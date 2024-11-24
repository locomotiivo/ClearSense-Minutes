//
//  HearingTestViewController.swift
//  clearsenseminutes
//
//  Created by HWANJUN YU on 10/28/24.
//

import UIKit

class HearingTestViewController: UIViewController {
    
    @IBOutlet weak var bgImage: UIImageView!
    @IBOutlet weak var contentView: UIStackView!
    
    var targetStep: AnyClass?
    let stepBadge = StepBadge(step: 1)

    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupLayout()
        
        if let targetStep = targetStep {
            changeStep(targetStep)
            self.targetStep = nil
        }
    }
    
    // MARK: - Init
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
        self.navigationItem.setLeftBarButton(navBackBtn, animated: false)
        self.navigationItem.title = "SIMPLE_HEARING_TEST".localized()
        self.navigationItem.setRightBarButton(UIBarButtonItem.init(customView: stepBadge), animated: false)
        
        // 스텝별 스크린 초기화
        setupStep1()
        setupStep2()
        setupStep3()
        setupStep4()
        changeStep(Step1FirstView.self)
    }
    
    // 스텝1 스크린 초기화
    private func setupStep1() {
        // Step1-1 : 맞춤 기능을 위해서 간이 청력 검사를 진행하겠습니다.
        let step1FistView = Step1FirstView() { [weak self] flag in
            if flag {
                self?.changeStep(Step1SecondView.self)
            } else {
                DispatchQueue.main.async { [weak self] in
                    self?.onClickBack(())
                }
            }
        }
        contentView.addArrangedSubview(step1FistView)
        step1FistView.isHidden = true
        
        // Step1-2 : 평소에 상대방의 목소리를 듣는데 어려움을 느끼나요?
        let step1SecondView = Step1SecondView() { [weak self] flag in
            if flag {
                self?.changeStep(Step2FirstView.self)
                self?.stepBadge.setStep(step: 2)
            } else {
                self?.changeStep(Step1ThirdView.self)
            }
        }
        contentView.addArrangedSubview(step1SecondView)
        step1SecondView.isHidden = true
        
        // Step1-3 : 개인화 소리조절을 하지 않고 넘어가시겠습니까?
        let step1ThirdView = Step1ThirdView() { [weak self] flag in
            if flag {
                DispatchQueue.main.async { [weak self] in
                    PresetManager.shared.creatBasicPreset()
                    self?.onClickBack(())
                }
            } else {
                self?.changeStep(Step2FirstView.self)
                self?.stepBadge.setStep(step: 2)
            }
        }
        contentView.addArrangedSubview(step1ThirdView)
        step1ThirdView.isHidden = true
    }
    
    // 스텝2 스크린 초기화
    private func setupStep2() {
        // Step2-1 : 전화 시 어떤 귀를 주로 사용하나요?
        let step2FirstView = Step2FirstView() { [weak self] isLeft in
            self?.changeStep(Step2SecondView.self)
        }
        contentView.addArrangedSubview(step2FirstView)
        step2FirstView.isHidden = true
        
        // Step2-2 : 선택한 귀에만 이어폰을 착용하고 들어주세요.
        let step2SecondView = Step2SecondView() { [weak self] in
            self?.changeStep(Step2ThirdView.self)
        }
        contentView.addArrangedSubview(step2SecondView)
        step2SecondView.isHidden = true
        
        // Step2-3 : 들을 수 있는 가장 작은 볼륨으로 설정해주세요
        let step2ThirdView = Step2ThirdView() { [weak self] in
            self?.changeStep(Step3FirstView.self)
            self?.stepBadge.setStep(step: 3)
        }
        contentView.addArrangedSubview(step2ThirdView)
        step2ThirdView.isHidden = true
    }
    
    // 스텝3 스크린 초기화
    private func setupStep3() {
        // Step3-1 : 소리가 몇 번 들리는지 기억해주세요
        let step3FirstView = Step3FirstView() { [weak self] in
            self?.changeStep(Step3SecondView.self)
        }
        contentView.addArrangedSubview(step3FirstView)
        step3FirstView.isHidden = true
        
        // Step3-2 : 소리가 몇 번 들리셨나요?
        let step3SecondView = Step3SecondView { [weak self] num in
            // -1은 "모르겠다" 클릭이벤트
            self?.changeStep(Step3ThirdView.self)
        } onClickRetry: { [weak self] in
            self?.changeStep(Step3FirstView.self)
        }
        contentView.addArrangedSubview(step3SecondView)
        step3SecondView.isHidden = true
        
        // Step3-3 : 세밀한 조절을 위해서 조금만 더 측정하겠습니다. 소리가 몇 번 들리는지 기억해주세요.
        let step3ThirdView = Step3ThirdView { [weak self] in
            self?.changeStep(Step3FourthView.self)
        }
        contentView.addArrangedSubview(step3ThirdView)
        step3ThirdView.isHidden = true
        
        // Step3-4 : 반대쪽 귀도 진행하시겠습니까?
        let step3FourthView = Step3FourthView { [weak self] flag in
            if flag {
                self?.changeStep(Step3FirstView.self)
            } else {
                self?.changeStep(Step4FirstView.self)
                self?.stepBadge.setStep(step: 4)
            }
        }
        contentView.addArrangedSubview(step3FourthView)
        step3FourthView.isHidden = true
    }
    
    // 스텝4 스크린 초기화
    private func setupStep4() {
        // Step4-1 : 검사가 완료되었습니다.
        let step4FirstView = Step4FirstView {
            // 완료
            DispatchQueue.main.async { [weak self] in
                self?.onClickBack(())
            }
        } overwrite: {
            // 덮어쓰기
            DispatchQueue.main.async { [weak self] in
                self?.onClickBack(())
            }
        }
        contentView.addArrangedSubview(step4FirstView)
        step4FirstView.isHidden = true
    }
    
    // MARK: - Function
    // 스텝 전환
    func changeStep(_ screen: AnyClass) {
        if screen == Step2ThirdView.self {
            bgImage.image = UIImage(named: "bg_equalizer")
        } else {
            bgImage.image = UIImage(named: "bg_hearing_test")
        }
        
        for subview in contentView.subviews {
            if type(of: subview) == screen {
                subview.isHidden = false
            } else {
                subview.isHidden = true
            }
        }
    }
}
