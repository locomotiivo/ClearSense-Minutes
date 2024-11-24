//
//  CSVolumeSlider.swift
//  clearsenseminutes
//
//  Created by HWANJUN YU on 11/6/24.
//

import UIKit

class CSVolumeSlider: UISlider {
    
    // thumb 트래킹 시작 범위 확장
    override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        return true
    }
}
