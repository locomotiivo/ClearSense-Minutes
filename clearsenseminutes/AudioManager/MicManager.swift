import Foundation
import UIKit
import AVFoundation
import CTPCircularBuffer
import OSLog
import CoreData

struct RuntimeError: LocalizedError {
    let description: String
    init(_ desc: String) {
        description = desc
    }
    var errorDescription: String? {
        description
    }
}

@objc protocol AURecordCallbackDelegate {
    func recordCallback(inRefCon: UnsafeMutableRawPointer,
                        ioActionFlags: UnsafeMutablePointer<AudioUnitRenderActionFlags>,
                        inTimeStamp: UnsafePointer<AudioTimeStamp>,
                        inBusNumber: UInt32,
                        inNumberFrames: UInt32,
                        ioData: UnsafeMutablePointer<AudioBufferList>?) -> OSStatus
}

@objc protocol AURenderCallbackDelegate {
    func renderCallback(inRefCon: UnsafeMutableRawPointer,
                        ioActionFlags: UnsafeMutablePointer<AudioUnitRenderActionFlags>,
                        inTimeStamp: UnsafePointer<AudioTimeStamp>,
                        inBusNumber: UInt32,
                        inNumberFrames: UInt32,
                        ioData: UnsafeMutablePointer<AudioBufferList>?) -> OSStatus
}

private let AUrecordCallback: AURenderCallback = {(inRefCon,
                                                 ioActionFlags/*: UnsafeMutablePointer<AudioUnitRenderActionFlags>*/,
                                                 inTimeStamp/*: UnsafePointer<AudioTimeStamp>*/,
                                                   inBusNumber/*: UInt32*/,
                                                 inNumberFrames/*: UInt32*/,
                                                 ioData/*: UnsafeMutablePointer<AudioBufferList>*/)
    -> OSStatus
    in
    let delegate = unsafeBitCast(inRefCon, to: AURecordCallbackDelegate.self)
    let result = delegate.recordCallback(inRefCon: inRefCon,
                                         ioActionFlags: ioActionFlags,
                                         inTimeStamp: inTimeStamp,
                                         inBusNumber: inBusNumber,
                                         inNumberFrames: inNumberFrames,
                                         ioData: ioData)
    return result
}

class AudioEngineManager : AURecordCallbackDelegate {

    static let shared = AudioEngineManager()
    private var mutex: pthread_mutex_t = pthread_mutex_t()
    
    static let SAMPLE_RATE : Double = 16000
    var sampleRate : Double = 48000
    let samples : Double = 128
    let bytesPerBuffer = 256
    
    var audioUnit: AudioUnit!
    let session = AVAudioSession.sharedInstance()

    var bufferSize: Int = 0
    var startIdx = 0
    var bufferIndex: Int = 0
    
    var rBufferIn : TPCircularBuffer
    var rBufferInBytes = 0
    
    var isRunning : Bool = false
    var timer : BackgroundTimer!
    
    var label_txt : String = ""
        
    init() {
        rBufferIn = TPCircularBuffer()
        setupAudioSession()
        setupAudioUnit()
        
        do {
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let eq = try appDelegate.persistentContainer.viewContext.fetch(Eq.fetchRequest()) as! [Eq]
        } catch {
            let message = "Error loading Core Data: \(error.localizedDescription)"
            os_log(.error, log: .system, "%@", message)
        }
        
        pthread_mutex_init(&mutex, nil)
    }
    
