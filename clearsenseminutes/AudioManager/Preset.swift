//
//  Preset.swift
//  clearsenseminutes
//
//  Created by HWANJUN YU on 11/20/24.
//

import Foundation

struct Preset: Codable, Equatable {
    var name: String
    let device: String
    let volumeBase: Double
    let leftVolume: [Int: Double]
    let rightVolume: [Int: Double]
    let standard: String
    var leftRightEqual: Bool
    var leftDb: [Int: Double]
    var rightDb: [Int: Double]
    
    // JSON 키와 프로퍼티 매핑
    private enum CodingKeys: String, CodingKey {
        case name
        case device
        case volumeBase = "volume_base"
        case leftVolume = "left_volume"
        case rightVolume = "right_volume"
        case standard
        case leftRightEqual = "left_right_equal"
        case leftDb = "left_dB"
        case rightDb = "right_dB"
    }
    
    // JSON 디코딩 로직
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        device = try container.decode(String.self, forKey: .device)
        volumeBase = try container.decode(Double.self, forKey: .volumeBase)
        leftVolume = try container.decodeStringKeyedDictionary(forKey: .leftVolume)
        rightVolume = try container.decodeStringKeyedDictionary(forKey: .rightVolume)
        standard = try container.decode(String.self, forKey: .standard)
        leftRightEqual = try container.decode(Bool.self, forKey: .leftRightEqual)
        leftDb = try container.decodeStringKeyedDictionary(forKey: .leftDb)
        rightDb = try container.decodeStringKeyedDictionary(forKey: .rightDb)
    }
    
    // 기본값 제공을 위한 생성자
    // TODO: 기본 플랫한 프리셋 데이터 입력
    init(
        name: String = "\("PRESET".localized())1",
        device: String = "Default Device",
        volumeBase: Double = 0.5,
        leftVolume: [Int: Double] = [500: 0.0, 1000: 0.0, 3000: 0.0],
        rightVolume: [Int: Double] = [500: 0.0, 1000: 0.0, 3000: 0.0],
        standard: String = "ISO226:2003",
        leftRightEqual: Bool = true,
        leftDb: [Int: Double] = [125: 0.0, 250: 0.0, 500: 0.0, 1000: 0.0, 2000: 0.0, 3000: 0.0, 4000: 0.0, 8000: 0.0],
        rightDb: [Int: Double] = [125: 0.0, 250: 0.0, 500: 0.0, 1000: 0.0, 2000: 0.0, 3000: 0.0, 4000: 0.0, 8000: 0.0]
    ) {
        self.name = name
        self.device = device
        self.volumeBase = volumeBase
        self.leftVolume = leftVolume
        self.rightVolume = rightVolume
        self.standard = standard
        self.leftRightEqual = leftRightEqual
        self.leftDb = leftDb
        self.rightDb = rightDb
    }
}
