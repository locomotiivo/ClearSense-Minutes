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
@objc protocol AUConversionCallbackDelegate {
    func convertCallback(converter: AudioConverterRef,
                         inNumberDataPackets: UnsafeMutablePointer<UInt32>,
                         ioData: UnsafeMutablePointer<AudioBufferList>,
                         outDataPacketDescription: UnsafeMutablePointer<UnsafeMutablePointer<AudioStreamPacketDescription>?>?,
                         inUserData: UnsafeMutableRawPointer?) -> OSStatus
}

private let AURecordCallback: AURenderCallback = {(inRefCon,
                                                   ioActionFlags,
                                                   inTimeStamp,
                                                   inBusNumber,
                                                   inNumberFrames,
                                                   ioData)
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

private let AUConvertCallback: AudioConverterComplexInputDataProc = {(inAudioConverter,
                                                                      ioNumberDataPackets,
                                                                      ioData,
                                                                      outDataPacketDescription,
                                                                      inUserData)
    -> OSStatus in
    let buffer = inUserData!.assumingMemoryBound(to: AUConvertBuffer.self)
    let maxPackets = buffer.pointee.srcBufferSize / buffer.pointee.srcSizePerPacket // 512 / 4 = 128
    if ioNumberDataPackets.pointee > maxPackets {
        ioNumberDataPackets.pointee = maxPackets
    }
    
    let ioDataPtr = UnsafeMutableAudioBufferListPointer(ioData)
//    ioDataPtr[0].mData = UnsafeMutableRawPointer(buffer.pointee.data)           // srcBuffer
    ioDataPtr[0].mData = UnsafeMutableRawPointer(buffer.pointee.dataChar)           // srcBuffer
    ioDataPtr[0].mDataByteSize = buffer.pointee.srcBufferSize                   // 512
    ioDataPtr[0].mNumberChannels = buffer.pointee.inputFormat.mChannelsPerFrame // 1
    
    return noErr
}

private struct AUConvertBuffer {
    var inputFormat: AudioStreamBasicDescription!
    var srcSizePerPacket: UInt32 = 0
    var data: UnsafeMutablePointer<Float32>?
    var dataChar: UnsafeMutablePointer<CChar>?
    var srcBufferSize: UInt32 = 0
}

class AudioEngineManager : AURecordCallbackDelegate {

    static let shared = AudioEngineManager()
    private var mutex: pthread_mutex_t = pthread_mutex_t()
    private var TPCmutex: pthread_mutex_t = pthread_mutex_t()

    private let SAMPLE_RATE : Double = 16000
    private let CHANNEL_MONO = 1

    var sampleRate : Double = 48000
    private let samples : Int = 128
    private let bytesPerBufferIn = 128 * MemoryLayout<Float32>.size
    private let bytesPerBufferOut = 128 * MemoryLayout<Int16>.size
    private let packetSizeIn = MemoryLayout<Float32>.size
    private let packetSizeOut = MemoryLayout<UInt16>.size

    private var AUInput: AudioUnit!
    private var converter: AudioConverterRef? = nil
    let session = AVAudioSession.sharedInstance()
    
    private var rBufferIn : TPCircularBuffer
    private var srcFormat: AudioStreamBasicDescription!
    private var srcSizePerPacket: UInt32 = 0

    var isRunning : Bool = false
    var timer : BackgroundTimer!
    
    private var turnOn: UInt32 = 1
    private var turnOff: UInt32 = 0;
    private let kInputBus: AudioUnitElement = 1
    private let kOutputBus: AudioUnitElement = 0
    
    private let ASBDsize : UInt32 = UInt32(MemoryLayout<AudioStreamBasicDescription>.size)
    private var inputFormat : AudioStreamBasicDescription!
    private var outputFormat : AudioStreamBasicDescription!
    
    private var destFile: ExtAudioFileRef?
    private var destFileName = ""
    private var destFileURL: URL?
    
    static var iterConvert: UInt64 = 0
    static var iterRecord: UInt64 = 0
    
    init() {
        rBufferIn = TPCircularBuffer()
        setupAudioSession()
        setupAudioUnit()
        pthread_mutex_init(&mutex, nil)
        pthread_mutex_init(&TPCmutex, nil)
    }
    
    // MARK: setup Session
    private func setupAudioSession() {
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
    
    // MARK: AURecordCallback
    @objc func recordCallback(inRefCon: UnsafeMutableRawPointer,
                              ioActionFlags: UnsafeMutablePointer<AudioUnitRenderActionFlags>,
                              inTimeStamp: UnsafePointer<AudioTimeStamp>,
                              inBusNumber: UInt32,
                              inNumberFrames: UInt32,
                              ioData: UnsafeMutablePointer<AudioBufferList>?) -> OSStatus {
        
        var err: OSStatus = noErr
        let bufferList = AudioBufferList.allocate(maximumBuffers: 2)
        for i in 0..<2 {
            bufferList[i] = AudioBuffer(
                mNumberChannels: 1
                , mDataByteSize: UInt32(bytesPerBufferIn)
                , mData: nil
            )
        }
        defer {
            bufferList.unsafeMutablePointer.deallocate()
        }
        
        err = AudioUnitRender(
            AUInput!,
            ioActionFlags,
            inTimeStamp,
            1,
            inNumberFrames,
            bufferList.unsafeMutablePointer
        )
        
        if err == noErr {
            AudioEngineManager.iterRecord += 1
            
//            let neededBytes = bufferList[0].mDataByteSize
            let neededBytes = 2 * bufferList[0].mDataByteSize
            var availableBytes: UInt32 = 0
            let dstBuffer = TPCircularBufferHead(&rBufferIn, &availableBytes)
            if (availableBytes >= neededBytes) {
//                let data = UnsafeMutableRawPointer(bufferList[0].mData)
//                if let dptr = data {
//                    let arr = dptr.assumingMemoryBound(to: Float32.self)
//                    memcpy((dstBuffer!), arr, Int(bufferList[0].mDataByteSize))
//                    TPCircularBufferProduce(&rBufferIn, UInt32(neededBytes))
//                }
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
                if 0 == pthread_mutex_trylock(&mutex) {
                    err = ExtAudioFileWriteAsync(destFile!, inNumberFrames, bufferList.unsafePointer)
                    if err != noErr {
                        let messages = "Error while writing to file: \(err.description)"
                        os_log(.error, log: .audio, "%@", messages)
                    }
                    pthread_mutex_unlock(&mutex)
                }
#endif
            }
            return err
        } else {
            let messages = "Error Rendering Audio Unit, \(err.description)"
            os_log(.error, log: .audio, "%@", messages)
        }

        return err
    }
    
    //MARK: Polling Thread
    @objc private func processData() {
        let neededBytesIn : UInt32 = 2 * UInt32(bytesPerBufferIn)
//        let neededBytesIn : UInt32 = UInt32(bytesPerBufferIn)
        var availableBytes : UInt32 = 0
        let srcBuffer = TPCircularBufferTail(&rBufferIn, &availableBytes)
        guard let ptrIn = srcBuffer?.assumingMemoryBound(to: Float32.self) else { return }
        
        if (availableBytes >= neededBytesIn) {
            AudioEngineManager.iterConvert += 1
            
            if 0 == pthread_mutex_trylock(&TPCmutex) {
                
//                // create source buffer
//                var bufferIn = AUConvertBuffer()
//                bufferIn.srcBufferSize = UInt32(bytesPerBufferIn)
//                bufferIn.inputFormat = inputFormat
//                bufferIn.srcSizePerPacket = inputFormat.mBytesPerPacket
//                bufferIn.dataChar = UnsafeMutablePointer<CChar>.allocate(capacity: bytesPerBufferIn) // 512 * 1
//                bufferIn.data = UnsafeMutablePointer<Float32>.allocate(capacity: samples) // 128 * 4
//                defer { bufferIn.data?.deallocate() }
//                defer { bufferIn.dataChar?.deallocate() }
//                memcpy(bufferIn.dataChar, ptrIn, bytesPerBufferIn)
//                
//                print("INPUT: ", terminator: " ")
//                for i in 0..<samples {
//                    bufferIn.data?[i] = ptrIn[i]
//                    print(ptrIn[i], terminator: " ")
//                }
//                print("\n")
//                
//                // create output buffer
//                let sizeOut : UInt32 = UInt32(samples * 2)
//                let dataOut = UnsafeMutablePointer<Int16>.allocate(capacity: samples * 2) // 128 * 2 * 2
//                defer { dataOut.deallocate() }
//                let dataOutChar = UnsafeMutablePointer<CChar>.allocate(capacity: bytesPerBufferIn) // 512 * 1
//                defer { dataOutChar.deallocate() }
//                
//                var bufferOut = AudioBufferList()
//                bufferOut.mNumberBuffers = 1
//                bufferOut.mBuffers.mNumberChannels = 1
//                bufferOut.mBuffers.mDataByteSize = UInt32(sizeOut)
//                //            bufferOut.mBuffers.mData = UnsafeMutableRawPointer(dataOut)
//                bufferOut.mBuffers.mData = UnsafeMutableRawPointer(dataOutChar)
//                
//                // Convert PCM Buffer
//                var ioOutputDataPackets: UInt32 = UInt32(bytesPerBufferIn) / outputFormat.mBytesPerPacket // 128 / 1
//                var err = noErr
//            err = AudioConverterFillComplexBuffer(
//                converter!,
//                AUConvertCallback,
//                &bufferIn,
//                &ioOutputDataPackets,
//                &bufferOut,
//                nil
//            )
//
//            if err != noErr {
//                let message = "ERROR CONVERSION: \(err.description)"
//                os_log(.error, log: .system, "%@", message)
//            }
//
//            let inNumBytes = bufferOut.mBuffers.mDataByteSize
//            bufferOut.mBuffers.mData?.withMemoryRebound(to: Int16.self, capacity: Int(ioOutputDataPackets)) { ptr in
//                let arr = UnsafeBufferPointer(start: ptr, count: Int(ioOutputDataPackets))
//                if STTconn.isConnected {
//                    STTconn.send(buffer: arr)
//                }
//            }
                
                TPCircularBufferConsume(&rBufferIn, neededBytesIn)
            }
            pthread_mutex_unlock(&TPCmutex)
        }
    }

    // MARK: Setup AudioUnit
    private func setupAudioUnit() {
        var err : OSStatus = noErr
        
        // MARK: find and create new audiocomponent
        var componentDesc = AudioComponentDescription(
            componentType: kAudioUnitType_Output,
            componentSubType: kAudioUnitSubType_RemoteIO,
            componentManufacturer: kAudioUnitManufacturer_Apple,
            componentFlags: 0,
            componentFlagsMask: 0
        )
        
        let IOComponent = AudioComponentFindNext(nil, &(componentDesc))!
        err = AudioComponentInstanceNew(IOComponent, &AUInput)
        
        // MARK: enable Input
        err = AudioUnitSetProperty(AUInput!,
                                   kAudioOutputUnitProperty_EnableIO,
                                   kAudioUnitScope_Input,
                                   kInputBus,
                                   &turnOn,
                                   UInt32(MemoryLayout<UInt32>.size))
        
        err = AudioUnitSetProperty(AUInput!,
                                   kAudioOutputUnitProperty_EnableIO,
                                   kAudioUnitScope_Output,
                                   kOutputBus,
                                   &turnOff,
//                                   &turnOn,
                                   UInt32(MemoryLayout<UInt32>.size))
        
        // MARK: Apply Input format to Converter's Input
        inputFormat = AudioStreamBasicDescription(
            mSampleRate: sampleRate,
            mFormatID: kAudioFormatLinearPCM,
            mFormatFlags: kAudioFormatFlagsNativeFloatPacked | kLinearPCMFormatFlagIsNonInterleaved,
            mBytesPerPacket: UInt32(packetSizeIn), // 4
            mFramesPerPacket: 1,
            mBytesPerFrame: UInt32(packetSizeIn), // 4
            mChannelsPerFrame: UInt32(CHANNEL_MONO), // 1
            mBitsPerChannel: UInt32(8 * packetSizeIn), // 32
            mReserved: 0)
        
        err = AudioUnitSetProperty(AUInput!,
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
            mFormatFlags: kAudioFormatFlagIsPacked | kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsNonInterleaved,
            mBytesPerPacket: UInt32(packetSizeOut), // 2
            mFramesPerPacket: 1,
            mBytesPerFrame: UInt32(packetSizeOut), // 2
            mChannelsPerFrame: UInt32(CHANNEL_MONO), // 1
            mBitsPerChannel: UInt32(8 * packetSizeOut), // 16
            mReserved: 0)
 
        err = AudioConverterNew(&inputFormat,
                               &outputFormat,
                               &converter)
        if err != noErr {
            let messages = "Error setting up Converter: \(err.description)"
            os_log(.error, log: .audio, "%@", messages)
        }
        
        // MARK: Setup Converter related variables
        srcFormat = inputFormat
        srcSizePerPacket = inputFormat.mBytesPerPacket

        // MARK: Disable auto allocation
        err = AudioUnitSetProperty(AUInput!,
                                   kAudioUnitProperty_ShouldAllocateBuffer,
                                   kAudioUnitScope_Output,
                                   kOutputBus,
                                   &turnOff,
                                   UInt32(MemoryLayout<UInt32>.size))
        if err != noErr {
            let messages = "Error disabling allocation: \(err.description)"
            os_log(.error, log: .audio, "%@", messages)
        }
        
        // MARK: Set Recording callback
        var recordCallbackStruct = AURenderCallbackStruct(
            inputProc: AURecordCallback,
            inputProcRefCon: Unmanaged.passUnretained(self).toOpaque()
        )
        err = AudioUnitSetProperty(AUInput!,
                                   kAudioOutputUnitProperty_SetInputCallback,
                                   kAudioUnitScope_Global,
                                   1,
                                   &recordCallbackStruct,
                                   UInt32(MemoryLayout<AURenderCallbackStruct>.size))
        
        if err != noErr {
            let messages = "Error setting up AURecordCallback: \(err.description)"
            os_log(.error, log: .audio, "%@", messages)
        }
        
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
            mSampleRate: sr,
            mFormatID: kAudioFormatLinearPCM,
            mFormatFlags: kAudioFormatFlagsNativeFloatPacked | kLinearPCMFormatFlagIsNonInterleaved,
            mBytesPerPacket: UInt32(packetSizeIn),
            mFramesPerPacket: 1,
            mBytesPerFrame: UInt32(packetSizeIn),
            mChannelsPerFrame: UInt32(CHANNEL_MONO),
            mBitsPerChannel: UInt32(8 * packetSizeIn),
            mReserved: 0)
        
        err = AudioUnitSetProperty(AUInput!,
                                   kAudioUnitProperty_StreamFormat,
                                   kAudioUnitScope_Input,
                                   kOutputBus,
                                   &inputFormat,
                                   ASBDsize)
        if err != noErr {
            let messages = "Error changing incoming AUDescription: \(err.description)"
            os_log(.error, log: .audio, "%@", messages)
        }
        
        if let converter = converter {
            err = AudioConverterReset(converter)
        }
        err = AudioConverterNew(&inputFormat,
                               &outputFormat,
                               &converter)
        if err != noErr {
            let messages = "Error setting up Converter: \(err.description)"
            os_log(.error, log: .audio, "%@", messages)
        }
        
        // MARK: Setup Converter related variables
        srcFormat = inputFormat
        srcSizePerPacket = inputFormat.mBytesPerPacket
        
        err = AudioUnitInitialize(AUInput!)
        if err != noErr {
            let messages = "Error initializing AU: \(err.description)"
            os_log(.error, log: .audio, "%@", messages)
        }
    }
    
    func start_audio_unit(){
        AudioEngineManager.iterConvert = 0
        AudioEngineManager.iterRecord = 0
        
        isRunning = true
        
        let size = 3 * bytesPerBufferIn
        _TPCircularBufferInit(&rBufferIn, UInt32(size), MemoryLayout<TPCircularBuffer>.size)
        
#if DEBUG
        createFile()
#endif
        // 5. 오디오 유닛 시작
        AudioOutputUnitStart(AUInput!)
        
        timer = BackgroundTimer(with: Double(samples) / sampleRate) { [weak self] in
            guard let `self` = self else {
                return
            }
            if self.isRunning {
                self.processData()
            } else {
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
        
        pthread_mutex_lock(&TPCmutex)
        TPCircularBufferCleanup(&rBufferIn)
        pthread_mutex_unlock(&TPCmutex)
#if DEBUG
        if let destFile = destFile {
            pthread_mutex_lock(&mutex)
            err = ExtAudioFileDispose(destFile)
            pthread_mutex_unlock(&mutex)
            if err != noErr {
                let messages = "Error disposing existing file \(destFileName): \(err.description)"
                os_log(.error, log: .audio, "%@", messages)
            } else {
                let messages = "Successfully disposed existing file \(destFileName)"
                os_log(.info, log: .audio, "%@", messages)
            }
        }
        destFileName = ""
#endif
    }
    
    private func createFile() {
        // MARK: create Record Output File
        let docURL = mpWAVURL
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
        let dateStr = dateFormatter.string(from: Date())
        destFileName = "\(dateStr)"
        
        let filePath = docURL.path.appending("/\(destFileName).m4a")
        destFileURL = URL(fileURLWithPath: filePath)
        
        var dstFormat = AudioStreamBasicDescription(
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
                                        &dstFormat,
                                        nil,
                                        AudioFileFlags.eraseFile.rawValue,
                                        &destFile)
        if err != noErr {
            let messages = "Error creating dest file: \(err.description)"
            os_log(.error, log: .audio, "%@", messages)
        }
        
//        var codec = kAppleHardwareAudioCodecManufacturer
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
}



