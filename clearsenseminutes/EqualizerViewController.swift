//
//  EqualizerViewController.swift
//  clearsenseminutes
//
//  Created by HWANJUN YU on 10/25/24.
//

import UIKit
import AVFoundation
import DropDown

class EqualizerViewController: UIViewController {
    
    @IBOutlet weak var presetNameLabel: UILabel!        // 프리셋 이름 라벨
    @IBOutlet weak var presetArrow: UIImageView!        // 프리셋 드롭다운 화살표
    @IBOutlet weak var presetRenameBtn: UIButton!       // 프리셋 이름변경 버튼
    @IBOutlet weak var presetRemoveBtn: UIButton!       // 프리셋 삭제 버튼
    
    @IBOutlet weak var contentView: UIView!             // 원래 내용이 표시될 뷰
    @IBOutlet weak var hearingTestView: Step1FirstView! // 간이청력검사 추천 뷰
    
    @IBOutlet weak var equalSwitch: CSSwitch!           // 양쪽 같게 스위치
    @IBOutlet weak var usingDeviceLabel: UILabel!       // 사용 기기 라벨
    
    @IBOutlet weak var dbStackView: UIStackView!        // dB 값들 스택뷰
    
    @IBOutlet weak var chartView: CSLineChart!          // 차트 뷰
    
    @IBOutlet weak var chartStackView: UIStackView!     // 양쪽 따로 차트 스택 뷰
    @IBOutlet weak var leftChartView: CSLineChart!      // 왼쪽 차트 뷰
    @IBOutlet weak var rightChartView: CSLineChart!     // 오른쪽 차트 뷰
    
    let presetManager = PresetManager.shared
    let dropdown = DropDown()
    
