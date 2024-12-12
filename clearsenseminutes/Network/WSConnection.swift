import UIKit
import Starscream
import OSLog
import AVFoundation

enum WebSocketError: Error {
    case invalidURL
}

public protocol WebSocketInterface {
    var listener: ((WebSocketEventType) -> Void)? { get set }
    var socket: WebSocket? { get }
    
    func connect(mode: String) throws
    func disconnect()
    func request(data: Data)
    func request(string: String)
}

public enum WebSocketEventType {
    case connect(socket: WebSocketClient)
    case disconnect(socket: WebSocketClient, code: String, reason: UInt16)
    case error(socket: WebSocketClient, error: Error?)
    case message(socket: WebSocketClient, text: String)
    case data(socket: WebSocketClient, data: Data)
}

class WS: WebSocketInterface {
    
    var listener: ((WebSocketEventType) -> Void)?
    var socket: WebSocket?
    private var urlstr: String!
    
    public init() { }
    deinit {
        disconnect()
    }
    
    func connect(mode: String) throws {
        if mode == "STT" {
            urlstr = "ws://horseymask.com/v1/audio/transcriptions?model=$Systran/faster-whisper-small&language=ko&response_format=json&temperature=0&vad_filter=true"
        }
        else {
            urlstr = "ws://ec2-3-35-131-163.ap-northeast-2.compute.amazonaws.com:3001/ws"
        }
        guard let url = URL(string: urlstr) else {
            return
        }
        var request = URLRequest(url: url)
        request.timeoutInterval = 10
        socket = WebSocket(request: request)
        
        request.addValue("APP", forHTTPHeaderField: "Origin")
        request.timeoutInterval = 10
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        socket = WebSocket(request: request)
        socket?.delegate = self
        socket?.connect()
    }
    
    func disconnect() {
        socket?.disconnect()
        socket?.delegate = nil
    }
    
    func request(string: String) {
        if let socket {
            socket.write(string: string)
        } else {
            os_log("socket is not connected")
        }
    }
    
    func request(data: Data) {
        if let socket {
            socket.write(data: data)
        } else {
            os_log("socket is not connected")
        }
    }
    
    func request(pcmBuffer: AVAudioPCMBuffer) {
        guard let buffer = pcmBuffer.int16ChannelData else {
            let message = "WebSocket: No pcm data to send"
            os_log(.error, log: .system, "%@", message)
            return
        }

        let frameLength = Int(pcmBuffer.frameLength)
        let data = Data(bytes: buffer[0], count: frameLength * MemoryLayout<Int16>.size)
        request(data: data)
    }
}

extension WS: WebSocketDelegate {
    func didReceive(event: Starscream.WebSocketEvent, client: any Starscream.WebSocketClient) {
        switch event {
        case .connected(let headers):
            listener?(.connect(socket: client))
        case .disconnected(let code, let reason):
            listener?(.disconnect(socket: client, code: code, reason: reason))
        case .binary(let data):
            listener?(.data(socket: client, data: data))
        case .text(let text):
            listener?(.message(socket: client, text: text))
        case .pong(_):
            break
        case .ping(_):
            break
        case .error(let error):
            listener?(.error(socket: client, error: error))
        case .viabilityChanged(_):
            break
        case .reconnectSuggested(_):
            break
        case .cancelled:
            listener?(.disconnect(socket: client, code: "Cancelled", reason: 0))
        case .peerClosed:
            listener?(.disconnect(socket: client, code: "Peer Closed", reason: 0))
        }
    }
}
