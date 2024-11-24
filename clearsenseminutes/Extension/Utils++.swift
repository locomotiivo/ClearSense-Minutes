//
//  Utils++.swift
//  clearsenseminutes
//
//  Created by HYUNJUN SHIN on 9/2/24.
//

import Foundation
import UIKit
import OSLog

public class Utils {
    internal static func getAppVersion() -> String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String
    }
    
    internal static func getBuildVersion() -> String {
        return Bundle.main.infoDictionary?["CFBundleVersion"] as! String
    }
    
    // 앱 최초 실행 여부 확인
    internal static func isFirstLaunch() -> Bool {
        return !UserDefaults.standard.bool(forKey: "onBoarding")
    }
    
    // 초 단위로 대기 후 앱 종료
    internal static func terminateAppGracefullyAfter(second: Double) {
        DispatchQueue.main.asyncAfter(deadline: .now() + second) {
            UIApplication.shared.perform(#selector(NSXPCConnection.suspend))
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                exit(1) // Exit Failure
            }
        }
    }
    
    // 파일 이름으로 주소 반환
    internal static func getFilePath(_ name: String) -> String {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        return "\(paths[0])/mpWAV/\(name)"
    }
    
    // Hz문자열 정리하여 반환
    internal static func convertHz(_ value: Double) -> String { convertHz(Int(value)) }
    internal static func convertHz(_ value: Int) -> String {        
        let isKilo = Double(value) >= 1000
        let divisor = isKilo ? 1000.0 : 1.0
        let calcValue = ceil(Double(value) / divisor * 10) / 10
        
        let suffix = isKilo ? "K" : ""
        
        return floor(calcValue) == calcValue ? "\(Int(calcValue))\(suffix)" : "\(calcValue)\(suffix)"
    }
    
    // SE 단말인지 여부
    internal static func isSeDevice() -> Bool {
        return UIScreen.main.bounds.size.height <= 667
    }
}


//let version = Utils.getAppVersion()
//1.0.0
//let versionProject2 = Utils.getBuildVersion()
//2024.08.12.2


// https://j2q043etx4.execute-api.ap-northeast-2.amazonaws.com/mpwave/notice
// date : 갱신 날짜
// text : 공지 사항 렌더링

// https://j2q043etx4.execute-api.ap-northeast-2.amazonaws.com/mpwave/compatibility?type=ios&version=0.0.0

//     if (versionStr != "") {
//     minium 1.0.0
//     Simple version 가져오기
//     서버에 던져주기
//     is_minimum을 기반으로 분기 처리
//     false -> itunes gogo
//     true -> 환영
