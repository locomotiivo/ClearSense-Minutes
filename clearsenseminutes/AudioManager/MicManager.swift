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
    
    let sr_in : Int = 48000
    let sr_out : Int = 48000
    var dur_in : Double = 0.002
    var file_name : String = ""
    
    // Eqaulizer - Personalization
    let n_gain_band = 8+1
    var eq_left : [Double]
    var eq_right : [Double]
    var noise_floor: Double
    var optEQ: Bool = false
    
    // IO
    var processing_frame = 128
    var audioUnit: AudioUnit!
//    var cppProcessing: CWrapper?
    let session = AVAudioSession.sharedInstance()

    // input stream buffer
    var bufferSize: Int = 0 // size of data in buffer
    var startIdx: Int = 0
    var bufferIndex: Int = 0 // 현재 버퍼 인덱스
    
    // Output
    var numFramesToRead = 128 * 3 * 2 // 링 버퍼의 크기만큼 데이터를 읽습니다.
    var numFrames = 128 * 3
    var _bytesPerBuffer = 128 * 4

    var inputData : [Float]
    var outputData : [Float]
    
    var rBufferIn : TPCircularBuffer
    var rBufferInBytes = 0
    // stores setting for playback and recording on remote io unit
    var remoteIODesc : AudioComponentDescription!
    // stores playback format
    var fileFormat : AudioStreamBasicDescription!
    
    
    var isRunning : Bool = false
    var isBypassing : Bool = false
    var isAGCEnabled : Bool = false
    var isRecording : Bool = false
    var isSpatial : Bool = false
    var sendFlag : Bool = false
    var rawFlag : Bool = false
    var timer : BackgroundTimer!
    var sr_file: Double = 48000
    var n_hop: Int = 128
    
    var label_txt : String = ""
        
    init() {
        rBufferIn = TPCircularBuffer()
        
        n_hop = 128

        processing_frame = n_hop
        
        // 3 for resampling factor
        numFramesToRead = n_hop * 3 * 2
        numFrames = n_hop * 3
        
        _bytesPerBuffer = n_hop * 4
        
        inputData = [Float](repeating: 0.0, count: numFramesToRead)
//        outputData = [Float](repeating: 0.0, count: numFrames)
        outputData = [Float](repeating: 0.0, count: numFramesToRead)
        eq_left = [Double](repeating : 0.0, count: n_gain_band)
        eq_right = [Double](repeating : 0.0, count: n_gain_band)
        noise_floor = 0.0
        bufferSize  = 0 // size of data in buffer
        startIdx    = 0
        bufferIndex = 0 // 현재 버퍼 인덱스
        
        setupAudioSession()
        setupAudioUnit()
        
        
        do {
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let eq = try appDelegate.persistentContainer.viewContext.fetch(Eq.fetchRequest()) as! [Eq]
            eq.forEach {
                optEQ = $0.on
            }
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
            try session.setPreferredSampleRate(Double(sr_in))
            try session.setPreferredIOBufferDuration(dur_in) // built in mic 128 frame setting
            
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
        
        var err : OSStatus = noErr
        let bufferList = AudioBufferList.allocate(maximumBuffers: 2)
        bufferList[0] = AudioBuffer(
            mNumberChannels: 1,
            mDataByteSize: UInt32(_bytesPerBuffer),
            mData: nil
        )
        bufferList[1] = AudioBuffer(
            mNumberChannels: 1,
            mDataByteSize: UInt32(_bytesPerBuffer),
            mData: nil
        )
        
        err = AudioUnitRender(
            audioUnit!,
            ioActionFlags,
            inTimeStamp,
            1,
            inNumberFrames,
            bufferList.unsafeMutablePointer
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
                    memcpy((dstBuffer! + _bytesPerBuffer), arrR, Int(bufferList[0].mDataByteSize))
                    TPCircularBufferProduce(&rBufferIn, UInt32(neededBytes))
                }
            }
        }
        
        free(bufferList.unsafeMutablePointer)
        
        return err
    }
    
    
    private func setupAudioUnit() {
        var err : OSStatus = noErr
        
        remoteIODesc = AudioComponentDescription(
            componentType: kAudioUnitType_Output,
            componentSubType: kAudioUnitSubType_RemoteIO,
            componentManufacturer: kAudioUnitManufacturer_Apple,
            componentFlags: 0,
            componentFlagsMask: 0
        )
        
        fileFormat = AudioStreamBasicDescription(
            mSampleRate: sr_file,
            mFormatID: kAudioFormatLinearPCM,
            mFormatFlags: kAudioFormatFlagsNativeFloatPacked | kAudioFormatFlagIsNonInterleaved,
            mBytesPerPacket: 4 ,  // Assuming each sample is 4 bytes for 32-bit float
            mFramesPerPacket: 1,           // For PCM, this should be 1
            mBytesPerFrame: 4 ,   // Each frame will have 'channel' number of samples
            mChannelsPerFrame: 2,
            mBitsPerChannel: 32,
            mReserved: 0)
        
        // MARK: find and create new audiocomponent
        let audioComponent = AudioComponentFindNext(nil, &(remoteIODesc)!)
        AudioComponentInstanceNew(audioComponent!, &audioUnit)
        
        // MARK: set MaximumFramesPerSlice
        var turnOn: UInt32 = 1
        var turnOff: UInt32 = 0;
        let kInputBus: AudioUnitElement = 1
        let kOutputBus: AudioUnitElement = 0
        
        var frameCount: UInt32 = UInt32(numFrames) * 2 // 원하는 프레임 수로 설
        err = AudioUnitSetProperty(audioUnit!,
                                   kAudioUnitProperty_MaximumFramesPerSlice,
                                   kAudioUnitScope_Input,
                                   kOutputBus,
                                   &frameCount,
                                   UInt32(MemoryLayout<UInt32>.size))
        
        // MARK: set BypassVoiceProcessing
        err = AudioUnitSetProperty(audioUnit,
                                   kAUVoiceIOProperty_BypassVoiceProcessing,
                                   kAudioUnitScope_Global,
                                   kInputBus,
                                   &turnOff,
                                   UInt32(MemoryLayout<UInt32>.size))
        // MARK: set Enable AGC
        err = AudioUnitSetProperty(audioUnit,
                                   kAUVoiceIOProperty_VoiceProcessingEnableAGC,
                                   kAudioUnitScope_Global,
                                   kInputBus,
                                   &turnOff,
                                   UInt32(MemoryLayout<UInt32>.size))
        // MARK: enable Input
        err = AudioUnitSetProperty(audioUnit!,
                                   kAudioOutputUnitProperty_EnableIO,
                                   kAudioUnitScope_Input,
                                   kInputBus,
                                   &turnOn,
                                   UInt32(MemoryLayout<UInt32>.size))
        // MARK: enable Output
        err = AudioUnitSetProperty(audioUnit!,
                                   kAudioOutputUnitProperty_EnableIO,
                                   kAudioUnitScope_Output,
                                   kOutputBus,
                                   &turnOn,
                                   UInt32(MemoryLayout<UInt32>.size))
        
        //apply format
        err = AudioUnitSetProperty(audioUnit!,
                                   kAudioUnitProperty_StreamFormat,
                                   kAudioUnitScope_Input,
                                   kOutputBus,
                                   &fileFormat,
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
        
        sr_file = sr
        fileFormat = AudioStreamBasicDescription(
            mSampleRate: sr,
            mFormatID: kAudioFormatLinearPCM,
            mFormatFlags: kAudioFormatFlagsNativeFloatPacked | kAudioFormatFlagIsNonInterleaved,
            mBytesPerPacket: 4 ,  // Assuming each sample is 4 bytes for 32-bit float
            mFramesPerPacket: 1,           // For PCM, this should be 1
            mBytesPerFrame: 4 ,   // Each frame will have 'channel' number of samples
            mChannelsPerFrame: 2,
            mBitsPerChannel: 32,
            mReserved: 0)

        err = AudioUnitSetProperty(audioUnit!,
                                   kAudioUnitProperty_StreamFormat,
                                   kAudioUnitScope_Input,
                                   0,
                                   &fileFormat,
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
        let neededBytes : UInt32 = 3 * 2 * UInt32(_bytesPerBuffer)
        var availableBytes : UInt32 = 0
        let srcBufferIn = TPCircularBufferTail(&rBufferIn, &availableBytes)
        guard let ptrIn = srcBufferIn?.assumingMemoryBound(to: Float32.self) else {return}
        
        if (availableBytes >= neededBytes) {

            var ch1_Idx = 0
            var ch2_Idx = 1
            
            for i in 0..<numFramesToRead {
                let sample = ptrIn[bufferIndex]
                if (i % (processing_frame * 2) < processing_frame){
                    inputData[ch1_Idx] = sample;
                    ch1_Idx += 2
                }
                else if (i % (processing_frame * 2) >=  processing_frame){
                    inputData[ch2_Idx] = sample;
                    ch2_Idx += 2
                }
                
                bufferIndex = (bufferIndex + 1) % bufferSize
            }
            
            // begin TODO
            // TODO: send data to server
            // end TODO
            
            var txt = ""
            label_txt = txt
            
            TPCircularBufferConsume(&rBufferIn, neededBytes)
        }
    }
    
    func start_audio_unit(){
        isRunning = true
        startIdx = 0
        label_txt = ""

        bufferSize = numFramesToRead
        
        _TPCircularBufferInit(&rBufferIn, 3 * UInt32(_bytesPerBuffer), MemoryLayout<TPCircularBuffer>.size)
        
        // 5. 오디오 유닛 시작
        AudioOutputUnitStart(audioUnit!)
        
        timer = BackgroundTimer(with: dur_in) { [weak self] in
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



