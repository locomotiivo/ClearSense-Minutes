//
//  Step2ThirdView.swift
//  clearsenseminutes
//
//  Created by HWANJUN YU on 10/29/24.
//

import UIKit
import AVFAudio
import MediaPlayer

class Step2ThirdView: UIView {
    @IBOutlet weak var muteBtn: UIButton!        // 음소거 버튼
    @IBOutlet weak var volumeSliderView: UIView! // 볼륨 슬라이더
    
    // 볼륨 슬라이더
    let volumeView = MPVolumeView(frame: .zero)
    let volumeSlider = CSVolumeSlider()
    
    var onClickHandler: (() -> Void)?
    var timer: Timer?
    
    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
        startTimer()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
        startTimer()
    }
    
    convenience init(onClick: @escaping () -> Void) {
        self.init(frame: .zero)
        onClickHandler = onClick
    }
    
    // 볼륨 변화 감지 타이머 시작
    private func startTimer() {
        timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(onChangeDeviceVolume), userInfo: nil, repeats: true)
    }
    
    deinit {
        timer?.invalidate()
    }
    
    // UI 초기화
    private func commonInit() {
        if let view = Bundle.main.loadNibNamed("Step2ThirdView", owner: self, options: nil)?.first as? UIView {
            view.frame = self.bounds
            addSubview(view)
        }
        
        // 볼륨 슬라이더
        volumeSlider.tintColor = UIColor(named: "btn_color")
        volumeSlider.translatesAutoresizingMaskIntoConstraints = false
        volumeSlider.value = AVAudioSession.sharedInstance().outputVolume
        volumeSlider.addTarget(self, action: #selector(onChangeSlideVolume(_:)), for: .valueChanged)
        volumeSliderView.addSubview(volumeSlider)
        NSLayoutConstraint.activate([
            volumeSlider.leadingAnchor.constraint(equalTo: volumeSliderView.leadingAnchor, constant: 0),
            volumeSlider.trailingAnchor.constraint(equalTo: volumeSliderView.trailingAnchor, constant: 0),
            volumeSlider.bottomAnchor.constraint(equalTo: volumeSliderView.bottomAnchor, constant: 0),
            volumeSlider.topAnchor.constraint(equalTo: volumeSliderView.topAnchor, constant: 0),
        ])
        changeMuteImage(volumeSlider.value)
    }
    
    // MARK: - Function
    // 다음 버튼 클릭
    @IBAction func onClickNext(_ sender: UIButton) {
        onClickHandler?()
    }
    
    // 디바이스 볼륨 변경에 따른 슬라이더 UI 조정
    @objc private func onChangeDeviceVolume() {
        let deviceVolume = AVAudioSession.sharedInstance().outputVolume
        
        if volumeSlider.value != deviceVolume {
            if !volumeSlider.isTracking {
                volumeSlider.value = deviceVolume
            }
            changeMuteImage(deviceVolume)
        }
    }
    
    // 슬라이드 조절에 따른 볼륨 조정
    @objc private func onChangeSlideVolume(_ slider: UISlider) {
        let sliderView = volumeView.subviews.first(where: {$0 is UISlider}) as? UISlider
        DispatchQueue.main.async() {
            sliderView?.value = slider.value
        }
        changeMuteImage(slider.value)
    }
    
    // 볼륨에 따른 음소거 버튼 이미지 반환
    private func changeMuteImage(_ volume: Float) {
        var image: UIImage?
        
        if volume > 0.6 {
            image = UIImage(systemName: "speaker.wave.3.fill")
        }else if volume > 0.3{
            image = UIImage(systemName: "speaker.wave.2.fill")
        }else if volume > 0.0 {
            image = UIImage(systemName: "speaker.wave.1.fill")
        } else {
            image = UIImage(systemName: "speaker.slash.fill")
        }
        
        muteBtn.setImage(image, for: .normal)
    }
}
