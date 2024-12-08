//
//  MainViewController.swift
//  MuitiChannelMic
//
//  Created by 이동건 on 2023/07/19.
//  Edited by 문하진 on 2023/01/01
//

import UIKit
import AVFoundation
import Foundation
import SwiftyJSON
import MediaPlayer
import Dispatch
import AVKit
import OSLog
import CoreData

class MainViewController: UIViewController {
    
    @IBOutlet weak var bgView: UIView!
    
    @IBOutlet weak var minuteBtn: UIButton!           // 파일 버튼
    @IBOutlet weak var logoImg: UIImageView!        // 앱 로고
    
    @IBOutlet weak var micBtn: UIButton!            // 재생 버튼ß
    
    @IBOutlet weak var companyLabel : UILabel!      // 회사 이름
    @IBOutlet weak var settingBtn: UIButton!        // 설정 버튼
    
    // 영상 재생 관련 변수
    var avPlayer: AVPlayer!
    var avPlayerLayer: AVPlayerLayer!
    
    var container: NSPersistentContainer!
//    var didShowNotice: Bool = false         // 공지사항은 앱 킬때, 한번만
    var isHeadphoneConnected: Bool = false  // 헤드폰 연결 여부
    var isBackground: Bool = false          // 백그라운드 상태인지 여부
    
    @IBOutlet weak var emptyTextView: MPTextView!
    @IBOutlet weak var minuteView: MPTextView!
    
    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        STTconn.setDelegate(self)
        
        // 저장해뒀던 데이터 불러와 세팅
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        container = appDelegate.persistentContainer
        do {
            let flags = try container.viewContext.fetch(Flag.fetchRequest())
            os_log(.debug, "Flags: \(flags.count)")
            
            if flags.count > 0 {
                let flag = flags[0]
                lan = flag.lan ?? lan
            }
        } catch {
            os_log(.error, log: .system, "%@", "Error loading Core Data: \(error.localizedDescription)")
        }
        
