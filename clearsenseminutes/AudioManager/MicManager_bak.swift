import Foundation
import UIKit
import AVFoundation
import AudioToolbox
import CTPCircularBuffer
import OSLog

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
                        inBufNumber: UInt32,
                        inNumberFrames: UInt32,
                        ioData: UnsafeMutablePointer<AudioBufferList>?) -> OSStatus
}

@objc protocol AURenderCallbackDelegate {
    func renderCallback(inRefCon: UnsafeMutableRawPointer,
                        ioActionFlags: UnsafeMutablePointer<AudioUnitRenderActionFlags>,
                        inTimeStamp: UnsafePointer<AudioTimeStamp>,
                        inBufNumber: UInt32,
                        inNumberFrames: UInt32,
                        ioData: UnsafeMutablePointer<AudioBufferList>?) -> OSStatus
}

private let AUrecordCallback: AURenderCallback = {(inRefCon,
                                                 ioActionFlags/*: UnsafeMutablePointer<AudioUnitRenderActionFlags>*/,
                                                 inTimeStamp/*: UnsafePointer<AudioTimeStamp>*/,
                                                 inBufNumber/*: UInt32*/,
                                                 inNumberFrames/*: UInt32*/,
                                                 ioData/*: UnsafeMutablePointer<AudioBufferList>*/)
    -> OSStatus
    in
    let delegate = unsafeBitCast(inRefCon, to: AURecordCallbackDelegate.self)
    let result = delegate.recordCallback(inRefCon: inRefCon,
                                         ioActionFlags: ioActionFlags,
                                         inTimeStamp: inTimeStamp,
                                         inBufNumber: inBufNumber,
                                         inNumberFrames: inNumberFrames,
                                         ioData: ioData)
    return result
}

private let AUrenderCallback: AURenderCallback = {(inRefCon,
                                                 ioActionFlags/*: UnsafeMutablePointer<AudioUnitRenderActionFlags>*/,
                                                 inTimeStamp/*: UnsafePointer<AudioTimeStamp>*/,
                                                 inBufNumber/*: UInt32*/,
                                                 inNumberFrames/*: UInt32*/,
                                                 ioData/*: UnsafeMutablePointer<AudioBufferList>*/)
    -> OSStatus
    in
    let delegate = unsafeBitCast(inRefCon, to: AURenderCallbackDelegate.self)
    let result = delegate.renderCallback(inRefCon: inRefCon,
                                         ioActionFlags: ioActionFlags,
                                         inTimeStamp: inTimeStamp,
                                         inBufNumber: inBufNumber,
                                         inNumberFrames: inNumberFrames,
                                         ioData: ioData)
    return result
}


//@objc(AudioEngineManager)
class AudioEngineManager: AURecordCallbackDelegate, AURenderCallbackDelegate {
    
    static let shared = AudioEngineManager()
    
    let sr_in : Int = 48000
    let sr_out : Int = 48000
    var dur_in : Double = 0.002
    var file_name : String = ""
    
    // Eqaulizer
    let n_gain_band = 8+1
    var gain_eq : [Double] = []
    var optEQ: Bool = false
    
    // IO
    var processing_frame = 128
    var audioUnit: AudioUnit!
    var cppProcessing: CWrapper?
    let session = AVAudioSession.sharedInstance()
    
    // input stream buffer
    var startIdx: Int = 0
    var bufferIndex: Int = 0 // 현재 버퍼 인덱스
    
    // Output
    var numFramesToRead = 128 * 3 * 2 // 링 버퍼의 크기만큼 데이터를 읽습니다.
    var numFrames = 128 * 3
    var _bytesPerBuffer = 128 * 4

    var inputData : [Float] = []
    var outputData : [Float] = []
    
    var rBufferIn : TPCircularBuffer = TPCircularBuffer()
    var rBufferOut : TPCircularBuffer = TPCircularBuffer()
    var rBufferInBytes = 0
    var rBufferOutBytes = 0
    // stores setting for playback and recording on remote io unit
    var remoteIODesc : AudioComponentDescription?;
    // stores playback format
    var fileFormat : AudioStreamBasicDescription?;
    
