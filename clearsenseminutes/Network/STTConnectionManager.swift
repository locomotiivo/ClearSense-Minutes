//
//  SSTConnectionManager.swift
//  clearsenseminutes
//
//  Created by KooBH on 7/17/24.
//

import AVFoundation
import Foundation
import SwiftyJSON
import OSLog

@objc protocol STTDelegate: URLSessionWebSocketDelegate, URLSessionDelegate {
    func STTConnect()
    func STTCallback(text: String)
    func STTCallback(data: Data)
    func STTError(message: String)
}

enum STTRequestError: Error {
    case invalidURL
}

class STTConnectionManager: NSObject, URLSessionWebSocketDelegate, URLSessionDelegate {
    static let shared = STTConnectionManager()
    weak var STTDelegate : STTDelegate?
    private var socket: URLSessionWebSocketTask?
    private var STTURL: URL!
    
    private(set) var isConnected = false
    
    override init() {
        if let urlstr = Bundle.main.infoDictionary?["STTURL"] as? String,
           let url = URL(string: urlstr) {
            STTURL = url
        }
        else {
            os_log(.error, log: .system, "STTConnectionManager: INVALID STT URL")
        }
        super.init()
    }
    
    func setDelegate(_ delegate : STTDelegate?) {
        STTDelegate = delegate
    }
    
    func connect() throws {
        let configuration = URLSessionConfiguration.default
        let urlSession = URLSession(configuration: configuration, delegate: self, delegateQueue: OperationQueue())
        var urlRequest = URLRequest(url: STTURL)
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        socket = urlSession.webSocketTask(with: urlRequest)
        socket?.resume()
        listen()
    }
    
    private func listen() {
        socket?.receive { [weak self] result in
            switch result {
            case .failure(let error):
                let message = "WebSocket: Error in STT connection: \(error.localizedDescription)"
                os_log(.error, log: .system, "%@", message)
                break
                
            case .success(let msg):
                switch msg {
                case .string(let text):
                    self?.STTDelegate?.STTCallback(text: text)
                case .data(let data):
                    self?.STTDelegate?.STTCallback(data: data)
                @unknown default:
                    print("Huh?")
                    break
                }
                self?.listen()
            }
        }
    }
    
    func send(pcmBuffer: AVAudioPCMBuffer) {
        guard let buffer = pcmBuffer.int16ChannelData else {
            let message = "WebSocket: No pcm data to send"
            os_log(.error, log: .system, "%@", message)
            return
        }

        let frameLength = Int(pcmBuffer.frameLength)
        let data = Data(bytes: buffer[0], count: frameLength * MemoryLayout<Int16>.size)
        if isConnected {
            socket?.send(.data(data)) { error in
                self.errHandler(error)
            }
        }
    }
    
    func send(arr: [CChar]) {
        let binary = arr.map { String(format: "%c", $0) }.joined()
        let data = Data(binary.utf8)
        let message = URLSessionWebSocketTask.Message.data(data)
        
        if isConnected {
            socket?.send(message) { error in
                self.errHandler(error)
            }
        }
    }
    
    func send(buffer: UnsafeBufferPointer<Int16>) {
        let message = URLSessionWebSocketTask.Message.data(Data(buffer: buffer))
        if isConnected {
            socket?.send(message) { error in
                self.errHandler(error)
            }
        }
    }
    
    func errHandler(_ error: Error?) {
        if let error = error as? NSError {
            if error.code == 57 || error.code == 60 || error.code == 54 {
                isConnected = false
                self.STTDelegate?.STTError(message: error.localizedDescription)
            } else {
                self.STTDelegate?.STTError(message: error.localizedDescription)
            }
            disconnect()
        }
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        isConnected = true
        self.STTDelegate?.STTConnect()
    }

    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        isConnected = false
    }

    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        completionHandler(.useCredential, URLCredential(trust: challenge.protectionSpace.serverTrust!))
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        self.errHandler(error)
    }

    func disconnect() {
        socket?.cancel(with: .goingAway, reason: nil)
        isConnected = false
        os_log(.info, log: .system, "Disconnected from STT Server")
    }
}