    var leftTestData: [LineChartData] = []
    var rightTestData: [LineChartData] = []
    
    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupLayout()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        presetManager.loadPresetList()
        updatePresetUI() // 프리셋 데이터로 UI 세팅
    }
    
    private func setupLayout() {
        
        // 네비게이션 바
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.shadowImage = UIImage()
        appearance.shadowColor = .clear // 하단 구분선 색상을 투명하게 설정
        appearance.backgroundColor = .clear
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        
        // 네비게이션 아이템
        let navGuideBtn = UIBarButtonItem(image: UIImage(named: "ic_info"), style: .plain, target: self, action: #selector(onClickGuide))
        self.navigationItem.setLeftBarButton(navBackBtn, animated: false)
        self.navigationItem.title = "EQ_PERSONER_PRESET".localized()
        self.navigationItem.setRightBarButton(navGuideBtn, animated: false)
        
        // 프리셋 드롭다운
        DropDown.appearance().textColor = .black
        DropDown.appearance().selectedTextColor = .separator
        DropDown.appearance().backgroundColor = .white
        DropDown.appearance().selectionBackgroundColor = .lightGray
        DropDown.appearance().setupCornerRadius(8)
        dropdown.dismissMode = .automatic
        dropdown.dataSource = presetManager.presetList.map({ $0.name })
        dropdown.anchorView = presetNameLabel
        dropdown.bottomOffset = CGPoint(x: 0, y: presetNameLabel.bounds.height)
        dropdown.selectionAction = { [weak self] (index, item) in
            guard let self = self else { return }
            // 프리셋 변경
            presetManager.selectedPreset = presetManager.presetList[index]
            updatePresetUI()
        }
        presetNameLabel.isUserInteractionEnabled = true
        presetNameLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onClickDropDown)))
        presetArrow.isUserInteractionEnabled = true
        presetArrow.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onClickDropDown)))
        
        // 사용 기기 라벨
        usingDeviceLabel.text = "\("USING_DEVICE".localized()) : \(AVAudioSession.sharedInstance().currentRoute.outputs.first?.portName ?? "Default Device")"
        
        equalSwitch.delegate = self // 양쪽 같게 스위치
        
        // 간이청력검사 추천 뷰 버튼 클릭 이벤트 세팅
        hearingTestView.setOnClickHandler { [weak self] flag in
            guard let self = self else { return }
            if flag {
                guard let vc = self.storyboard?.instantiateViewController(identifier: "HearingTestViewController") as? HearingTestViewController else { return }
                vc.targetStep = Step1SecondView.self
                navigationController?.pushViewController(vc, animated: true)
            } else {
                onClickBack(())
            }
        }
    }
    
    // 프리셋 변경 후 UI 반영
    private func updatePresetUI() {
        if !presetManager.presetList.isEmpty, presetManager.selectedPreset == nil {
            presetManager.selectedPreset = presetManager.presetList.first
        }
        
        // 프리셋
        dropdown.dataSource = presetManager.presetList.map({ $0.name })
        presetNameLabel.text = presetManager.selectedPreset?.name
        presetNameLabel.isUserInteractionEnabled = !presetManager.presetList.isEmpty
        presetArrow.isHidden = presetManager.presetList.isEmpty
        presetArrow.isUserInteractionEnabled = !presetManager.presetList.isEmpty
        presetRenameBtn.isEnabled = presetManager.selectedPreset != nil
        presetRemoveBtn.isEnabled = presetManager.selectedPreset != nil
        
        // 양쪽 같게 스위치
        equalSwitch.setOn(presetManager.selectedPreset?.leftRightEqual ?? true)
        
        // 청력검사 데이터 가져옴
        let data = presetManager.getChartData()
        leftTestData = data.left
        rightTestData = data.right
        updateDbLabel()
        
        // 차트 초기화
        chartView.setData(rightTestData) // 데이터 세팅
        leftChartView.setData(leftTestData)
        rightChartView.setData(rightTestData) // 데이터 세팅
        
        // 검사결과 존재 여부에 따라 보여질 화면 결정
        contentView.isHidden = presetManager.selectedPreset == nil
        hearingTestView.isHidden = presetManager.selectedPreset != nil
    }
    
    // MARK: - Function
    // db라벨 값들 변경
    private func updateDbLabel() {
        for (index, item) in rightTestData.enumerated() {
            if dbStackView.arrangedSubviews.count > index,
               let dbLabel = dbStackView.arrangedSubviews[index] as? UILabel {
                dbLabel.text = item.value.toEqVal
            }
        }
    }
    
    @objc func onClickDropDown(_ sender: Any) {
        dropdown.show()
    }
    
    // MARK: - onClick Event
    // 가이드 버튼 클릭
    @objc func onClickGuide(_ sender: Any) {
        // TODO: 알맞은 가이드로 교체
        let onboardingVC = OnboardingViewController(transitionStyle: .scroll, navigationOrientation: .horizontal)
        onboardingVC.modalPresentationStyle = .formSheet
        present(onboardingVC, animated: true, completion: nil)
    }
    
    // 프리셋 추가 버튼 클릭
    @IBAction func onClickPresetAdd(_ sender: UIButton) {
        if presetManager.presetList.count >= 3 {
            self.showToast("ERR_300".localized())
        } else {
            onClickHearingTest(UIButton())
        }
    }
    
    // 프리셋 이름 변경 버튼 클릭
    @IBAction func onClickPresetRename(_ sender: UIButton) {
        let alert = UIAlertController(title: "EDIT".localized(), message: nil, preferredStyle: .alert)
        alert.addTextField { [weak self] field in
            guard let self = self else { return }
            
            field.placeholder = presetManager.selectedPreset?.name
            
            let edit = UIAlertAction(title: "EDIT".localized(), style: .destructive) { [weak self] yes in
                guard let self = self else { return }
                
                let newName = field.text ?? "PRESET".localized()
                presetManager.changeName(newName)
                updatePresetUI()
            }
            let no = UIAlertAction(title: "CANCEL".localized(), style: .cancel, handler: nil)
            
            alert.addAction(no)
            alert.addAction(edit)
        }
        
        self.present(alert, animated: true, completion: nil)
    }
    
    // 프리셋 삭제 버튼 클릭
    @IBAction func onClickPresetRemove(_ sender: UIButton) {
        Alert("WANT_REMOVE_PRESET".localized(), "") { [weak self] in
            self?.presetManager.removePreset()
            self?.updatePresetUI()
        } _: { }
    }
    
    // 전체 재검사 버튼 클릭
    @IBAction func onClickHearingTest(_ sender: UIButton) {
        guard let vc = self.storyboard?.instantiateViewController(identifier: "HearingTestViewController") as? HearingTestViewController else { return }
        navigationController?.pushViewController(vc, animated: true)
    }
    
    // 상세 튜닝 버튼 클릭
    @IBAction func onClickDetailTuning(_ sender: UIButton) {
        guard let vc = self.storyboard?.instantiateViewController(identifier: "DetailTuningViewController") as? DetailTuningViewController else { return }
        navigationController?.pushViewController(vc, animated: true)
    }
}

// MARK: - CSSwitchDelegate
extension EqualizerViewController: CSSwitchDelegate {
    // 양쪽 같게 스위치 변경
    func onChange(isOn: Bool) {
        presetManager.saveIsEqualToLocal(isEqual: isOn) // 양쪽 같게 값 로컬 저장
        
        // 차트 1개 보여줄지 2개 보여줄지 처리
        chartView.isHidden = !equalSwitch.isOn
        chartStackView.isHidden = equalSwitch.isOn
    }
}