    var isRunning : Bool = false
    var isBypassing : Bool = false
    var isAGCEnabled : Bool = false
    var isRecording : Bool = false
    var isSpatial : Bool = false
    var toggleFlag : Bool = false
    var sendFlag : Bool = false
    var timer : BackgroundTimer?
    
    var destFile: ExtAudioFileRef?
    var destFileName: String?
    var destFileURL: URL?
    
    var rawFile: ExtAudioFileRef?
    var rawFileName: String?
    var rawFileURL: URL?
    
    let semaphore = DispatchSemaphore(value: 1)
    
//    override init() {
//        super.init()
    init() {
        let n_hop = 128

        processing_frame = n_hop
        
        // 3 for resampling factor
        numFramesToRead = n_hop * 3 * 2
        numFrames = n_hop * 3
        
        _bytesPerBuffer = n_hop * 4
        
        inputData = [Float](repeating: 0.0, count: numFramesToRead)
        outputData = [Float](repeating: 0.0, count: numFrames)
        gain_eq = [Double](repeating : 0.0, count: n_gain_band)
        startIdx    = 0
        bufferIndex = 0 // 현재 버퍼 인덱스
                
        if n_hop == 32{
            file_name = "/mpANC_128.onnx"
            dur_in = 32 / Double(sr_in)
        }
        else if n_hop == 64{
            file_name = "/mpANC_256.onnx"
            dur_in = 64 / Double(sr_in)
        }
        else if n_hop == 128{
            //self.file_name = "/mpANC_512.onnx"
            file_name = "/mpANC_1.onnx"
            dur_in = 128 / Double(sr_in)
        }
       
        let path_model = String(Bundle.main.bundlePath) + "\(file_name)"
        String(path_model).withCString { (cCharPtr: UnsafePointer<CChar>) in
            cppProcessing = CWrapper(
                hop: Int32(processing_frame),
                path : UnsafeMutablePointer(mutating: cCharPtr),
                sr_in : Int32(sr_in),
                sr_out: Int32(sr_out)
            )
        }
        
        setupAudioSession()
        setupAudioUnit()
        
        for i in 0..<9 {
            let eqValStr = UserDefaults.standard.string(forKey: "eq_\(i)") ?? "0"
            let eqVal = (Double(eqValStr) ?? 0.0) / 24 + 0.5
            gain_eq[i] = eqVal
        }
        optEQ = true
        SetEQ()
    }
    
    private func setupAudioSession() {
        // MARK: setup Session
        do {
            try session.setCategory(.playAndRecord,
                                    mode: .videoRecording,
                                    options: [.allowBluetooth, .allowBluetoothA2DP])
            try session.setPreferredSampleRate(Double(sr_in))
            try session.setPreferredIOBufferDuration(dur_in)
            
//            let route = session.currentRoute
//            if route.outputs.count > 0 {
//                try route.outputs.forEach {
//                    if $0.portType == .headphones || $0.portType == .bluetoothA2DP {
            try session.overrideOutputAudioPort(.none)
//                    } else {
//                        try session.overrideOutputAudioPort(.speaker)
//                    }
//                }
//            } else {
//                try session.overrideOutputAudioPort(.speaker)
//            }
            
            guard let inputs = session.availableInputs,
                  let mic = inputs.first(where: {$0.portType == .builtInMic})
            else {
                throw RuntimeError("The device must have a built-in microphone!")
            }
            try session.setPreferredInput(mic)
            try session.setPreferredInputOrientation(.portrait)

            guard let builtinMicPort = session.preferredInput,
                  let dataSource = builtinMicPort.dataSources,
                  let newDataSource = dataSource.first(where: { $0.orientation == .front }),
                  let supportedPolarPatterns = newDataSource.supportedPolarPatterns
            else {
                throw RuntimeError("Unexpected Error Setting Directivity!")
            }
            
            if supportedPolarPatterns.contains(.stereo) {
                try newDataSource.setPreferredPolarPattern(.cardioid)
                try newDataSource.setPreferredPolarPattern(.stereo)
            }
            try builtinMicPort.setPreferredDataSource(newDataSource)
            
            try session.setActive(true, options: [.notifyOthersOnDeactivation])
        } catch {
            let messages = "Error setting up Session, \(error.localizedDescription)"
            os_log(.error, log: .audio, "%@", messages)
        }
    }
    
