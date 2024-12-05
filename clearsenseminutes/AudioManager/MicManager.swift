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
    
    let SAMPLE_RATE : Double = 16000
    let CHANNEL_MONO = 1

    var sampleRate : Double = 48000
    let samples : Int = 128
    let bytesPerBuffer = 256
    
    var audioUnit: AudioUnit!
    var convertUnit: AudioUnit!
//    var audioUnitOut: AudioUnit!
    let session = AVAudioSession.sharedInstance()

    var bufferSize: Int = 0
    var startIdx = 0
    var bufferIdx: Int = 0
    
    var rBufferIn : TPCircularBuffer
    var rBufferInBytes = 0
    var isRunning : Bool = false
    var timer : BackgroundTimer!
    
    var turnOn: UInt32 = 1
    var turnOff: UInt32 = 0;
    let kInputBus: AudioUnitElement = 1
    let kOutputBus: AudioUnitElement = 0
    let packetSize = MemoryLayout<UInt16>.size
    
    let ASBDsize : UInt32 = UInt32(MemoryLayout<AudioStreamBasicDescription>.size)
    var inputFormat : AudioStreamBasicDescription!
    var outputFormat : AudioStreamBasicDescription!
    var connection: AudioUnitConnection!
    
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
            try session.setPreferredIOBufferDuration(Double(samples) / sampleRate) // built in mic 128 frame setting
            
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
//        let bufferList = AudioBufferList.allocate(maximumBuffers: CHANNEL_MONO)
//        for i in 0..<CHANNEL_MONO {
//            bufferList[i] = AudioBuffer(
//                mNumberChannels: 1
//                , mDataByteSize: UInt32(bytesPerBuffer)
//                , mData: nil
//            )
//        }
        if let au = audioObj.audioUnit {
            err = AudioUnitRender(
                au,
                ioActionFlags,
                inTimeStamp,
                inBusNumber,
                inNumberFrames,
//                bufferList.unsafeMutablePointer
                ioData!
            )
    
            if err == noErr {
                let abl = UnsafeMutableAudioBufferListPointer(ioData)
                print("\(abl![0].mDataByteSize) , \(ioData!.pointee.mNumberBuffers)")
                let neededBytes = UInt32(CHANNEL_MONO) * abl![0].mDataByteSize
                var availableBytes: UInt32 = 0
                let dstBuffer = TPCircularBufferHead(&rBufferIn, &availableBytes)
                if (availableBytes >= neededBytes) {
                    let data = UnsafeMutableRawPointer(abl![0].mData)
                    if let dptr = data {
                        let arr = dptr.assumingMemoryBound(to: Float32.self)
                        
                        dump(Array(UnsafeBufferPointer(start: arr, count: samples)))
                        
                        memcpy((dstBuffer!), arr, Int(abl![0].mDataByteSize))
                        TPCircularBufferProduce(&rBufferIn, UInt32(neededBytes))
                    }
                }
            }
        }

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
        
        var converterDesc = AudioComponentDescription(
            componentType: kAudioUnitType_FormatConverter,
            componentSubType: kAudioUnitSubType_AUConverter,
            componentManufacturer: kAudioUnitManufacturer_Apple,
            componentFlags: 0,
            componentFlagsMask: 0
        )
        
        // MARK: find and create new audiocomponent
        let IOComponent = AudioComponentFindNext(nil, &(componentDesc))
        AudioComponentInstanceNew(IOComponent!, &audioUnit)
        let converterComponent = AudioComponentFindNext(nil, &(converterDesc))
        AudioComponentInstanceNew(converterComponent!, &convertUnit)
        
        // MARK: enable Input
        err = AudioUnitSetProperty(audioUnit!,
                                   kAudioOutputUnitProperty_EnableIO,
                                   kAudioUnitScope_Input,
                                   kInputBus,
                                   &turnOn,
                                   UInt32(MemoryLayout<UInt32>.size))
        
        err = AudioUnitSetProperty(audioUnit!,
                                   kAudioOutputUnitProperty_EnableIO,
                                   kAudioUnitScope_Output,
                                   kOutputBus,
                                   &turnOff,
                                   UInt32(MemoryLayout<UInt32>.size))
        
        // MARK: Apply Input format to Converter's Input
        inputFormat = AudioStreamBasicDescription(
            mSampleRate: sampleRate,
            mFormatID: kAudioFormatLinearPCM,
            mFormatFlags: kAudioFormatFlagIsPacked | kAudioFormatFlagIsSignedInteger,
            mBytesPerPacket: UInt32(CHANNEL_MONO * packetSize),
            mFramesPerPacket: 1,
            mBytesPerFrame: UInt32(CHANNEL_MONO * packetSize),
            mChannelsPerFrame: UInt32(CHANNEL_MONO),
            mBitsPerChannel: UInt32(8 * packetSize),
            mReserved: 0)
        
