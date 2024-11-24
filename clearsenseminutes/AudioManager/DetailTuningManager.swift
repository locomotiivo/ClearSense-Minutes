//
//  DetailTuningManager.swift
//  clearsenseminutes
//
//  Created by HWANJUN YU on 11/18/24.
//

import Foundation
import UIKit
import AVFoundation
import MediaPlayer
import OSLog
import CoreData

class DetailTuningManager {
    
    enum ToneType {
        case sine
        case square
        case triangle
        case sawtooth
    }
    
    enum EarSide: Int {
        case left = -1
        case right = 1
    }
    
    static let shared = DetailTuningManager()
    
    private var mutex = pthread_mutex_t()
    
    private var engine: AVAudioEngine!
    private var playerNode: AVAudioPlayerNode!
    
    private var freq: Double = 1000.0   // 주파수
    private var ear: EarSide = .right   // 귀 방향
    private var gain: Float = 1.0       // 부스트 정도 (데시벨)
    private var prev_t: Int = 0
    private var scaler: Float = 0.05
    private var toneType: ToneType = .sine
    
    var isPlay = false
    
    // MARK: - 초기화
    private init() {
        setupAudioEngine()
        pthread_mutex_init(&mutex, nil)
    }
    
    private func setupAudioEngine() {
        engine = AVAudioEngine()
        playerNode = AVAudioPlayerNode()
        
        engine.attach(playerNode)
        
        engine.connect(playerNode, to: engine.mainMixerNode, format: nil)
        
        do {
            try engine.start()
        } catch {
            os_log(.error, log: .audio, "%@", "Error starting AVAudioEngine: \(error)")
        }
    }
    
    // MARK: - 조작
    // 비프음 재생
    func start() {
        isPlay = true
        playTone()
    }
    
    // 비프음 정지
    func stop() {
        isPlay = false
        playerNode.stop()
    }
    
    // 주파수 변경
    func setFreq(_ freq: Double) {
        let prevFreq = self.freq
        self.freq = freq
        
        if isPlay, prevFreq != freq {
            stop()
            start()
        }
    }
    
    // 좌우 귀 세팅
    func setEar(_ earSide: EarSide) {
        ear = earSide
        
        if isPlay {
            stop()
            start()
        }
    }
    
    // 부스트 조절
    func setGain(_ value: Float) {
        let gain = pow(10, value / 20)
        engine.mainMixerNode.outputVolume = gain
    }
    
    // MARK: - 비프음 구현
    private func playTone() {
        let sampleRate: Double = audioEngine.session.sampleRate
        let frameCount = AVAudioFrameCount(sampleRate)
        
        let buffer = AVAudioPCMBuffer(pcmFormat: engine.mainMixerNode.outputFormat(forBus: 0), frameCapacity: frameCount)!
        buffer.frameLength = frameCount
        
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
            buffer.floatChannelData?.pointee[frame + Int(frameCount)] = sampleValue
        }
        
        prev_t = cur_frame + 1
        if prev_t >= Int(sampleRate) - 1 {
            prev_t = 0
        }
        
        playerNode.scheduleBuffer(buffer, at: nil, options: .loops, completionHandler: nil)
        playerNode.pan = Float(ear.rawValue)
        playerNode.play()
    }
}
