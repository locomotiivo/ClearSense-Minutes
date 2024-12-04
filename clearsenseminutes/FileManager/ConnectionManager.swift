//
//  FilesArray.swift
//  clearsenseminutes
//
//  Created by KooBH on 7/17/24.
//

import Foundation
import SwiftyJSON
import OSLog

class ConnectionManager: NSObject {
    
    enum RequestError: Error {
        case invalidURL
        case missingData
    }
    
    static let shared = ConnectionManager()
    
    private var DBURL : String
    private var SSTURL: String
    var onReceiveClosure : ((String?, Data?) -> ())?
    weak var delegate : URLSessionWebSocketDelegate?
    
    private override init() {
        if let url = Bundle.main.infoDictionary?["DBURL"] as? String {
            DBURL = url
        } else {
            DBURL = ""
        }
        
        if let url = Bundle.main.infoDictionary?["SSTURL"] as? String {
            SSTURL = url
        }
        else {
            SSTURL = ""
        }
    }
    
    func DATAREQUEST(_ mode: String, _ param: Dictionary<String, Any>) async throws -> JSON {
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
    
    private var webSocketTask: URLSessionWebSocketTask {
        didSet {
            oldValue.cancel(with: .goingAway, reason: nil)
        }
    }
    private var timer: Timer
    
    func openWebSocket() throws {
        
    }
    
    private func startPing() {
        
    }
    
    private func ping() {
        
    }
}

extension ConnectionManager : URLSessionWebSocketDelegate {
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol ptc: String?) {
        self.delegate?.urlSession?(session, webSocketTask: webSocketTask, didOpenWithProtocol: ptc)
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        self.delegate?.urlSession?(session, webSocketTask: webSocketTask, didCloseWith: closeCode, reason: reason)
    }
}
