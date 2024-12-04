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

enum RequestError: Error {
    case invalidURL
    case missingData
}

class SSTConnectionManager: NSObject {
    static let shared = SSTConnectionManager()

    private var SSTURL: String

    private var task: URLSessionWebSocketTask {
        didSet {
            oldValue.cancel(with: .goingAway, reason: nil)
        }
    }
    private let urlSession: URLSession
    private let apiKey: String = ""
    private let audioSampleRate: Int = 16000
    weak var delegate : URLSessionWebSocketDelegate?

    var text : String = ""

    private override init() {
        if let url = Bundle.main.infoDictionary?["SSTURL"] as? String {
            SSTURL = url
        }
        else {
            SSTURL = ""
        }
        text = ""
        urlSession = URLSession(configuration: .default, delegate: self, delegateQueue: OperationQueue())
    }
    
    func connect() {
        guard let url = SSTURL else {
			throw RequestError.invalidURL
		}
        
        var request = URLRequest(url: url)
        request.addValue("\(apiKey)", forHTTPHeaderField: "Authorization")

        task = urlSession.webSocketTask(with: request)
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
                switch message {
                case .string(let text):
                    DispatchQueue.main.async {
                        self?.listenHandler(text)
                    }
                case .data(let data):
                    print("WebSocket: [DATA] \(data)")
                }
                default:
                    break
            }
            self?.listen()
        }
    }

    private func listenHandler(_ text: String) {
        guard let data = text.data(using: .utf8),
              let json = JSON(data),
        else {
            let message = "WebSocket: Error parsing STT data"
            os_log(.error, log: .system, "%@", message)
            return
        }

        guard let msgType = json["message_type"].string,
              let text = json["text"].string,
              let confidence = json["confidence"].double
              let words = json["words"].object as? [[String: Any]]
        else {
            let message = "WebSocket: Error parsing STT data"
            os_log(.error, log: .system, "%@", message)
            return
        }

        let word = words.compactMap { wordDict -> Word? in
            guard let start = wordDict["start"].int,
                  let end = wordDict["end"].int,
                  let wordConfidence = wordDict["confidence"].double,
                  let wordText = wordDict["text"].string
            else {
                return nil
            }
            return Word(start: start, end: end, confidence: confidence, text: wordText)
        }

        let transcript = Transcript(msgType: msgType, text: text, confidency: confidency, words: word)
        self.text = transcript.text
    }

    func send(pcmBuffer: AVAudioPCMBuffer) {
        guard let buffer = pcmBuffer.int16ChannelData?[0] else {
            let message = "WebSocket: No pcm data to send"
            os_log(.error, log: .system, "%@", message)
            return
        }
        let frameLength = Int(pcmBuffer.frameLength)
        let data = Data(bytes: audioBuffer, count: frameLength * 2) // 16-bit samples
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

class DBConnectionManager {
    static let shared = DBConnectionManager()
    
    private var DBURL : String
    
    init() {
        if let url = Bundle.main.infoDictionary?["DBURL"] as? String {
            DBURL = url
        } else {
            DBURL = ""
        }
    }
    
    func DBRequest(_ mode: String, _ param: Dictionary<String, Any>) async throws -> JSON {
        guard let url = param["URL"] as? String,
              let URL = URL(string: DBURL + url) else {
            throw RequestError.invalidURL
        }
        let paramData = JSON(param)
        
        var request = URLRequest.init(url: URL)
        request.httpMethod = mode
        request.addValue("application/json", forHTTPHeaderField:  "Content-Type")
        request.setValue(String(paramData.count), forHTTPHeaderField:  "Content-Length")
        
        guard let (data, response) = try? await URLSession.shared.data(for: request) else {
            throw RequestError.invalidURL
        }
        
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw RequestError.invalidURL}
        
        return JSON(data)
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
