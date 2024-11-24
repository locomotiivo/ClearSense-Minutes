import Foundation
import UIKit
import AVFoundation
import MediaPlayer
import OSLog
import CoreData

class HearingTestManager {

    enum ToneType {
        case sine
        case square
        case triangle
        case sawtooth
    }
    
    static let shared = HearingTestManager()
    private var mutex: pthread_mutex_t = pthread_mutex_t()
    
    private var freq: Double = 1000.0
    private var ear: Int = 1
    
    private var engine: AVAudioEngine!
    private var playerNode: AVAudioPlayerNode!
    private var toneType: ToneType = .sine
    
    
    private var scaler : Float = 0.05
    private var prev_t : Int = 0;
    public var gain : Float = 1.0;
    
    var state: Bool = false
    
    // MARK: - 초기화
    init() {
        setupAudioEngine()
        pthread_mutex_init(&mutex, nil)
    }
    
    private func setupAudioEngine() {
        engine = AVAudioEngine()
        playerNode = AVAudioPlayerNode()
        engine.attach(playerNode)
        
        let mainMixer = engine.mainMixerNode
        engine.connect(playerNode, to: mainMixer, format: mainMixer.outputFormat(forBus: 0))
        
        do {
            try engine.start()
        } catch {
            let message = "Error starting AVAudioEngine: \(error)"
            os_log(.error, log: .audio, "%@", message)
        }
    }
    
    // MARK: - 조작
    // 원하는 횟수만큼 비프음 재생 (기본은 무한재생)
    func start(_ cnt: Int = -1) {
        state = true
        
        if cnt > 0 {
            var cur = 0
            func playNextTone() {
                if cur < cnt {
                    playTone(isLoop: false) {
                        cur += 1
                        playNextTone()
                    }
                }
            }
            playNextTone()
        } else {
            playTone(isLoop: true) { }
        }
    }
    
    // 비프음 정지
    func stop() {
        state = false
        playerNode.stop()
    }
    
    func setFreq(_ freq: Double) {
        self.freq = freq
        
        if state {
            stop()
            start()
        }
    }
    
    // 좌우 귀 세팅
    func setEar(isLeft: Bool) {
        ear = isLeft ? 0 : 1
        
        if state {
            playerNode.pan = (ear > 0) ? 1 : -1
        }
    }
    
    // 부스트 조절
    func setGain(_ value: Float) {
        gain = pow(10, value / 20)
        
        if state {
//            stop()
            start()
        }
    }
    
    // MARK: - 비프음 구현
    // 비프음 출력
    private func playTone(isLoop: Bool, _ completion: @escaping () -> Void) {
        let sampleRate: Double = audioEngine.session.sampleRate
        let duration: Double = 0.5
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        let augFrameCount = isLoop ? frameCount : frameCount + UInt32(Int(sampleRate * 0.2))
        
        let format = engine.mainMixerNode.outputFormat(forBus: 0)
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: augFrameCount)!
        buffer.frameLength = augFrameCount
        
        let theta = 2.0 * Double.pi * freq / sampleRate
        var cur_frame = 0
        
        for frame in 0..<Int(frameCount) {
            cur_frame = prev_t + frame
            var sampleValue: Float
            
            switch toneType {
            case .sine:
                sampleValue = Float(sin(Double(cur_frame) * theta))
            case .square:
                sampleValue = Float((sin(Double(cur_frame) * theta) > 0) ? 1.0 : -1.0)
            case .triangle:
                sampleValue = Float(asin(sin(Double(cur_frame) * theta)) * (2.0 / Double.pi))
            case .sawtooth:
                sampleValue = Float(2.0 * (Double(cur_frame) * freq / sampleRate - floor(0.5 + Double(cur_frame) * freq / sampleRate)))
            }
            
            sampleValue *= gain * scaler
            buffer.floatChannelData?.pointee[frame] = sampleValue
            buffer.floatChannelData?.pointee[frame + Int(augFrameCount)] = sampleValue
        }
        
        prev_t = cur_frame + 1
        if prev_t >= Int(sampleRate) - 1 {
            prev_t = 0
        }
        
        playerNode.scheduleBuffer(buffer, at: nil, options: isLoop ? .loops : .interrupts, completionHandler: completion)
        playerNode.pan = (ear > 0) ? 1 : -1
        playerNode.play()
    }
    
    // MARK: - ???
    func playMute(_ completion: @escaping () -> Void) {
        let sampleRate: Double = 44100.0
        let duration: Double = 0.1
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        
        let format = engine.mainMixerNode.outputFormat(forBus: 0)
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
        buffer.frameLength = frameCount
        
        playerNode.pan = (ear > 0) ? 1 : -1
        playerNode.scheduleBuffer(buffer, at: nil, options: .interrupts, completionHandler: completion)
        playerNode.play()
    }
    
    func dispose() {
        playerNode.stop()
        engine.stop()
    }
}