        setupLayout()       // 홈 화면 UI 세팅
        let dirExists = (try? mpWAVURL.checkResourceIsReachable()) ?? false
        do {
            if !dirExists {
                try FileManager.default.createDirectory(atPath: mpWAVURL.path, withIntermediateDirectories: true)
            }
        } catch {
            let message = "Error creating Directory: \(error.localizedDescription)"
            os_log(.error, log: .audio, "%@", message)
            
            mpWAVURL = URL.documentsDirectory
        }
        checkHeadphoneConnected()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: true)
        
        NotificationCenter.default.addObserver(self, selector: #selector(toggleForeBack), name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(toggleForeBack), name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleAudioInterruption), name: AVAudioSession.interruptionNotification, object: AVAudioSession.sharedInstance())
        NotificationCenter.default.addObserver(self, selector: #selector(handleAudioRouteChange), name: AVAudioSession.routeChangeNotification, object: nil)
        
        // 볼륨 변화 감지
        if micBtn.isSelected {
            avPlayer.play() // 영상 재생
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        
        NotificationCenter.default.removeObserver(self, name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: AVAudioSession.interruptionNotification, object: AVAudioSession.sharedInstance())
        NotificationCenter.default.removeObserver(self, name: AVAudioSession.routeChangeNotification, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Init
    // UI 세팅
    private func setupLayout() {
        // 배경 영상
        if let theURL = Bundle.main.url(forResource:"bg_wav", withExtension: "mp4") {
            avPlayer = AVPlayer(url: theURL)
            avPlayerLayer = AVPlayerLayer(player: avPlayer)
            avPlayerLayer.videoGravity = .resizeAspectFill
            avPlayer.volume = 0
            avPlayer.actionAtItemEnd = .none
            avPlayerLayer.frame = view.layer.bounds
            bgView.layer.insertSublayer(avPlayerLayer, at: 0)
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(playerItemDidReachEnd(notification:)),
                                                   name: .AVPlayerItemDidPlayToEndTime,
                                                   object: avPlayer.currentItem)
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(handleAppDidBecomeActive),
                                                   name: UIApplication.didBecomeActiveNotification,
                                                   object: nil
            )
        }
        
        logoImg.image = UIImage(named: lan == "ko" ? "logo_kr" : "logo_en" ) // 언어
        
        // 회사 이름 라벨
        companyLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(openLicenseVC)))
        companyLabel.isUserInteractionEnabled = true
        
        // Initial Text View
        minuteView.isHidden = true
        emptyTextView.isHidden = false
        emptyTextView.centerVerticalText()
    }
    
    // MARK: - IBAction
    // 파일 버튼 클릭 이벤트
    @IBAction func onClickMinute(_ sender: UIButton) {
        guard let vc = self.storyboard?.instantiateViewController(identifier: "MinuteVC") as? MinuteVC else { return }
        navigationController?.pushViewController(vc, animated: true)
    }
    
    // 마이크 버튼 클릭 이벤트
    @IBAction func onClickMic(_ sender: UIButton) {
        if audioEngine.isRunning {
            toggleAudio(false)
        } else {
            toggleAudio(true)
        }
    }
    
    // 설정 버튼 클릭
    @IBAction func onClickSetting(_ sender: UIButton) {
        guard let vc = self.storyboard?.instantiateViewController(identifier: "SettingVC") as? SettingVC else { return }
        navigationController?.pushViewController(vc, animated: true)
    }
    
    // MARK: - Function
    // 재생 / 정지
    private func toggleAudio(_ flag: Bool) {
        if flag {
            // Connect to STT Server
            do {
                LoadingIndicator.showLoading()
                try STTconn.connect()
            } catch let err {
                LoadingIndicator.hideLoading()
                let messages = "Error connecting to STT Server: \(err.localizedDescription)"
                os_log(.error, log: .audio, "%@", messages)
                showToast(messages)
            }
        } else {
            // Disconnect from STT Server
            STTconn.disconnect()
            
            micBtn.isSelected = false
            avPlayer.pause()
            
            DispatchQueue.main.asyncAfter(deadline: .now()) {
                audioEngine.stop_audio_unit()
            }
        }
    }
    
    // 다른 오디오 인터럽트가 걸렸을 때 재생/정지 처리
    @objc func handleAudioInterruption(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }
        
        switch type {
        case .began:
            // 인터럽트가 걸렸을 때 잠시 정지
            os_log(.info, log: .audio, "audio interruption started")
            if audioEngine.isRunning {
                toggleAudio(false)
            }
        case .ended:
            // 인터럽트가 종료됐으면 다시 재생
            guard let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt else { return }
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
            if options.contains(.shouldResume) {
                os_log(.info, log: .audio, "audio interruption ended. Continuing playback")
                toggleAudio(true)
            } else {
                os_log(.info, log: .audio, "audio interruption ended")
            }
        default: break
        }
    }
    
    // 헤드폰 연결시 처리
    @objc func handleAudioRouteChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let type = AVAudioSession.RouteChangeReason(rawValue: typeValue) else {
            return
        }
        
        switch type {
        case .newDeviceAvailable:
            os_log(.info, log: .audio, "new device plugged in")
            if audioEngine.isRunning {
                toggleAudio(false)
            }
            checkHeadphoneConnected()
        case .oldDeviceUnavailable:
            os_log(.info, log: .audio, "device pulled out")
            if audioEngine.isRunning {
                toggleAudio(false)
            }
            checkHeadphoneConnected()
        default: break
        }
    }
    
    // 로컬에 변경값 저장
    private func saveLocalData() {
        do {
            let flags = try container.viewContext.fetch(Flag.fetchRequest())
            if flags.count > 0 {
                let flag = flags[0]
//                flag.record = audioEngine.isRecording
            } else if let entity = NSEntityDescription.entity(forEntityName: "Flag", in: container.viewContext) {
                let flag = NSManagedObject(entity: entity, insertInto: container.viewContext)
//                flag.setValue(audioEngine.isRecording, forKey: "record")
            }
            try container.viewContext.save()
//            os_log(.info, log: .audio, "%@", "record flag set to \(audioEngine.isRecording)")
        } catch {
            os_log(.error, log: .system, "%@", "Error saving Core Data : \(error.localizedDescription)")
        }
    }
    
    // 헤드폰 연결 확인
    private func checkHeadphoneConnected() {
        let connectedHeadphones = audioEngine.session.currentRoute.outputs.compactMap {
            ($0.portType == .headphones ||
             $0.portType == .bluetoothA2DP ||
             $0.portType == .bluetoothHFP ||
             $0.portType == .bluetoothLE) ? $0.portName : nil
        }
        isHeadphoneConnected = !connectedHeadphones.isEmpty
        
        if isHeadphoneConnected {
            let msg = "ROUTE_CHANGE_MSG".localized() + connectedHeadphones.joined(separator: ", ")
            os_log(.info, log: .audio, "%@", msg)
            os_log(.info, log: .audio, "%@", "sample Rate of device: \(audioEngine.session.sampleRate)")
            topMostViewController().showToast(msg)
            
            audioEngine.changeSampleRate(audioEngine.session.sampleRate)
        } else {
            let msg = "ROUTE_CHANGE_ERR".localized()
            os_log(.info, log: .audio, "%@", msg)
            topMostViewController().showToast(msg)
        }
    }
    
    // 백/포그라운드 전환 여부
    @objc func toggleForeBack(_ notification : Notification) {
        let name = notification.name
        if name == Notification.Name("UIApplicationWillResignActiveNotification") {
            isBackground = true
        } else if name == Notification.Name("UIApplicationWillEnterForegroundNotification") {
            isBackground = false
        }
    }
    
    // 배경 영상이 끝까지 재생되면 루프
    @objc func playerItemDidReachEnd(notification: Notification) {
        if let player = notification.object as? AVPlayerItem {
            player.seek(to: .zero) {_ in }
        }
    }
    
    // 포그라운드 전환시 처리
    @objc func handleAppDidBecomeActive() {
        if micBtn.isSelected {
            avPlayer.play()
        }
    }
    
    // MARK: - ViewController 노출 or 이동
    // LicenseVC 노출
    @objc func openLicenseVC(_ sender: UIButton) {
        guard let vc = self.storyboard?.instantiateViewController(identifier: "LicenseVC") as? LicenseVC else { return }
        vc.modalPresentationStyle = .overCurrentContext
        vc.modalTransitionStyle = .crossDissolve
        vc.view.backgroundColor = .black.withAlphaComponent(0.6)
        vc.view.layer.cornerRadius = 8
        navigationController?.present(vc, animated: true, completion: nil)
    }
}

