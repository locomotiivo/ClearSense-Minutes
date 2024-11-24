//
//  NetworkManager.swift
//  clearsenseminutes
//
//  Created by HYUNJUN SHIN on 9/2/24.
//

import Foundation
import OSLog

public class NetworkManager {
    
    var needTogoUpdate: Bool
    var notiDate: Int
    var notiText: String
    
    let baseURL: String = "https://j2q043etx4.execute-api.ap-northeast-2.amazonaws.com/mpwave/"
    let routeTypeCheckingVersion: String = "compatibility?type=ios&version="
    let routeTypeNotification: String = "notice"
    
    init(needTogoUpdate: Bool = false, notiDate: Int = 0, notiText: String = "") {
        self.needTogoUpdate = needTogoUpdate
        self.notiDate = notiDate
        self.notiText = notiText
    }
    
    internal func performCheckingVersionCall(version: String, completion: @escaping (Bool) -> Void) {
        
        
        guard let url = URL(string: baseURL + routeTypeCheckingVersion + version) else {
            os_log(.error, log: .system, "Invalid URL")
            completion(true)
            return
        }
        
        let session = URLSession(configuration: .default)
        let task = session.dataTask(with: url) { data, response, error in
            
            if let error = error {
                let message = "Error during session.dataTask(with: \(url): \(error.localizedDescription)"
                os_log(.error, log: .system, "%@", message)
                completion(true)
                return
            }
            
            guard let JSONdata = data else {
                os_log(.error, log: .system, "No data received")
                completion(true)
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let decodedData = try decoder.decode(VersionInfo.self, from: JSONdata)
                let needTogoUpdate = !(decodedData.is_minimum ?? true)
                completion(needTogoUpdate)
                
            } catch {
                let message = "Error during decoder.decode(): \(error.localizedDescription)"
                os_log(.error, log: .system, "%@", message)
                completion(true)
            }
        }
        
        task.resume()
    }
    
    
    internal func performNotificationCall(completion: @escaping (Int, String) -> Void) {
        
        
        guard let url = URL(string: baseURL + routeTypeNotification) else {
            os_log(.error, log: .system, "Invalid URL")
            completion(0, "")
            return
        }
        
        let session = URLSession(configuration: .default)
        let task = session.dataTask(with: url) { data, response, error in
            
            if let error = error {
                let message = "Error during session.dataTask(with: \(url): \(error.localizedDescription)"
                os_log(.error, log: .system, "%@", message)
                completion(0, "")
                return
            }
            
            guard let JSONdata = data else {
                os_log(.error, log: .system, "No data received")
                completion(0, "")
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let decodedData = try decoder.decode(NotiInfo.self, from: JSONdata)
                let notiDate = decodedData.date ?? 0
                let notiText = decodedData.text ?? ""
                
                completion(notiDate, notiText)
                
            } catch {
                let message = "Error during decoder.decode(): \(error.localizedDescription)"
                os_log(.error, log: .system, "%@", message)
                print("Decoding error: \(error)")
                completion(0, "")
            }
        }
        
        task.resume()
    }
}
