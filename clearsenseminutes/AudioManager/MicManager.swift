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

private let AUrenderCallback: AURenderCallback = {(inRefCon,
                                                 ioActionFlags/*: UnsafeMutablePointer<AudioUnitRenderActionFlags>*/,
                                                 inTimeStamp/*: UnsafePointer<AudioTimeStamp>*/,
                                                   inBusNumber/*: UInt32*/,
                                                 inNumberFrames/*: UInt32*/,
                                                 ioData/*: UnsafeMutablePointer<AudioBufferList>*/)
    -> OSStatus
    in
    let delegate = unsafeBitCast(inRefCon, to: AURenderCallbackDelegate.self)
    let result = delegate.renderCallback(inRefCon: inRefCon,
                                         ioActionFlags: ioActionFlags,
                                         inTimeStamp: inTimeStamp,
                                         inBusNumber: inBusNumber,
                                         inNumberFrames: inNumberFrames,
                                         ioData: ioData)
    return result
}

class AudioEngineManager : AURecordCallbackDelegate,
                           AURenderCallbackDelegate {
    
    static let shared = AudioEngineManager()
    private var mutexFile: pthread_mutex_t = pthread_mutex_t()
    private var mutexTPC: pthread_mutex_t = pthread_mutex_t()

    let samples = 128
    var sampleRate : Double = 48000
    let SAMPLE_RATE : Double = 16000
    let AMPLIFY_CONST : Float = 2
    private let bytesPerBufferIn = 128 * MemoryLayout<Float32>.size
    private let bytesPerBufferOut = 128 * MemoryLayout<Int16>.size
    private let packetSizeIn = MemoryLayout<Float32>.size
    private let packetSizeOut = MemoryLayout<UInt16>.size
    
    // IO
    var AUInput: AudioUnit!
    var AUConvert: AVAudioConverter!
    let session = AVAudioSession.sharedInstance()
    
    // Output
    let maxFrames = 128 * 3 * 2
    var rBufferIn : TPCircularBuffer
    var rBufferOut : TPCircularBuffer
    var remoteIODesc : AudioComponentDescription!
    
    private var turnOn: UInt32 = 1
    private var turnOff: UInt32 = 0;
    private let kInputBus: AudioUnitElement = 1
    private let kOutputBus: AudioUnitElement = 0
    
    var isRunning : Bool = false
    var timer : BackgroundTimer!
    
    private let ASBDsize : UInt32 = UInt32(MemoryLayout<AudioStreamBasicDescription>.size)
    private var inputFormat : AudioStreamBasicDescription!
    private var inFormat : AVAudioFormat!
    private var outFormat : AVAudioFormat!

    private var destFile: ExtAudioFileRef?
    private var destFileName = ""
    private var destFileURL: URL?

    static var iterConvert: UInt64 = 0
    static var iterRecord: UInt64 = 0
    var isRecording = false { didSet { print("isRecording: \(isRecording)") } }
    
    init() {
        rBufferIn = TPCircularBuffer()
        rBufferOut = TPCircularBuffer()
        setupAudioSession()
        setupAudioUnit()
        pthread_mutex_init(&mutexFile, nil)
        pthread_mutex_init(&mutexTPC, nil)
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
        
        var err : OSStatus = noErr
        let bufferList = AudioBufferList.allocate(maximumBuffers: 2)
        bufferList[0] = AudioBuffer(
            mNumberChannels: 1,
            mDataByteSize: UInt32(bytesPerBufferIn),
            mData: nil
        )
        bufferList[1] = AudioBuffer(
            mNumberChannels: 1,
            mDataByteSize: UInt32(bytesPerBufferIn),
            mData: nil
        )
        
        err = AudioUnitRender(
            AUInput!,
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
                    memcpy((dstBuffer! + bytesPerBufferIn), arrR, Int(bufferList[0].mDataByteSize))
                    TPCircularBufferProduce(&rBufferIn, UInt32(neededBytes))
                }
                
#if DEBUG
                if isRecording && 0 == pthread_mutex_trylock(&mutexFile) {
                    err = ExtAudioFileWriteAsync(destFile!, inNumberFrames, bufferList.unsafePointer)
                    if err != noErr {
                        let messages = "Error while writing to file: \(err.description)"
                        os_log(.error, log: .audio, "%@", messages)
                    }
                    pthread_mutex_unlock(&mutexFile)
                }
#endif
            }
        }
        
        free(bufferList.unsafeMutablePointer)
        
        return err
    }
    
    // MARK: renderCallback
    @objc func renderCallback(inRefCon: UnsafeMutableRawPointer,
                              ioActionFlags: UnsafeMutablePointer<AudioUnitRenderActionFlags>,
                              inTimeStamp: UnsafePointer<AudioTimeStamp>,
                              inBusNumber: UInt32,
                              inNumberFrames: UInt32,
                              ioData: UnsafeMutablePointer<AudioBufferList>?) -> OSStatus {
        
        var err: OSStatus = noErr
        
        // 입력 데이터 가져오기
        let abl = UnsafeMutableAudioBufferListPointer(ioData)
        let frames = Int(abl![0].mDataByteSize / UInt32(MemoryLayout<Float>.size))
        let neededBytes : UInt32 = 2 *  UInt32(bytesPerBufferIn)
        var availableBytes : UInt32 = 0
        let srcBuffer = TPCircularBufferTail(&rBufferOut, &availableBytes)
        
        let ptrOut = srcBuffer?.assumingMemoryBound(to: Float32.self)
        if (availableBytes >= neededBytes) {
            for i in 0..<Int(ioData!.pointee.mNumberBuffers) {
                let audioBuffer: AudioBuffer = abl![i]
                let audioData = audioBuffer.mData?.assumingMemoryBound(to: Float32.self)
                for j in 0..<frames {
                    audioData?[j] = ptrOut![j]
                }
            }
            TPCircularBufferConsume(&rBufferOut, 2 * abl![0].mDataByteSize)
        } else {
            for i in 0..<Int(ioData!.pointee.mNumberBuffers) {
                let audioBuffer: AudioBuffer = abl![i]
                let audioData = audioBuffer.mData?.assumingMemoryBound(to: Float32.self)
                for j in 0..<frames {
                    audioData?[j] = 0.0
                }
            }
            TPCircularBufferConsume(&rBufferOut, availableBytes)
        }
        
        return err
    }
    // End of renderCallback
    
    @objc private func processData() {
        let neededBytes : UInt32 = 2 * UInt32(bytesPerBufferIn)
        var availableBytes : UInt32 = 0
        let srcBufferIn = TPCircularBufferTail(&rBufferIn, &availableBytes)
        guard let ptrIn = srcBufferIn?.assumingMemoryBound(to: Float32.self) else {return}
        if (availableBytes >= neededBytes) {
            if 0 == pthread_mutex_trylock(&mutexTPC) {
                var dataL = [Float32](repeating: 0, count: samples)
                var dataR = [Float32](repeating: 0, count: samples)
                for i in 0..<Int(samples) {
                    dataL[i] = ptrIn[i] * AMPLIFY_CONST
                    dataR[i] = ptrIn[i + samples] * AMPLIFY_CONST
                }
                
                var outputData = [Float32](repeating: 0, count: samples * 2)
                for i in 0..<Int(samples * 2) {
                    outputData[i] = ptrIn[i]
                }
                
                dataL.withUnsafeMutableBufferPointer { bytesL in
                    dataR.withUnsafeMutableBufferPointer { bytesR in
                        var bufferList = AudioBufferList.allocate(maximumBuffers: 2)
                        bufferList[0] = AudioBuffer(mNumberChannels: 1, mDataByteSize: UInt32(bytesPerBufferIn), mData: bytesL.baseAddress)
                        bufferList[1] = AudioBuffer(mNumberChannels: 1, mDataByteSize: UInt32(bytesPerBufferIn), mData: bytesR.baseAddress)
                        defer { bufferList.unsafeMutablePointer.deallocate() }
                        let pcmBuffer = AVAudioPCMBuffer(pcmFormat: inFormat, bufferListNoCopy: bufferList.unsafeMutablePointer)!
                        
                        if let convertedBuffer = convertBuffer(buffer: pcmBuffer, from: pcmBuffer.format, to: outFormat) {
                            STTConn.request(pcmBuffer: convertedBuffer)
                            //                            STTconn.send(pcmBuffer: convertedBuffer)
                        }
                    }
                }
                
                let neededBytesOut = neededBytes
                var availableBytesOut: UInt32 = 0
                let dstBuffer = TPCircularBufferHead(&rBufferOut, &availableBytesOut)
                if (availableBytesOut >= neededBytesOut) {
                    memcpy((dstBuffer!), &outputData, Int(neededBytesOut))
                    TPCircularBufferProduce(&rBufferOut, neededBytesOut)
                }
                
                TPCircularBufferConsume(&rBufferIn, neededBytes)
            }
            pthread_mutex_unlock(&mutexTPC)
        }
    }
    
    private func convertBuffer(buffer: AVAudioPCMBuffer,
                               from inputFormat: AVAudioFormat,
                               to outputFormat: AVAudioFormat) -> AVAudioPCMBuffer? {
        var data = false
        let inputCallback: AVAudioConverterInputBlock = { inNumPackets, outStatus in
            if data {
                outStatus.pointee = .noDataNow
                return nil
            }
            data = true
            outStatus.pointee = .haveData
            return buffer
        }
        
        let capacity = UInt32(Double(buffer.frameCapacity) * sampleRate / SAMPLE_RATE)
        let convertedBuffer = AVAudioPCMBuffer(pcmFormat: outputFormat, frameCapacity: capacity)!
        
        var error: NSError?
        _ = AUConvert.convert(to: convertedBuffer, error: &error, withInputFrom: inputCallback)
        if let error = error {
            print("Error during conversion: \(error.localizedDescription)")
            return nil
        }
        
        return convertedBuffer
    }
    
    private func setupAudioUnit() {
        var err : OSStatus = noErr
        
        // MARK: find and create new audiocomponent
        remoteIODesc = AudioComponentDescription(
            componentType: kAudioUnitType_Output,
            componentSubType: kAudioUnitSubType_RemoteIO,
            componentManufacturer: kAudioUnitManufacturer_Apple,
            componentFlags: 0,
            componentFlagsMask: 0
        )
        let audioComponent = AudioComponentFindNext(nil, &(remoteIODesc)!)
        AudioComponentInstanceNew(audioComponent!, &AUInput)
        
        inputFormat = AudioStreamBasicDescription(
            mSampleRate: sampleRate,
            mFormatID: kAudioFormatLinearPCM,
            mFormatFlags: kAudioFormatFlagsNativeFloatPacked | kAudioFormatFlagIsNonInterleaved,
            mBytesPerPacket: UInt32(packetSizeIn) ,  // Assuming each sample is 4 bytes for 32-bit float
            mFramesPerPacket: 1,           // For PCM, this should be 1
            mBytesPerFrame: UInt32(packetSizeIn) ,   // Each frame will have 'channel' number of samples
            mChannelsPerFrame: 2,
            mBitsPerChannel: 32,
            mReserved: 0)
        
        // MARK: set MaximumFramesPerSlice
        var frameCount: UInt32 = UInt32(maxFrames)
        err = AudioUnitSetProperty(AUInput!,
                                   kAudioUnitProperty_MaximumFramesPerSlice,
                                   kAudioUnitScope_Input,
                                   kOutputBus,
                                   &frameCount,
                                   UInt32(MemoryLayout<UInt32>.size))
        
        // MARK: set BypassVoiceProcessing
        err = AudioUnitSetProperty(AUInput,
                                   kAUVoiceIOProperty_BypassVoiceProcessing,
                                   kAudioUnitScope_Global,
                                   kInputBus,
                                   &turnOff,
                                   UInt32(MemoryLayout<UInt32>.size))
        
        // MARK: enable Input
        err = AudioUnitSetProperty(AUInput!,
                                   kAudioOutputUnitProperty_EnableIO,
                                   kAudioUnitScope_Input,
                                   kInputBus,
                                   &turnOn,
                                   UInt32(MemoryLayout<UInt32>.size))
        // MARK: enable Output
        err = AudioUnitSetProperty(AUInput!,
                                   kAudioOutputUnitProperty_EnableIO,
                                   kAudioUnitScope_Output,
                                   kOutputBus,
                                   &turnOn,
                                   UInt32(MemoryLayout<UInt32>.size))
        
        // MARK: apply format & converter
        err = AudioUnitSetProperty(AUInput!,
                                   kAudioUnitProperty_StreamFormat,
                                   kAudioUnitScope_Input,
                                   kOutputBus,
                                   &inputFormat,
                                   UInt32(MemoryLayout<AudioStreamBasicDescription>.size))
        
        inFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32,
                                 sampleRate: sampleRate,
                                 channels: 2,
                                 interleaved: false)
        outFormat = AVAudioFormat(commonFormat: .pcmFormatInt16,
                                  sampleRate: SAMPLE_RATE,
                                  channels: 1,
                                  interleaved: false)
        if let AUConvert = AUConvert {
            AUConvert.reset()
        }
        AUConvert = AVAudioConverter(from: inFormat, to: outFormat)
        
        // MARK: turn off auto allocation for AudioBuffers
        err = AudioUnitSetProperty(AUInput!,
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
        err = AudioUnitSetProperty(AUInput!,
                             kAudioOutputUnitProperty_SetInputCallback,
                             kAudioUnitScope_Global,
                             1,
                             &recordCallbackStruct,
                             UInt32(MemoryLayout<AURenderCallbackStruct>.size))
        
#if DEBUG
        if isRecording {
            // MARK: Set Rendering callback
            var renderCallbackStruct = AURenderCallbackStruct(
                inputProc: AUrenderCallback,
                inputProcRefCon: Unmanaged.passUnretained(self).toOpaque()
            )
            err = AudioUnitSetProperty(AUInput!,
                                 kAudioUnitProperty_SetRenderCallback,
                                 kAudioUnitScope_Global,
                                 0,
                                 &renderCallbackStruct,
                                 UInt32(MemoryLayout<AURenderCallbackStruct>.size))
            
            if err != noErr {
                let messages = "Error setting up AU: \(err.description)"
                os_log(.error, log: .audio, "%@", messages)
            }
        }
#endif
        err = AudioUnitInitialize(AUInput!)
        if err != noErr {
            let messages = "Error initializing AU: \(err.description)"
            os_log(.error, log: .audio, "%@", messages)
        }
    }
    
    func changeSampleRate(_ sr: Double) {
        var err : OSStatus = noErr
        
        err = AudioUnitUninitialize(AUInput!)
        if err != noErr {
            let messages = "Error uninitializing AU: \(err.description)"
            os_log(.error, log: .audio, "%@", messages)
        }
        
        sampleRate = sr
        inputFormat = AudioStreamBasicDescription(
            mSampleRate: sampleRate,
            mFormatID: kAudioFormatLinearPCM,
            mFormatFlags: kAudioFormatFlagsNativeFloatPacked | kAudioFormatFlagIsNonInterleaved,
            mBytesPerPacket: UInt32(packetSizeIn) ,  // Assuming each sample is 4 bytes for 32-bit float
            mFramesPerPacket: 1,           // For PCM, this should be 1
            mBytesPerFrame: UInt32(packetSizeIn) ,   // Each frame will have 'channel' number of samples
            mChannelsPerFrame: 2,
            mBitsPerChannel: 32,
            mReserved: 0)

        err = AudioUnitSetProperty(AUInput!,
                                   kAudioUnitProperty_StreamFormat,
                                   kAudioUnitScope_Input,
                                   0,
                                   &inputFormat,
                                   UInt32(MemoryLayout<AudioStreamBasicDescription>.size))
        if err != noErr {
            let messages = "Error changing stream format: \(err.description)"
            os_log(.error, log: .audio, "%@", messages)
        }
        
        inFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32,
                                 sampleRate: sampleRate,
                                 channels: 2,
                                 interleaved: false)
        outFormat = AVAudioFormat(commonFormat: .pcmFormatInt16,
                                  sampleRate: SAMPLE_RATE,
                                  channels: 1,
                                  interleaved: false)
        if let AUConvert = AUConvert {
            AUConvert.reset()
        }
        AUConvert = AVAudioConverter(from: inFormat, to: outFormat)
        
        err = AudioUnitInitialize(AUInput!)
        if err != noErr {
            let messages = "Error initializing AU: \(err.description)"
            os_log(.error, log: .audio, "%@", messages)
        }
    }

    private func createFile() {
        // MARK: create Record Output File
        let docURL = mpWAVURL
        destFileName = formatterFile.string(from: Date())
        let filePath = docURL.path.appending("/\(destFileName).m4a")
        destFileURL = URL(fileURLWithPath: filePath)
        
        var fileFormat = AudioStreamBasicDescription(
            mSampleRate: sampleRate,
            mFormatID: kAudioFormatMPEG4AAC,
            mFormatFlags: 1,
            mBytesPerPacket: 0 ,
            mFramesPerPacket: 1024,
            mBytesPerFrame: 0 ,
            mChannelsPerFrame: 2,
            mBitsPerChannel: 0,
            mReserved: 0)
        
        // output data file
        var err = ExtAudioFileCreateWithURL(destFileURL! as CFURL,
                                        kAudioFileM4AType,
                                        &fileFormat,
                                        nil,
                                        AudioFileFlags.eraseFile.rawValue,
                                        &destFile)
        if err != noErr {
            let messages = "Error creating dest file: \(err.description)"
            os_log(.error, log: .audio, "%@", messages)
        }
        
        var codec = kAppleSoftwareAudioCodecManufacturer
        err = ExtAudioFileSetProperty(destFile!,
                                      kExtAudioFileProperty_CodecManufacturer,
                                      UInt32(MemoryLayout<UInt32>.size),
                                      &codec)
        if err != noErr {
            let messages = "Error setting up dest file codec: \(err.description)"
            os_log(.error, log: .audio, "%@", messages)
        }
        err = ExtAudioFileSetProperty(destFile!,
                                      kExtAudioFileProperty_ClientDataFormat,
                                      UInt32(MemoryLayout<AudioStreamBasicDescription>.size),
                                      &inputFormat)
        if err != noErr {
            let messages = "Error while setting up dest file format: \(err.description)"
            os_log(.error, log: .audio, "%@", messages)
        }
        
        err = ExtAudioFileWriteAsync(destFile!, 0, nil)
        if err != noErr {
            let messages = "Error while setting up dest file: \(err.description)"
            os_log(.error, log: .audio, "%@", messages)
        }
    }
    
    func start_audio_unit(){
        isRunning = true
        
        _TPCircularBufferInit(&rBufferIn, 16 * UInt32(bytesPerBufferIn), MemoryLayout<TPCircularBuffer>.size)
        _TPCircularBufferInit(&rBufferOut, 16 * UInt32(bytesPerBufferIn), MemoryLayout<TPCircularBuffer>.size)
        
#if DEBUG
        if isRecording {
            createFile()
        }
#endif
        // 5. 오디오 유닛 시작
        AudioOutputUnitStart(AUInput!)
        
        timer = BackgroundTimer(with: Double(samples) / sampleRate) { [weak self] in
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
        var err = noErr
        
        err = AudioOutputUnitStop(AUInput)
        
        if err != noErr {
            let messages = "Error stopping AU: \(err.description)"
            os_log(.error, log: .audio, "%@", messages)
        } else {
            os_log(.info, log: .audio, "AU Stopped")
        }
        
        pthread_mutex_lock(&mutexTPC)
        TPCircularBufferCleanup(&rBufferIn)
        TPCircularBufferCleanup(&rBufferOut)
        pthread_mutex_unlock(&mutexTPC)

#if DEBUG
        if isRecording {
            finishRecording()
        }
#endif
    }
    
    func finishRecording() {
        var err : OSStatus = noErr
        if let destFile = destFile {
            pthread_mutex_lock(&mutexFile)
            err = ExtAudioFileDispose(destFile)
            pthread_mutex_unlock(&mutexFile)
            if err != noErr {
                let messages = "Error disposing existing file \(destFileName): \(err.description)"
                os_log(.error, log: .audio, "%@", messages)
            } else {
                let messages = "Successfully disposed existing file \(destFileName)"
                os_log(.info, log: .audio, "%@", messages)
            }
        }
        destFileName = ""
    }
  
}



