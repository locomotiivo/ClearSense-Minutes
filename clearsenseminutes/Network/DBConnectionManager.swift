//
//  DBConnectionManager.swift
//  clearsenseminutes
//
//  Created by KooBH on 12/4/24.
//

import Foundation
import UIKit
import SwiftyJSON

enum DBRequestError: Error {
    case invalidURL(String)
    case missingData(String)
    case AccessDenied(String)
    case ErrorCode(String)
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
    
    func DBRequest(_ mode: String, _ rawFlag : Bool, _ url: String, _ param: Dictionary<String, Any>, completionBlock: @escaping (Bool, Int, String, Data?) -> Void) throws {
        guard let URL = URL(string: (!rawFlag ? DBURL : "") + url) else {
            throw DBRequestError.invalidURL("Invalid URL: \(param["URL"] ?? "")")
        }
        let paramData = JSON(param)
        
        var request = URLRequest.init(url: URL)
        request.httpMethod = mode
        request.addValue("application/json", forHTTPHeaderField:  "Content-Type")
        request.addValue("application/json", forHTTPHeaderField:  "Accept")
        
        if !param.isEmpty {
            request.httpBody = try JSONSerialization.data(withJSONObject: param)
        }
        
        let requestTask = URLSession.shared.dataTask(with: request) {
            (data: Data?, response: URLResponse?, error: Error?) in
            if let error = error {
                DispatchQueue.main.async {
                    completionBlock(false, -1, "Error processing request for \(url) : \(error.localizedDescription)", data)
                }
            }
            if let response = response as? HTTPURLResponse {
                if response.statusCode == 200 {
                    DispatchQueue.main.async {
                        completionBlock(true, response.statusCode, "", data)
                    }
                } else {
                    DispatchQueue.main.async {
                        completionBlock(false, response.statusCode, "Error processing request for \(url): \(response.statusCode)", data)
                    }
                }
            }
        }
        requestTask.resume()
    }
}
