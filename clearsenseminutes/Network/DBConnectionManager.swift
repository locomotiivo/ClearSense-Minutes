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
    case invalidURL
    case missingData
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
            throw DBRequestError.invalidURL
        }
        let paramData = JSON(param)
        
        var request = URLRequest.init(url: URL)
        request.httpMethod = mode
        request.addValue("application/json", forHTTPHeaderField:  "Content-Type")
        request.setValue(String(paramData.count), forHTTPHeaderField:  "Content-Length")
        
        guard let (data, response) = try? await URLSession.shared.data(for: request) else {
            throw DBRequestError.invalidURL
        }
        
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw DBRequestError.invalidURL}
        
        return JSON(data)
    }
}