//        err = AudioUnitSetProperty(convertUnit!,
        err = AudioUnitSetProperty(audioUnit!,
                                   kAudioUnitProperty_StreamFormat,
                                   kAudioUnitScope_Input,
                                   kOutputBus,
                                   &inputFormat,
                                   ASBDsize)
        if err != noErr {
            let messages = "Error setting up incoming AUDescription: \(err.description)"
            os_log(.error, log: .audio, "%@", messages)
        }
        
        // MARK: Apply Output format to Converter's Output
        outputFormat = AudioStreamBasicDescription(
            mSampleRate: SAMPLE_RATE,
            mFormatID: kAudioFormatLinearPCM,
            mFormatFlags: kAudioFormatFlagIsPacked | kAudioFormatFlagIsSignedInteger,
            mBytesPerPacket: UInt32(CHANNEL_MONO * packetSize),
            mFramesPerPacket: 1,
            mBytesPerFrame: UInt32(CHANNEL_MONO * packetSize),
            mChannelsPerFrame: UInt32(CHANNEL_MONO),
            mBitsPerChannel: UInt32(8 * packetSize),
            mReserved: 0)

        err = AudioUnitSetProperty(convertUnit!,
                                   kAudioUnitProperty_StreamFormat,
                                   kAudioUnitScope_Output,
                                   kOutputBus,
                                   &outputFormat,
                                   ASBDsize)
        if err != noErr {
            let messages = "Error setting up outgoing AUDescription: \(err.description)"
            os_log(.error, log: .audio, "%@", messages)
        }
        
        // MARK: Connection
        connection = AudioUnitConnection(sourceAudioUnit: audioUnit, sourceOutputNumber: 1, destInputNumber: 0)
        err = AudioUnitSetProperty(convertUnit!,
                                   kAudioUnitProperty_MakeConnection,
                                   kAudioUnitScope_Input,
                                   kOutputBus,
                                   &connection,
                                   ASBDsize)
        if err != noErr {
            let messages = "Error setting up connecting AUGraph: \(err.description)"
            os_log(.error, log: .audio, "%@", messages)
        }

        // MARK: Disable auto allocation
        err = AudioUnitSetProperty(audioUnit!,
                                   kAudioUnitProperty_ShouldAllocateBuffer,
                                   kAudioUnitScope_Output,
                                   kOutputBus,
                                   &turnOn,
//                                   &turnOff,
                                   UInt32(MemoryLayout<UInt32>.size))
        if err != noErr {
            let messages = "Error disabling allocation: \(err.description)"
            os_log(.error, log: .audio, "%@", messages)
        }
        
        // MARK: Set Recording callback
        var recordCallbackStruct = AURenderCallbackStruct(
            inputProc: AUrecordCallback,
            inputProcRefCon: Unmanaged.passUnretained(self).toOpaque()
        )
        err = AudioUnitSetProperty(audioUnit!,
                                   kAudioUnitProperty_SetRenderCallback,
//                             kAudioOutputUnitProperty_SetInputCallback,
                             kAudioUnitScope_Global,
                             1,
                             &recordCallbackStruct,
                             UInt32(MemoryLayout<AURenderCallbackStruct>.size))
        
        if err != noErr {
            let messages = "Error setting up AURecordCallback: \(err.description)"
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
        outputFormat = AudioStreamBasicDescription(
            mSampleRate: sr,
            mFormatID: kAudioFormatLinearPCM,
            mFormatFlags: kAudioFormatFlagIsPacked | kAudioFormatFlagIsSignedInteger,
            mBytesPerPacket: UInt32(CHANNEL_MONO * packetSize),
            mFramesPerPacket: 1,
            mBytesPerFrame: UInt32(CHANNEL_MONO * packetSize),
            mChannelsPerFrame: UInt32(CHANNEL_MONO),
            mBitsPerChannel: UInt32(8 * packetSize),
            mReserved: 0)
        
//        err = AudioUnitSetProperty(convertUnit!,
        err = AudioUnitSetProperty(audioUnit!,
                                   kAudioUnitProperty_StreamFormat,
                                   kAudioUnitScope_Input,
                                   kOutputBus,
                                   &inputFormat,
                                   ASBDsize)
        if err != noErr {
            let messages = "Error changing incoming AUDescription: \(err.description)"
            os_log(.error, log: .audio, "%@", messages)
        }

        err = AudioUnitInitialize(audioUnit!)
        if err != noErr {
            let messages = "Error initializing AU: \(err.description)"
            os_log(.error, log: .audio, "%@", messages)
        }
    }
    
    
    @objc private func processData() {
        let neededBytes : UInt32 = UInt32(CHANNEL_MONO * bytesPerBuffer)
        var availableBytes : UInt32 = 0
        let srcBufferIn = TPCircularBufferTail(&rBufferIn, &availableBytes)
        guard let ptrIn = srcBufferIn?.assumingMemoryBound(to: Int16.self) else {
            return
        }
        
        if (availableBytes >= neededBytes) {
            let outputFormatSettings = [
                AVFormatIDKey : kAudioFormatLinearPCM,
                AVLinearPCMBitDepthKey : 16,
                AVLinearPCMIsFloatKey : true,
                AVSampleRateKey : SAMPLE_RATE,
                AVNumberOfChannelsKey : 1
                ] as [String : Any]

            let bufferFormat = AVAudioFormat(settings: outputFormatSettings)!
            guard let outputBuffer = AVAudioPCMBuffer(pcmFormat: bufferFormat, frameCapacity: AVAudioFrameCount(samples)) else {
                return
            }
            for i in 0..<samples {
                outputBuffer.int16ChannelData!.pointee[i] = ptrIn[bufferIdx]
                bufferIdx = (bufferIdx + 1) % samples
            }
            outputBuffer.frameLength = AVAudioFrameCount(samples)
            
            STTconn.send(pcmBuffer: outputBuffer)
            TPCircularBufferConsume(&rBufferIn, neededBytes)
        }
    }
    
    func start_audio_unit(){
        isRunning = true
        
        let size = 32768
        _TPCircularBufferInit(&rBufferIn, UInt32(size), MemoryLayout<TPCircularBuffer>.size)
        
        // 5. 오디오 유닛 시작
        AudioOutputUnitStart(audioUnit!)
        
        timer = BackgroundTimer(with: Double(samples) / sampleRate) { [weak self] in
            guard let `self` = self else {
                return
            }
            if self.isRunning {
                self.processData()
            }
        }
        timer!.activate()

        do {
            try STTconn.connect()
        } catch let err {
        }
        
        os_log(.info, log: .audio, "AU Started")
    }
    
    func stop_audio_unit(){
        isRunning = false
        timer?.suspend()
        
        var err = noErr
        err = AudioOutputUnitStop(audioUnit)
        if err != noErr {
            let messages = "Error stopping AU: \(err.description)"
            os_log(.error, log: .audio, "%@", messages)
        } else {
            os_log(.info, log: .audio, "AU Stopped")
        }
        
        STTconn.disconnect()

        TPCircularBufferCleanup(&rBufferIn)
    }
}