    private func setupAudioSession() {
        // MARK: setup Session
        do {
            try session.setCategory(.playAndRecord,
                                     mode: .videoRecording,
                                    options: [.allowBluetoothA2DP, .allowAirPlay])
            try session.setPreferredSampleRate(sampleRate)
            try session.setPreferredIOBufferDuration(samples / sampleRate) // built in mic 128 frame setting
            
            guard let inputs = session.availableInputs,
                  let mic = inputs.first(where: {$0.portType == .builtInMic})
            else {
                throw RuntimeError("The device must have a built-in microphone!")
            }
            try session.setPreferredInput(mic)
                        
            guard let preferredInput = session.preferredInput,
                  let dataSource = preferredInput.dataSources,
                  let newDataSource = dataSource.first(where: { $0.orientation == .front }),
                  let supportedPolarPatterns = newDataSource.supportedPolarPatterns
            else {
                throw RuntimeError("Unexpected Error Setting Directivity!")
            }
            
            if supportedPolarPatterns.contains(.stereo) {
                try newDataSource.setPreferredPolarPattern(.cardioid)
                try newDataSource.setPreferredPolarPattern(.stereo)
            }
            try preferredInput.setPreferredDataSource(newDataSource)
            try session.setPreferredInputOrientation(.portrait)
            
            try session.setActive(true, options: [.notifyOthersOnDeactivation])
        } catch {
            let messages = "Error setting up Session, \(error.localizedDescription)"
            os_log(.error, log: .audio, "%@", messages)
        }
    }
    
    
    // MARK: recordCallback
    @objc func recordCallback(inRefCon: UnsafeMutableRawPointer,
                              ioActionFlags: UnsafeMutablePointer<AudioUnitRenderActionFlags>,
                              inTimeStamp: UnsafePointer<AudioTimeStamp>,
                              inBusNumber: UInt32,
                              inNumberFrames: UInt32,
                              ioData: UnsafeMutablePointer<AudioBufferList>?) -> OSStatus {
        
        let audioObj = unsafeBitCast(inRefCon, to: AudioEngineManager.self)
        var err : OSStatus = noErr
        let bufferList = AudioBufferList.allocate(maximumBuffers: 2)
        for i in 0..<2 {
            bufferList[i] = AudioBuffer(
                mNumberChannels: 1
                , mDataByteSize: UInt32(bytesPerBuffer)
                , mData: nil
            )
        }
        if let au = audioObj.audioUnit {
            err = AudioUnitRender(
                au,
                ioActionFlags,
                inTimeStamp,
                inBusNumber,
                inNumberFrames,
                bufferList.unsafeMutablePointer
//                &bufferList
            )
            
    
            if err == noErr {
                let neededBytes = 2 * bufferList[0].mDataByteSize
                var availableBytes: UInt32 = 0
                let dstBuffer = TPCircularBufferHead(&rBufferIn, &availableBytes)
                if (availableBytes >= neededBytes) {
                    let dataL = UnsafeMutableRawPointer(bufferList[0].mData)
                    let dataR = UnsafeMutableRawPointer(bufferList[1].mData)
                    if let dptrL = dataL,
                       let dptrR = dataR {
                        let arrL = dptrL.assumingMemoryBound(to: Float32.self)
                        let arrR = dptrR.assumingMemoryBound(to: Float32.self)
                        memcpy((dstBuffer!), arrL, Int(bufferList[0].mDataByteSize))
                        memcpy((dstBuffer! + bytesPerBuffer), arrR, Int(bufferList[0].mDataByteSize))
                        TPCircularBufferProduce(&rBufferIn, UInt32(neededBytes))
                    }
                }
            }
        }
        
        free(bufferList.unsafeMutablePointer)

        return err
    }
    
    
    private func setupAudioUnit() {
        var err : OSStatus = noErr
        
        var componentDesc = AudioComponentDescription(
            componentType: kAudioUnitType_Output,
            componentSubType: kAudioUnitSubType_RemoteIO,
            componentManufacturer: kAudioUnitManufacturer_Apple,
            componentFlags: 0,
            componentFlagsMask: 0
        )
        
        // MARK: find and create new audiocomponent
        let audioComponent = AudioComponentFindNext(nil, &(componentDesc))
        AudioComponentInstanceNew(audioComponent!, &audioUnit)
        
        // MARK: set MaximumFramesPerSlice
        var turnOn: UInt32 = 1
        var turnOff: UInt32 = 0;
        let kInputBus: AudioUnitElement = 1
        let kOutputBus: AudioUnitElement = 0
        
        // MARK: enable Input
        err = AudioUnitSetProperty(audioUnit!,
                                   kAudioOutputUnitProperty_EnableIO,
                                   kAudioUnitScope_Input,
                                   kInputBus,
                                   &turnOn,
                                   UInt32(MemoryLayout<UInt32>.size))
        
        let channel = 2
        let packetSize = MemoryLayout<UInt16>.size
        var streamFormat = AudioStreamBasicDescription(
            mSampleRate: sampleRate,
            mFormatID: kAudioFormatLinearPCM,
            mFormatFlags: kAudioFormatFlagIsPacked | kAudioFormatFlagIsSignedInteger, //kAudioFormatFlagsNativeFloatPacked | kLinearPCMFormatFlagIsNonInterleaved,
            mBytesPerPacket: UInt32(channel * packetSize) ,  // Assuming each sample is 4 bytes for 32-bit float
            mFramesPerPacket: 1,           // For PCM, this should be 1
            mBytesPerFrame: UInt32(channel * packetSize),   // Each frame will have 'channel' number of samples
            mChannelsPerFrame: UInt32(channel),
            mBitsPerChannel: UInt32(8 * packetSize),
            mReserved: 0)

        // MARK: apply format
        err = AudioUnitSetProperty(audioUnit!,
                                   kAudioUnitProperty_StreamFormat,
                                   kAudioUnitScope_Input,
                                   kOutputBus,
                                   &streamFormat,
                                   UInt32(MemoryLayout<AudioStreamBasicDescription>.size))
        
        err = AudioUnitSetProperty(audioUnit!,
                                   kAudioUnitProperty_ShouldAllocateBuffer,
                                   kAudioUnitScope_Output,
                                   kOutputBus,
                                   &turnOff,
                                   UInt32(MemoryLayout<UInt32>.size))
        
        if err != noErr {
            let messages = "Error setting up AU: \(err.description)"
            os_log(.error, log: .audio, "%@", messages)
        }
        
        // MARK: Set Recording callback
        var recordCallbackStruct = AURenderCallbackStruct(
            inputProc: AUrecordCallback,
            inputProcRefCon: Unmanaged.passUnretained(self).toOpaque()
        )
        err = AudioUnitSetProperty(audioUnit!,
                             kAudioOutputUnitProperty_SetInputCallback,
                             kAudioUnitScope_Global,
                             1,
                             &recordCallbackStruct,
                             UInt32(MemoryLayout<AURenderCallbackStruct>.size))
        
        if err != noErr {
            let messages = "Error setting up AU: \(err.description)"
            os_log(.error, log: .audio, "%@", messages)
        }
        
        err = AudioUnitInitialize(audioUnit!)
        if err != noErr {
            let messages = "Error initializing AU: \(err.description)"
            os_log(.error, log: .audio, "%@", messages)
        }
    }
    
