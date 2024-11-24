//
//  DetailTuningViewController.swift
//  clearsenseminutes
//
//  Created by HWANJUN YU on 10/31/24.
//

import UIKit
import OSLog

class DetailTuningViewController: UIViewController {
    
    @IBOutlet weak var presetNameLabel: UILabel!    // 프리셋 이름 라벨
    @IBOutlet weak var earSwitch: CSSwitch!         // 어느쪽 귀인지 스위치
    @IBOutlet weak var curFrequencyLabel: UILabel!  // 현재 설정 주파수 라벨
    
    @IBOutlet weak var dbStackView: UIStackView!    // dB 값들 스택뷰
    @IBOutlet weak var chartView: CSLineChart!      // 차트 뷰
    
    @IBOutlet weak var listenBtn: LanguageButton!   // 들어보기 버튼
    
    let presetManager = PresetManager.shared
    var leftTestData: [LineChartData] = []
    var rightTestData: [LineChartData] = []
    var selectIndex: Int = -1 {
        didSet {
            if getUsingData().count > selectIndex {
                let freq = Double(getUsingData()[selectIndex].label)
                testManager.setFreq(freq)
            }
        }
    }
    
    let testManager = DetailTuningManager.shared
    
    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupLayout()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        testManager.stop()
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
        self.navigationItem.title = "DETAIL_TUNING".localized()
        self.navigationItem.setRightBarButton(navGuideBtn, animated: false)
        
        // 프리셋
        presetNameLabel.text = presetManager.selectedPreset?.name
        
        // 귀 선택 스위치
        earSwitch.delegate = self
        earSwitch.setOn(true)
        
        // 청력검사 데이터 가져옴
        let data = presetManager.getChartData()
        leftTestData = data.left
        rightTestData = data.right
        selectIndex = Int(floor(Double(getUsingData().count) / 2.0))
        updateDbLabel()
        
        // 현재 설정 주파수
        curFrequencyLabel.text = "\("CURRENT_FREQUENCY".localized()) : \(Utils.convertHz(getUsingData()[selectIndex].label))Hz"
        
        // 차트 초기화
        chartView.delegate = self
        chartView.setData(getUsingData()) // 데이터 세팅
    }
    
    // MARK: - Function
    // 차트에서 데이터 조절시 주파수 라벨들 바꿈
    private func updateDbLabel() {
        for (index, item) in getUsingData().enumerated() {
            if dbStackView.arrangedSubviews.count > index,
               let dbLabel = dbStackView.arrangedSubviews[index] as? UILabel {
                dbLabel.text = item.value.toEqVal
            }
        }
    }
    
    // 좌/우 귀 중 현재 표시중인 데이터
    private func getUsingData() -> [LineChartData] {
        return earSwitch.isOn ? rightTestData : leftTestData
    }
    
    // 현재 선택 주파수 볼륨값 적용
    private func setVolumeGain() {
        if getUsingData().count > selectIndex {
            let value = Float(getUsingData()[selectIndex].value)
            testManager.setGain(value)
        }
    }
    
    // MARK: - Click Event
    // 가이드 버튼 클릭
    @objc func onClickGuide(_ sender: Any) {
        // TODO: 알맞은 가이드로 교체
        let onboardingVC = OnboardingViewController(transitionStyle: .scroll, navigationOrientation: .horizontal)
        onboardingVC.modalPresentationStyle = .formSheet
        present(onboardingVC, animated: true, completion: nil)
    }
    
    // 들어보기 버튼 클릭
    @IBAction func onClickListen(_ sender: UIButton) {
        if testManager.isPlay {
            listenBtn.localized = "HEAR_ON"
            testManager.stop()
            os_log(.debug, log: .audio, "DetailTuningViewController::off")
        } else {
            listenBtn.localized = "HEAR_OFF"
            testManager.start()
            os_log(.debug, log: .audio, "DetailTuningViewController::on")
        }
    }
    
    // 되돌리기 버튼 클릭
    @IBAction func onClickReset(_ sender: UIButton) {
        let data = presetManager.getChartData()
        leftTestData = data.left
        rightTestData = data.right
        updateDbLabel()
        chartView.setData(getUsingData()) // 데이터 세팅
        curFrequencyLabel.text = "\("CURRENT_FREQUENCY".localized()) : \(Utils.convertHz(getUsingData()[selectIndex].label))Hz"
    }
    
    // 재검사 버튼 클릭
    @IBAction func onClickRetest(_ sender: UIButton) {
        guard let vc = self.storyboard?.instantiateViewController(identifier: "HearingTestViewController") as? HearingTestViewController else { return }
        // TODO: vc.targetStep 사용하여 원하는 부분으로 점프
        navigationController?.pushViewController(vc, animated: true)
    }
    
    // 반대쪽 귀와 같게 버튼 클릭
    @IBAction func onClickSameOtherEar(_ sender: UIButton) {
        if earSwitch.isOn {
            leftTestData = rightTestData
        } else {
            rightTestData = leftTestData
        }
    }
    
    // 확인 버튼 클릭
    @IBAction func onClickOk(_ sender: Any) {
        presetManager.savePresetToLocal(left: leftTestData, right: rightTestData) // 로컬에 데이터 저장
        self.onClickBack(sender)
    }
}

// MARK: - CSSwitchDelegate
extension DetailTuningViewController: CSSwitchDelegate {
    // 좌/우 귀 변경
    func onChange(isOn: Bool) {
        testManager.setEar(isOn ? .right : .left)
        updateDbLabel()
        chartView.setData(getUsingData(), selectIdx: selectIndex) // 데이터 세팅
        setVolumeGain()
    }
}

// MARK: - CSLineChartDelegate
extension DetailTuningViewController: CSLineChartDelegate {
    // 차트 슬라이더 조절 시작시
    func didBeginAdjusting(_ value: LineChartData) {
        selectIndex = getUsingData().firstIndex(where: { $0.label == value.label }) ?? 0
        curFrequencyLabel.text = "\("CURRENT_FREQUENCY".localized()) : \(Utils.convertHz(value.label))Hz"
    }
    
    // 차트 슬라이더 조절 중간
    func onChangeValue(_ values: [LineChartData]) {
        // 새 데이터 세팅
        if earSwitch.isOn {
            rightTestData = values
        } else {
            leftTestData = values
        }
        
        setVolumeGain()
        updateDbLabel()
    }
}
