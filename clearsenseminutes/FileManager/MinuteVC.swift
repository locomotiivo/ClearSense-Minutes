//
//  MinuteVC.swift
//  clearsenseminutes
//
//  Created by KooBH on 2/19/24.
//

import Foundation
import UIKit
import OSLog

class MinuteVC: UIViewController {
    
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
    
    let emptyView = EmptyMinuteView(imageName: "nosign", message: "NOMINUTE".localized())
        
    var list = [Minute]() // 파일 목록
    var selected = Set<Minute>() // 편집모드에서 선택된 파일
    
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
        navigationItem.title = "MINUTE_MANAGER".localized()
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
        Task {
            let data = try? await DBconn.DBRequest("GET", ["URL":"/meetings/get-all-records/"])
            print(data?.rawString() ?? "NO DATA")
        }
        
        checkNoEntry()
    }
    
    // MARK: - 네비게이션 아이템 클릭 이벤트
    // 꾹 눌렀다 떼면 편집모드로
    @objc func onLongPress(_ press: UILongPressGestureRecognizer) {
        if press.state == .ended, !isEditMode {
            let loc = press.location(in: tableView)
            let idxPath = tableView.indexPathForRow(at: loc) ?? nil
            
            isEditMode = true
            selected.insert(list[idxPath?.row ?? 0])
            checkSelectItems()
            
            tableView.reloadData()
        }
    }
    
    // 전체 체크 / 해제
    @objc func checkAll() {
        if selected.count == list.count {
            selected.removeAll()
        } else {
            for item in list {
                selected.insert(item)
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
    fileprivate func checkNoEntry() {
        if list.isEmpty {
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
                allBtn.isSelected = selected.count == list.count
            }
            self.navigationItem.setLeftBarButton(navCheckAllBtn, animated: true)
            self.navigationItem.title = "\(selected.count)" + "SELECTED".localized()
        }
    }
    
    // 편집모드 On/Off
    private func changeEditMode() {
        if isEditMode {
            checkSelectItems()
            self.navigationItem.setRightBarButton(navCloseBtn, animated: true)
        } else {
            selected.removeAll()
            self.navigationItem.setLeftBarButton(navBackBtn, animated: true)
            self.navigationItem.title = "MINUTE_MANAGER".localized()
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
        guard let cell = tableView.cellForRow(at: IndexPath(row: sender.tag, section: 0)) as? MinuteRow,
              let vc = self.storyboard?.instantiateViewController(identifier: "MinuteDetailsVC") as? MinuteDetailsVC,
              let id = cell.label_id.text
        else {
            return
        };
        vc.id = id
        vc.modalPresentationStyle = .overCurrentContext
        vc.modalTransitionStyle = .crossDissolve
        vc.view.backgroundColor = .black.withAlphaComponent(0.6)
        vc.view.layer.cornerRadius = 8
        navigationController?.present(vc, animated: true, completion: nil)
    }
    
    // 삭제 버튼 클릭
    @IBAction func onClickDelete(_ sender: UIButton) {
        if selected.isEmpty {
            Alert("", "ATLEAST_FAILURE".localized(), nil)
        } else {
            Alert("DELETE_CONFIRM".localized(), "", { [weak self] in
                self?.deleteMinute()
            }, nil)
        }
    }
    
    // 파일 삭제
    private func deleteMinute() {
        for item in selected {
            Task {
                let data = try? await DBconn.DBRequest("POST", ["URL":"/meetings/delete-record/\(item.id)"])
                
                print("DELETE RESPONSE : \(data ?? "nil")")
                
            }
            list.removeAll{ $0.id == item.id}
            selected.remove(item) // Delete On View
        }
        showToast("SUCCESS".localized())
        
        tableView.reloadData()
        checkNoEntry()
        self.navigationItem.title =  "\(Array(selected).count)" + "SELECTED".localized()
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension MinuteVC: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return list.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MinuteData", for: indexPath) as! MinuteRow
        
        cell.data = list[indexPath.row]
        
        if isEditMode {
            if selected.contains(list[indexPath.row]) {
                cell.btn_minute.setImage(UIImage(named: "ic_check_select"), for: .normal)
            } else {
                cell.btn_minute.setImage(UIImage(named: "ic_check_none"), for: .normal)
            }
        } else {
            cell.btn_minute.setImage(UIImage(systemName: "doc.text" ), for: .normal)
        }
        cell.btn_minute.tag = indexPath.row
        cell.label_id.text = list[indexPath.row].id
        cell.label_title.text = list[indexPath.row].title
        cell.label_company.text = list[indexPath.row].company
        cell.label_text.text = list[indexPath.row].text
        
        let df = DateFormatter()
        df.dateFormat = "yyyy/MM/dd"
        cell.label_date.text = df.string(from: list[indexPath.row].date)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 66
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard isEditMode, list.count > indexPath.row else { return }
        let targetData = list[indexPath.row]
        
        if selected.contains(targetData) {
            selected.remove(targetData)
        } else {
            selected.insert(targetData)
        }
        
        checkSelectItems()
        tableView.reloadData()
    }
}