    func changeSampleRate(_ sr: Double) {
        var err : OSStatus = noErr
        
        err = AudioUnitUninitialize(audioUnit!)
        if err != noErr {
            let messages = "Error uninitializing AU: \(err.description)"
            os_log(.error, log: .audio, "%@", messages)
        }
        
        sampleRate = sr
        let packetSize = MemoryLayout<UInt16>.size
        let channel = 2
        var streamFormat = AudioStreamBasicDescription(
            mSampleRate: sr,
            mFormatID: kAudioFormatLinearPCM,
            mFormatFlags:  kAudioFormatFlagIsPacked | kAudioFormatFlagIsSignedInteger, //kAudioFormatFlagsNativeFloatPacked | kLinearPCMFormatFlagIsNonInterleaved,
            mBytesPerPacket: UInt32(channel * packetSize),
            mFramesPerPacket: 1,           // For PCM, this should be 1
            mBytesPerFrame: UInt32(channel * packetSize),   // Each frame will have 'channel' number of samples
            mChannelsPerFrame: UInt32(channel),
            mBitsPerChannel: UInt32(8 * packetSize),
            mReserved: 0
        )

        err = AudioUnitSetProperty(audioUnit!,
                                   kAudioUnitProperty_StreamFormat,
                                   kAudioUnitScope_Input,
                                   0,
                                   &streamFormat,
                                   UInt32(MemoryLayout<AudioStreamBasicDescription>.size))
        if err != noErr {
            let messages = "Error changing stream format: \(err.description)"
            os_log(.error, log: .audio, "%@", messages)
        }
        
        err = AudioUnitInitialize(audioUnit!)
        if err != noErr {
            let messages = "Error initializing AU: \(err.description)"
            os_log(.error, log: .audio, "%@", messages)
        }
    }
    
    
    @objc private func processData() {
        let neededBytes : UInt32 = 2 * UInt32(bytesPerBuffer)
        var availableBytes : UInt32 = 0
        let srcBufferIn = TPCircularBufferTail(&rBufferIn, &availableBytes)
        guard let ptrIn = srcBufferIn?.assumingMemoryBound(to: Float32.self) else {return}
        
        if (availableBytes >= neededBytes) {
            // begin TODO
            // TODO: send data to server
            // end TODO
            print("NEEDED[\(neededBytes)] / AVAILABLE[\(availableBytes)]")
            var txt = ""
            label_txt = txt
            
            TPCircularBufferConsume(&rBufferIn, neededBytes)
        }
    }
    
    func start_audio_unit(){
        isRunning = true
        startIdx = 0
        label_txt = ""
        
        let size = 32768
        _TPCircularBufferInit(&rBufferIn, UInt32(size), MemoryLayout<TPCircularBuffer>.size)
        
        // 5. 오디오 유닛 시작
        AudioOutputUnitStart(audioUnit!)
        
        timer = BackgroundTimer(with: samples / sampleRate) { [weak self] in
            guard let `self` = self else {
                return
            }
            if self.isRunning {
                self.processData()
            }
        }
        timer!.activate()

        os_log(.info, log: .audio, "AU Started")
    }
    
    func stop_audio_unit(){
        isRunning = false
        timer?.suspend()
        startIdx = 0
        label_txt = ""
        
        var err = noErr
        err = AudioOutputUnitStop(audioUnit)
        if err != noErr {
            let messages = "Error stopping AU: \(err.description)"
            os_log(.error, log: .audio, "%@", messages)
        } else {
            os_log(.info, log: .audio, "AU Stopped")
        }

        TPCircularBufferCleanup(&rBufferIn)
    }
}