    func recordCallback(inRefCon: UnsafeMutableRawPointer,
                        ioActionFlags: UnsafeMutablePointer<AudioUnitRenderActionFlags>,
                        inTimeStamp: UnsafePointer<AudioTimeStamp>,
                        inBufNumber: UInt32,
                        inNumberFrames: UInt32,
                        ioData: UnsafeMutablePointer<AudioBufferList>?) -> OSStatus {
        var err: OSStatus = noErr
        
        if !isRunning {
            return err
        }
        
        var bufferList = AudioBufferList(mNumberBuffers: 2,
                                         mBuffers: AudioBuffer(
                                             mNumberChannels: UInt32(1),
                                             mDataByteSize: UInt32(_bytesPerBuffer),
                                             mData: nil))
        
        err = AudioUnitRender(
            audioUnit!,
            ioActionFlags,
            inTimeStamp,
            1,
            inNumberFrames,
            &bufferList
        )
        
        if err == noErr {
            //                if audioObj.isRecording {
            //                    err = ExtAudioFileWrite(audioObj.rawFile!, inNumberFrames, bufferList.unsafeMutablePointer)
            //                    if err != noErr {
            //                        let messages = "Error while writing to raw file: \(err.description)"
            //                        os_log(.error, log: .audio, "%@", messages)
            //                    }
            //                }
            
            let blPtr = UnsafeMutableAudioBufferListPointer(&bufferList)
            let mBufferL : AudioBuffer = blPtr[0]
            let mBufferR : AudioBuffer = blPtr[1]
            let dataL = UnsafeMutableRawPointer(mBufferL.mData)
            let dataR = UnsafeMutableRawPointer(mBufferR.mData)
            
            if let dptrL = dataL, let dptrR = dataR {
                let arrL = dptrL.assumingMemoryBound(to: Float32.self)
                let arrR = dptrR.assumingMemoryBound(to: Float32.self)
                
                TPCircularBufferProduceBytes(&rBufferIn, arrL, UInt32(_bytesPerBuffer))
                TPCircularBufferProduceBytes(&rBufferIn, arrR, UInt32(_bytesPerBuffer))
                rBufferInBytes += 2 * _bytesPerBuffer
            }
        } else {
            let message = "\(err.description)"
            os_log(.error, log: .audio, "%@", message)
        }
        
        return err
    }
    
    func renderCallback(inRefCon: UnsafeMutableRawPointer,
                        ioActionFlags: UnsafeMutablePointer<AudioUnitRenderActionFlags>,
                        inTimeStamp: UnsafePointer<AudioTimeStamp>,
                        inBufNumber: UInt32,
                        inNumberFrames: UInt32,
                        ioData: UnsafeMutablePointer<AudioBufferList>?) -> OSStatus {
        var err: OSStatus = noErr
        
        if !isRunning {
            return err
        }
        
        let abl = UnsafeMutableAudioBufferListPointer(ioData)!
        let frames = Int(abl[0].mDataByteSize) / 4
        
        var availableBytesOut : UInt32 = 0
        let srcBufferOut = TPCircularBufferTail(&rBufferOut, &availableBytesOut)
        
        let ptrOut = srcBufferOut?.assumingMemoryBound(to: Float.self)
        if (availableBytesOut >= _bytesPerBuffer) {
            for i in 0..<Int(ioData!.pointee.mNumberBuffers) {
                let audioBuffer: AudioBuffer = abl[i]
                let audioData = audioBuffer.mData?.assumingMemoryBound(to: Float.self)
                for j in 0..<frames {
                    audioData?[j] = ptrOut![j]
                }
            }
            TPCircularBufferConsume(&rBufferOut, UInt32(_bytesPerBuffer))
        } else {
            TPCircularBufferClear(&rBufferOut)
            for i in 0..<Int(ioData!.pointee.mNumberBuffers) {
                let audioBuffer: AudioBuffer = abl[i]
                let audioData = audioBuffer.mData?.assumingMemoryBound(to: Float.self)
                for j in 0..<frames {
                    audioData?[j] = 0.0
                }
            }
        }
//            if audioObj.isRecording {
//                err = ExtAudioFileWrite(audioObj.destFile!, inNumberFrames, ioData!)
//                if err != noErr {
//                    let messages = "Error while writing to file: \(err.description)"
//                    os_log(.error, log: .audio, "%@", messages)
//                }
//            }
        
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
            mSampleRate: 48000.0,
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
        
        // 128 * 3 * 2
        var frameCount: UInt32 = UInt32(numFrames) * 2
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
            let messages = "Error setting up AUrecordCallback: \(err.description)"
            os_log(.error, log: .audio, "%@", messages)
        }
        
