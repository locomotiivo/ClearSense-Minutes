//
//  StepBadge.swift
//  clearsenseminutes
//
//  Created by HWANJUN YU on 10/28/24.
//

import UIKit

class StepBadge: UIView {
    let innerLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 50, height: 32))
    
    convenience init(step: Int = 1) {
        self.init(frame: CGRect(x: 0, y: 0, width: 50, height: 32))
        
        innerLabel.text = "\(step)/4"
        innerLabel.font = UIFont(name: "PretendardGOVVariable-Medium", size: 18)
        innerLabel.textColor = .white
        innerLabel.textAlignment = .center
        innerLabel.backgroundColor = UIColor(named: "btn_color")
        innerLabel.layer.cornerRadius = 16
        innerLabel.clipsToBounds = true
        self.addSubview(innerLabel)
    }
    
    func setStep(step: Int) {
        innerLabel.text = "\(step)/4"
    }
}
