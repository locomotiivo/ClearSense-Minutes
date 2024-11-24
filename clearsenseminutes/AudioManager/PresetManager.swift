//
//  PresetManager.swift
//  clearsenseminutes
//
//  Created by HWANJUN YU on 11/19/24.
//

import Foundation
import OSLog

class PresetManager {
    static let shared = PresetManager()
    
    private let keyPresetList = ["preset1", "preset2", "preset3"] // 슬롯은 3개
    
    var presetList: [Preset] = []       // 로컬에서 불러온 프리셋 목록
    var selectedPreset: Preset?         // 선택된 프리셋
    
    private init() {
        loadPresetList()
    }
    
    // MARK: - 프리셋 관리
    // 로컬의 프리셋 목록 불러오기
    func loadPresetList() {
        let idx = presetList.firstIndex(where: { $0 == selectedPreset }) // 현재 선택된 프리셋 인덱스
        
        presetList.removeAll()
        
        for key in keyPresetList {
            if let presetStr = UserDefaults.standard.string(forKey: key),
               let jsonData = presetStr.data(using: .utf8) { // JSON 문자열을 Data로 변환
                do {
                    // JSON 디코딩
                    let preset = try JSONDecoder().decode(Preset.self, from: jsonData)
                    presetList.append(preset)
                } catch {
                    os_log(.error, "Failed to decode Preset: \(error)")
                }
            }
        }
        
        selectedPreset = (idx != nil && presetList.count > idx!) ? presetList[idx!] : presetList.first
    }
    
    // 플랫한 기본 프리셋 생성
    func creatBasicPreset() {
        guard presetList.count < 3 else { return }
        
        var newPreset = Preset()
        var num = 1
        for preset in presetList {
            if preset.name == newPreset.name {
                num += 1
                newPreset.name = "\("PRESET".localized())\(num)"
            }
        }
        
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let jsonData = try encoder.encode(newPreset)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                UserDefaults.standard.set(jsonString, forKey: keyPresetList[presetList.count])
            }
        } catch {
            os_log(.error, "Failed to encode Preset: \(error)")
        }
        
        loadPresetList()
        selectedPreset = presetList.last
    }
    
    // 현재 선택된 프리셋 이름 변경
    func changeName(_ newName: String) {
        guard selectedPreset != nil else { return }
        guard let idx = presetList.firstIndex(where: { $0 == selectedPreset }) else { return }
        
        selectedPreset!.name = newName
        presetList[idx].name = newName
        
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let jsonData = try encoder.encode(selectedPreset!)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                UserDefaults.standard.set(jsonString, forKey: keyPresetList[idx])
            }
        } catch {
            os_log(.error, "Failed to encode Preset: \(error)")
        }
        
        loadPresetList()
    }
    
    // 현재 선택된 프리셋 삭제
    func removePreset() {
        // 현재 목록에서 선택된 프리셋 삭제
        if let selectedPreset = selectedPreset, let idx = presetList.firstIndex(where: { $0 == selectedPreset }) {
            presetList.remove(at: idx)
        }
        
        // 로컬의 프리셋 초기화
        for key in keyPresetList {
            UserDefaults.standard.removeObject(forKey: key)
        }
        
        // 로컬에 새롭게 세팅
        for (index, preset) in presetList.enumerated() {
            do {
                let encoder = JSONEncoder()
                encoder.outputFormatting = .prettyPrinted
                let jsonData = try encoder.encode(preset)
                if let jsonString = String(data: jsonData, encoding: .utf8) {
                    UserDefaults.standard.set(jsonString, forKey: keyPresetList[index])
                }
            } catch {
                os_log(.error, "Failed to encode Preset: \(error)")
            }
        }
        
        loadPresetList()
    }
    
    // MARK: - 차트 관련
    // 현재 선택된 프리셋의 차트 데이터 가져오기
    func getChartData() -> (left: [LineChartData], right: [LineChartData]) {
        guard let selectedPreset else { return ([], []) }
        
        // left_dB와 right_dB를 [LineChartData]로 변환하는 함수
        func convertToLineChartData(from dictionary: [Int: Double]) -> [LineChartData] {
            var resultData = dictionary.map { (key, value) in
                LineChartData(label: key, value: value)
            }
            resultData.sort { Double($0.label) < Double($1.label) }
            return resultData
        }
        
        // left_dB와 right_dB 데이터를 변환하여 세팅
        let leftResult = convertToLineChartData(from: selectedPreset.leftDb)
        let rightResult = convertToLineChartData(from: selectedPreset.rightDb)
        
        return (left: leftResult, right: rightResult)
    }
    
    // 현재 프리셋 데이터 로컬에 저장
    func savePresetToLocal(left: [LineChartData]? = nil, right: [LineChartData]? = nil) {
        guard var selectedPreset else { return }
        guard let idx = presetList.firstIndex(where: { $0 == selectedPreset }) else { return }
        
        if let left {
            selectedPreset.leftDb = Dictionary(uniqueKeysWithValues: left.map { ($0.label, $0.value) })
        }
        if let right {
            selectedPreset.rightDb = Dictionary(uniqueKeysWithValues: right.map { ($0.label, $0.value) })
        }
        
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let jsonData = try encoder.encode(selectedPreset)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                UserDefaults.standard.set(jsonString, forKey: keyPresetList[idx])
            }
        } catch {
            os_log(.error, "Failed to encode Preset: \(error)")
        }
        
        loadPresetList()
    }
    
    // 양쪽 같게 데이터 로컬에 저장
    func saveIsEqualToLocal(isEqual: Bool) {
        guard var selectedPreset else { return }
        guard let idx = presetList.firstIndex(where: { $0 == selectedPreset }) else { return }
        
        selectedPreset.leftRightEqual = isEqual
        
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let jsonData = try encoder.encode(selectedPreset)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                UserDefaults.standard.set(jsonString, forKey: keyPresetList[idx])
            }
        } catch {
            os_log(.error, "Failed to encode Preset: \(error)")
        }
        
        loadPresetList()
    }
}