        // MARK: Set Rendering callback
        var renderCallbackStruct = AURenderCallbackStruct(
            inputProc: AUrenderCallback,
            inputProcRefCon: Unmanaged.passUnretained(self).toOpaque()
        )
        err = AudioUnitSetProperty(audioUnit!,
                                   kAudioUnitProperty_SetRenderCallback,
                                   kAudioUnitScope_Input,
                                   0,
                                   &renderCallbackStruct,
                                   UInt32(MemoryLayout<AURenderCallbackStruct>.size))
        
        if err != noErr {
            let messages = "Error setting up AUrenderCallback: \(err.description)"
            os_log(.error, log: .audio, "%@", messages)
        }
        
        AudioUnitInitialize(audioUnit!)
    }
    
    // Pass gain levels to the C++ instance
    func SetEQ(){
        cppProcessing?.seteq(withGains: &gain_eq, optEQ_: optEQ)
    }
    
    @objc private func processData() {
        var neededBytes : UInt32 = 3 * 2 * UInt32(_bytesPerBuffer)
        var availableBytes : UInt32 = 0
        let srcBufferIn = TPCircularBufferTail(&rBufferIn, &availableBytes)
        guard let ptrIn = srcBufferIn?.assumingMemoryBound(to: Float.self) else {return}
        
        if (availableBytes >= neededBytes) {

            var ch1_Idx = 0
            var ch2_Idx = 1
            
            for i in 0..<numFramesToRead {
                let sample = ptrIn[bufferIndex]
                if (i % (processing_frame * 2) < processing_frame){
                    inputData[ch1_Idx] = sample;
                    ch1_Idx += 2
                }
                else if (i % (self.processing_frame * 2) >=  self.processing_frame){
                    inputData[ch2_Idx] = sample;
                    ch2_Idx += 2
                }
                
                self.bufferIndex = (self.bufferIndex + 1) % self.numFramesToRead
            }
            semaphore.signal()
            semaphore.wait()
            
            // Processss
//            if (self.isBypassing){
//                cppProcessing?.process(withInputBuffer: &inputData, outputBuffer: &outputData)
//            }else{
                for i in 0..<numFrames{
                    outputData[i] = inputData[2*i]
                }
//            }
            semaphore.signal()
            semaphore.wait()

            neededBytes = 3 * UInt32(_bytesPerBuffer)
            availableBytes = 0
            
            let dstBuffer = TPCircularBufferHead(&rBufferOut, &availableBytes)
            
            if (availableBytes >= neededBytes) {
                memcpy((dstBuffer!), &outputData, 3 * _bytesPerBuffer)
                TPCircularBufferProduce(&rBufferOut, UInt32(neededBytes))
            }
            semaphore.signal()
            semaphore.wait()
            
            TPCircularBufferConsume(&rBufferIn, neededBytes)
            semaphore.signal()
            semaphore.wait()
            
        }
    }
    
    private func createFile() {
        // MARK: create Record Output File
        let docURL = mpWAVURL
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
        let dateStr = dateFormatter.string(from: Date())
        destFileName = "\(dateStr)"
        
        let filePath = docURL.path.appending("/\(destFileName!).m4a")
        let rawPath = docURL.path.appending("/\(destFileName!)_R.m4a");
        rawFileURL = URL(fileURLWithPath: rawPath)
        destFileURL = URL(fileURLWithPath: filePath)

        var dstFormat = AudioStreamBasicDescription(
            mSampleRate: 16000,
            mFormatID: kAudioFormatMPEG4AAC,
            mFormatFlags: UInt32(MPEG4ObjectID.AAC_LC.rawValue),
            mBytesPerPacket: 0 ,
            mFramesPerPacket: 1024,
            mBytesPerFrame: 0 ,
            mChannelsPerFrame: 2,
            mBitsPerChannel: 0,
            mReserved: 0)
        
        // output data file
        var err = ExtAudioFileCreateWithURL(destFileURL! as CFURL,
                                        kAudioFileM4AType,
                                        &dstFormat,
                                        nil,
                                        AudioFileFlags.eraseFile.rawValue,
                                        &destFile)
        if err != noErr {
            let messages = "Error creating dest file: \(err.description)"
            os_log(.error, log: .audio, "%@", messages)
        }
        
        var codec = kAppleHardwareAudioCodecManufacturer
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
                                      &fileFormat)
        if err != noErr {
            let messages = "Error while setting up dest file format: \(err.description)"
            os_log(.error, log: .audio, "%@", messages)
        }
        
        err = ExtAudioFileCreateWithURL(rawFileURL! as CFURL,
                                        kAudioFileM4AType,
                                        &dstFormat,
                                        nil,
                                        AudioFileFlags.eraseFile.rawValue,
                                        &rawFile)
        if err != noErr {
            let messages = "Error creating raw file: \(err.description)"
            os_log(.error, log: .audio, "%@", messages)
        }
        
        var codec2 = kAppleHardwareAudioCodecManufacturer
        err = ExtAudioFileSetProperty(rawFile!,
                                      kExtAudioFileProperty_CodecManufacturer,
                                      UInt32(MemoryLayout<UInt32>.size),
                                      &codec2)
        if err != noErr {
            let messages = "Error setting up raw file codec: \(err.description)"
            os_log(.error, log: .audio, "%@", messages)
        }
        err = ExtAudioFileSetProperty(rawFile!,
                                      kExtAudioFileProperty_ClientDataFormat,
                                      UInt32(MemoryLayout<AudioStreamBasicDescription>.size),
                                      &fileFormat)
        if err != noErr {
            let messages = "Error setting up raw file format: \(err.description)"
            os_log(.error, log: .audio, "%@", messages)
        }
    }
    
    func start_audio_unit(){
        isRunning = true
        startIdx = 0
        rBufferInBytes = 0
        rBufferOutBytes = 0

        _TPCircularBufferInit(&rBufferIn, 5 * UInt32(_bytesPerBuffer), MemoryLayout<TPCircularBuffer>.size)
        _TPCircularBufferInit(&rBufferOut, 5 * UInt32(_bytesPerBuffer), MemoryLayout<TPCircularBuffer>.size)
        
//        if isRecording {
//            createFile()
//        }
        
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
        rBufferInBytes = 0
        rBufferOutBytes = 0
        
        var status = AudioOutputUnitStop(audioUnit)
        //        status = AudioUnitUninitialize(audioUnit)
        if status != noErr {
            let messages = "Error stopping AU: \(status.description)"
            os_log(.error, log: .audio, "%@", messages)
        } else {
            os_log(.error, log: .audio, "AU Stopped")
        }
        
//        if isRecording {
//            if let destFile = destFile {
//                ExtAudioFileDispose(destFile)
//            }
//            if let rawFile = rawFile {
//                ExtAudioFileDispose(rawFile)
//            }
//        }
        
        TPCircularBufferCleanup(&rBufferIn)
        TPCircularBufferCleanup(&rBufferOut)
    }
    
    func startRecording() {
        createFile()
    }
}