extension MainViewController : STTDelegate {
    func STTConnect() {
        let message = "Connected to STT Server!"
        os_log(.info, log: .system, "%@", message)
        DispatchQueue.main.sync {
            minuteView.isHidden = false
            emptyTextView.isHidden = true
            minuteView.text = ""
            
            micBtn.isSelected = true
            avPlayer.play()
            DispatchQueue.main.asyncAfter(deadline: .now()) {
                LoadingIndicator.hideLoading()
                audioEngine.start_audio_unit()
            }
        }
    }
    
    func STTCallback(text: String) {
        DispatchQueue.main.async {
            guard let data = text.data(using: .utf8) else {
                return
            }
            let json = JSON(data)
            guard let text = json["text"].string
            else {
                let message = "WebSocket: Error parsing STT data"
                os_log(.error, log: .system, "%@", message)
                self.showToast(message)
                return
            }
            self.minuteView.text = text
            let range = NSMakeRange(self.minuteView.text.count - 1, 0)
            self.minuteView.scrollRangeToVisible(range)
        }
    }
    
    func STTCallback(data: Data) {
        DispatchQueue.main.async {
            let json = JSON(data)
            guard let text = json["text"].string
            else {
                let message = "WebSocket: Error parsing STT data"
                os_log(.error, log: .system, "%@", message)
                self.showToast(message)
                return
            }
            self.minuteView.text = text
            let range = NSMakeRange(self.minuteView.text.count - 1, 0)
            self.minuteView.scrollRangeToVisible(range)
        }
    }
    
    func STTError(message: String) {
        DispatchQueue.main.async {
            LoadingIndicator.hideLoading()
            let message = "ERROR IN STTConnectionManager: \(message)"
            os_log(.error, log: .system, "%@", message)
            self.Alert("ERROR".localized(), message, nil)
        }
    }
    
    func STTDisconnect() {
        DispatchQueue.main.async {
            if audioEngine.isRunning {
                self.toggleAudio(false)
            }
        }
    }
}
