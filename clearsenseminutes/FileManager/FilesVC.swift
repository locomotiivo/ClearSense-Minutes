//
//  FilesVC.swift
//  clearsenseminutes
//
//  Created by KooBH on 2/19/24.
//

import Foundation
import UIKit
import MediaPlayer
import OSLog

class FilesVC: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var controlBtnView: UIView!
    @IBOutlet weak var controlBtnViewHeight: NSLayoutConstraint!
    
    // 네비게이션 아이템
    var navCloseBtn: UIBarButtonItem {
        let backButton = UIButton(frame: CGRect(origin: .zero, size: CGSize(width: 25.5, height: 18.5)))
        backButton.setImage(UIImage(named: "ic_close"), for: .normal)
        backButton.contentHorizontalAlignment = .left
        backButton.addTarget(self, action: #selector(endEdit), for: .touchUpInside)
        return UIBarButtonItem(customView: backButton)
    }
    var navCheckAllBtn: UIBarButtonItem?
    
    let emptyView = EmptyFileView(imageName: "nosign", message: "NOFILE".localized())
        
    var fileList = [File]() // 파일 목록
    var playingFile: File?  // 재생중인 파일
    var selectedFile = Set<File>() // 편집모드에서 선택된 파일
    
    // 편집 모드 여부
    private var isEditMode: Bool = false {
        didSet { changeEditMode() }
    }
    
    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 네비게이션 바
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.shadowImage = UIImage()
        appearance.shadowColor = .clear // 하단 구분선 색상을 투명하게 설정
        appearance.backgroundColor = .clear
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationItem.title = "FILE_MANAGER".localized()
        navigationItem.setLeftBarButton(navBackBtn, animated: false)
        
        // 네비게이션 아이템
        let checkAllBtn = UIButton(type: .custom)
        var configuration = UIButton.Configuration.plain()
        configuration.attributedTitle = AttributedString("ALL".localized(), attributes: AttributeContainer([
            .font: UIFont(name: "PretendardGOVVariable-Medium", size: 12) ?? UIFont.systemFont(ofSize: 12)
        ]))
        configuration.baseForegroundColor = .white
        configuration.baseBackgroundColor = .clear
        configuration.image = UIImage(named: "ic_check_none")
        configuration.imagePadding = 8
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 13, bottom: 0, trailing: -13)
        checkAllBtn.configuration = configuration
        checkAllBtn.addTarget(self, action: #selector(checkAll), for: .touchUpInside)
        checkAllBtn.configurationUpdateHandler = { button in
            var selectedConfiguration = button.configuration
            selectedConfiguration?.image = UIImage(named: button.isSelected ? "ic_check_select" : "ic_check_none")
            button.configuration = selectedConfiguration
        }
        navCheckAllBtn = UIBarButtonItem(customView: checkAllBtn)
        
        // EMPTY VIEW
        view.addSubview(emptyView)
        emptyView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            emptyView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            emptyView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            emptyView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            emptyView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
        emptyView.isHidden = true
        
        // TABLE VIEW
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(onLongPress)))
        tableView.allowsSelection = false
        tableView.allowsMultipleSelection = false
        tableView.delegate = self
        tableView.dataSource = self
        
        // 편집 버튼들
        controlBtnView.isHidden = true
        controlBtnViewHeight.isActive = true
        
        // 파일 데이터
        fileList = FilesArray.loadData()
        checkFileIsEmpty()
    }
    
    // MARK: - 네비게이션 아이템 클릭 이벤트
    // 꾹 눌렀다 떼면 편집모드로
    @objc func onLongPress(_ press: UILongPressGestureRecognizer) {
        if press.state == .ended, !isEditMode {
            let loc = press.location(in: tableView)
            let idxPath = tableView.indexPathForRow(at: loc) ?? nil
            
            isEditMode = true
            selectedFile.insert(fileList[idxPath?.row ?? 0])
            checkSelectItems()
            
            tableView.reloadData()
        }
    }
    
    // 전체 체크 / 해제
    @objc func checkAll() {
        if selectedFile.count == fileList.count {
            selectedFile.removeAll()
        } else {
            for item in fileList {
                selectedFile.insert(item)
            }
        }
        checkSelectItems()
        tableView.reloadData()
    }
    
    // 편집모드 종료
    @objc func endEdit() {
        isEditMode = false
    }
    
    // MARK: - Function
    // 파일 목록 확인 후 EmptyView 노출
    fileprivate func checkFileIsEmpty() {
        if fileList.isEmpty {
            tableView.isHidden = true
            emptyView.isHidden = false
        } else {
            tableView.isHidden = false
            emptyView.isHidden = true
        }
    }
    
    // 선택된 아이템 판단하여 필요한 UI 변경
    private func checkSelectItems() {
        if isEditMode {
            if let allBtn = navCheckAllBtn?.customView as? UIButton {
                allBtn.isSelected = selectedFile.count == fileList.count
            }
            self.navigationItem.setLeftBarButton(navCheckAllBtn, animated: true)
            self.navigationItem.title = "\(selectedFile.count)" + "SELECTED".localized()
        }
    }
    
    // 편집모드 On/Off
    private func changeEditMode() {
        if isEditMode {
            checkSelectItems()
            self.navigationItem.setRightBarButton(navCloseBtn, animated: true)
        } else {
            selectedFile.removeAll()
            self.navigationItem.setLeftBarButton(navBackBtn, animated: true)
            self.navigationItem.title = "FILE_MANAGER".localized()
            self.navigationItem.setRightBarButton(nil, animated: true)
        }
        
        tableView.allowsSelection = isEditMode
        tableView.allowsMultipleSelection = isEditMode
        tableView.reloadData()
        
        controlBtnView.isHidden = !isEditMode
        controlBtnViewHeight.isActive = !isEditMode
    }
    
    // MARK: - View Minute
    @IBAction func onClickMinute(_ sender: UIButton) {
        guard let vc = self.storyboard?.instantiateViewController(identifier: "MinuteVC") as? MinuteVC else { return }
        vc.modalPresentationStyle = .overCurrentContext
        vc.modalTransitionStyle = .crossDissolve
        vc.view.backgroundColor = .black.withAlphaComponent(0.6)
        vc.view.layer.cornerRadius = 8
        navigationController?.present(vc, animated: true, completion: nil)
    }
    
    // MARK: - 편집 버튼들
    // 이름변경 버튼 클릭
    @IBAction func onClickEdit(_ sender: UIButton) {
        guard let targetFile = selectedFile.first else {
            Alert("", "\(selectedFile.count): \("ATLEAST_FAILURE".localized())", nil)
            return
        }
        guard selectedFile.count == 1 else {
            Alert("", "\(selectedFile.count): \("EDITABLE_ONLY_ONE".localized())", nil)
            return
        }
        
        let filePath = mpWAVURL.appendingPathComponent(targetFile.fileTitle)
        let fileTitle = mpWAVURL.appendingPathComponent(targetFile.fileTitle).lastPathComponent
        let selectedIdx = targetFile.idx
        
        guard let cell = tableView.cellForRow(at: IndexPath(row: selectedIdx, section: 0)) as? FileRow else { return }
        
        let alert = UIAlertController(title: "Edit", message: nil, preferredStyle: .alert)
        alert.addTextField { field in
            field.placeholder = fileTitle
            
            // edit
            let edit = UIAlertAction(title: "Edit", style: .destructive) { [weak self] yes in
                guard let self = self else { return }
                
                var newFieldName = (field.text ?? "noName") + ".m4a"
                
                // Check the duplicate
                for item in fileList {
                    if item.fileTitle == newFieldName {
                        let random = String(Int.random(in: 1...10000))
                        newFieldName = random + "_" + newFieldName
                        break
                    }
                }
                
                cell.label_name.text = newFieldName
                
                selectedFile.first?.fileTitle = newFieldName
            }
            
            let no = UIAlertAction(title: "No", style: .cancel, handler: nil)
            
            alert.addAction(no)
            alert.addAction(edit)
        }
        
        self.present(alert, animated: true, completion: nil)
    }
    
    // 공유 버튼 클릭
    @IBAction func onClickShare(_ sender: UIButton) {
        if selectedFile.isEmpty {
            Alert("", "ATLEAST_FAILURE".localized(), nil)
        } else {
            var URLArray: [NSURL] = []
            for item in selectedFile {
                let fileURL = NSURL(fileURLWithPath: Utils.getFilePath(item.fileTitle))
                URLArray.append(fileURL)
            }
            
            let activityVC = UIActivityViewController(activityItems: URLArray, applicationActivities: nil)
            activityVC.popoverPresentationController?.sourceView = view
            activityVC.popoverPresentationController?.sourceRect = CGRect(x: self.view.bounds.midX, y:self.view.bounds.midY, width:0, height:0)
            activityVC.present(over: self)
            
            Alert("", "SHARE_SUCCESS".localized(), nil)
        }
    }
    
    // 삭제 버튼 클릭
    @IBAction func onClickDelete(_ sender: UIButton) {
        if selectedFile.isEmpty {
            Alert("", "ATLEAST_FAILURE".localized(), nil)
        } else {
            Alert("DELETE_CONFIRM".localized(), "", { [weak self] in
                self?.deleteFile()
            }, nil)
        }
    }
    
    // 파일 삭제
    private func deleteFile() {
        var currentName = ""
        
        do {
            for item in selectedFile {
                currentName = item.fileTitle
                fileList.removeAll{ $0.fileTitle == currentName} // Delete Data on Tableview Content
                try FileManager.default.removeItem(atPath: mpWAVURL.appendingPathComponent(currentName).path) // Delete Local
                selectedFile.remove(item) // Delete On View
            }
            showToast("SUCCESS".localized())
        } catch {
            Alert("ERR_102_%@".localized(with: [currentName]), "\(error.localizedDescription)", nil)
        }
        
        tableView.reloadData()
        checkFileIsEmpty()
        self.navigationItem.title =  "\(Array(selectedFile).count)" + "SELECTED".localized()
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension FilesVC: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fileList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FileData", for: indexPath) as! FileRow
        
        cell.data = fileList[indexPath.row]
        
        if isEditMode {
            if selectedFile.contains(fileList[indexPath.row]) {
                //cell.contentView.backgroundColor = UIColor(named: "row_color_select")
                cell.btn_play.setImage(UIImage(named: "ic_check_select"), for: .normal)
            } else {
                //cell.contentView.backgroundColor = .clear
                cell.btn_play.setImage(UIImage(named: "ic_check_none"), for: .normal)
            }
        } else {
            cell.btn_play.setImage(playingFile == fileList[indexPath.row] ? UIImage(systemName: "pause") : UIImage(systemName: "doc.text" ), for: .normal)
        }
        cell.btn_play.tag = indexPath.row
        cell.label_name.text = fileList[indexPath.row].fileTitle
        cell.label_length.text = fileList[indexPath.row].fileDuration
        
        let df = DateFormatter()
        df.dateFormat = "yyyy년 MM월 dd일"
        cell.label_date.text = df.string(from: fileList[indexPath.row].fileDate)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 66
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard isEditMode, fileList.count > indexPath.row else { return }
        let targetData = fileList[indexPath.row]
        
        if selectedFile.contains(targetData) {
            selectedFile.remove(targetData)
        } else {
            selectedFile.insert(targetData)
        }
        
        checkSelectItems()
        tableView.reloadData()
    }
}
