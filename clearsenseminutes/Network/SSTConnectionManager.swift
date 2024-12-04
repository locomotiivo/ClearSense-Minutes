//
//  FilesArray.swift
//  clearsenseminutes
//
//  Created by KooBH on 7/17/24.
//

import AVFoundation
import Foundation
import SwiftyJSON
import OSLog

struct Word {
    var start: Int
    var end: Int
    var confidence: Double
    var text: String
}

struct Transcript {
    var msgType : String
    var text : String
    var confidence: Double
    var words: [Word]
}

enum STTRequestError: Error {
    case invalidURL
}

class SSTConnectionManager: NSObject {
    static let shared = SSTConnectionManager()
    
    private var SSTURL: String = ""
    
    private var task: URLSessionWebSocketTask? {
        didSet {
            oldValue?.cancel(with: .goingAway, reason: nil)
        }
    }
    private var urlSession: URLSession!
    private let apiKey: String = ""
    private let audioSampleRate: Int = 16000
    weak var delegate : URLSessionWebSocketDelegate?
    
    var text : String = ""
    
    private override init() {
        super.init()
        if let url = Bundle.main.infoDictionary?["SSTURL"] as? String {
            SSTURL = url
        }
        else {
            SSTURL = ""
        }
        text = ""
        urlSession = URLSession(configuration: .default, delegate: self, delegateQueue: OperationQueue())
    }
    
    func connect() throws {
        guard let url = URL(string: SSTURL) else {
            throw STTRequestError.invalidURL
        }
        
        text = ""
        var request = URLRequest(url: url)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
//        request.addValue("\(apiKey)", forHTTPHeaderField: "Authorization")
        
        task = urlSession?.webSocketTask(with: request)
        task?.resume()
        listen()
    }
    
    private func listen() {
        task?.receive { [weak self] result in
            switch result {
            case .failure(let error):
                let message = "WebSocket: Error in STT connection: \(error.localizedDescription)"
                os_log(.error, log: .system, "%@", message)
                
            case .success(let msg):
                switch msg {
                case .string(let text):
                    DispatchQueue.main.async {
                        print("WebSocket: [DATA] \(text)")
                        self?.listenHandler(text)
                    }
                case .data(let data):
                    print("WebSocket: [DATA] \(data)")
                @unknown default:
                    break
                }
            }
            self?.listen()
        }
    }
    
    func listenHandler(_ text: String) {
        guard let data = text.data(using: .utf8)
        else {
            let message = "WebSocket: Error parsing STT data"
            os_log(.error, log: .system, "%@", message)
            return
        }
        
        let json = JSON(data)
        guard let msgType = json["message_type"].string,
              let text = json["text"].string,
              let confidence = json["confidence"].double,
              let wordDict = json["words"].object as? [[String: Any]]
        else {
            let message = "WebSocket: Error parsing STT data"
            os_log(.error, log: .system, "%@", message)
            return
        }
        
        let word = wordDict.compactMap { wordDict -> Word? in
            guard let start = wordDict["start"] as? Int,
                  let end = wordDict["end"] as? Int,
                  let wordConfidence = wordDict["confidence"] as? Double,
                  let wordText = wordDict["text"] as? String
            else {
                return nil
            }
            return Word(start: start, end: end, confidence: confidence, text: wordText)
        }
        
        let transcript = Transcript(msgType: msgType, text: text, confidence: confidence, words: word)
        self.text = transcript.text
    }
    
    func send(pcmBuffer: AVAudioPCMBuffer) {
        guard let buffer = pcmBuffer.int16ChannelData?[0] else {
            let message = "WebSocket: No pcm data to send"
            os_log(.error, log: .system, "%@", message)
            return
        }
        let frameLength = Int(pcmBuffer.frameLength)
        let data = Data(bytes: buffer, count: frameLength * 2) // 16-bit samples
        let base64EncodedString = data.base64EncodedString()
        let message = URLSessionWebSocketTask.Message.string("{\"audio_data\": \"\(base64EncodedString)\"}")
        task?.send(message) { error in
            if let error = error {
                let message = "WebSocket: Error sending buffer - \(error.localizedDescription)"
                os_log(.error, log: .system, "%@", message)
            }
        }
    }
    
    func disconnect() {
        let terminateMessage = URLSessionWebSocketTask.Message.string("{\"terminate_session\": true}")
        task?.send(terminateMessage) { [weak self] error in
            if let error = error {
                let message = "WebSocket: Error closing connection - \(error.localizedDescription)"
                os_log(.error, log: .system, "%@", message)
            }
            self?.task?.cancel(with: .normalClosure, reason: nil)
        }
    }
}

extension SSTConnectionManager : URLSessionWebSocketDelegate {
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol ptc: String?) {
        self.delegate?.urlSession?(session, webSocketTask: webSocketTask, didOpenWithProtocol: ptc)
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        self.delegate?.urlSession?(session, webSocketTask: webSocketTask, didCloseWith: closeCode, reason: reason)
    }
}
