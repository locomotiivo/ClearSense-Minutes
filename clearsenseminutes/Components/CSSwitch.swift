//
//  CSSwitch.swift
//  clearsenseminutes
//
//  Created by HWANJUN YU on 10/28/24.
//

import UIKit

protocol CSSwitchDelegate {
    func onChange(isOn: Bool)
}

class CSSwitch: UIButton {
    typealias SwitchColor = (bar: UIColor, circle: UIColor)

    private var barView: UIView!
    private var circleView: UIView!

    var isOn: Bool = false

    // on 상태의 스위치 색상
    var onColor: SwitchColor = (UIColor(named: "btn_color") ?? .blue, .white) {
        didSet {
            if isOn {
                self.barView.backgroundColor = self.onColor.bar
                self.circleView.backgroundColor = self.onColor.circle
            }
        }
    }

    // off 상태의 스위치 색상
    var offColor: SwitchColor = (.lightGray, .white) {
        didSet {
            if isOn == false {
                self.barView.backgroundColor = self.offColor.bar
                self.circleView.backgroundColor = self.offColor.circle
            }
        }
    }

    
    var animationDuration: TimeInterval = 0.25 // 스위치가 이동하는 애니메이션 시간
    var barViewTopBottomMargin: CGFloat = 3.5 // barView의 상, 하단 마진 값

    var delegate: CSSwitchDelegate?

    override init(frame: CGRect) {
        super.init(frame: frame)
        buttonInit(frame: frame)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        buttonInit(frame: frame)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        setOn(!isOn)
    }

    // 초기화
    private func buttonInit(frame: CGRect) {
        let barViewHeight = frame.height - (barViewTopBottomMargin * 2)

        barView = UIView(frame: CGRect(x: 0, y: barViewTopBottomMargin, width: frame.width, height: barViewHeight))
        barView.backgroundColor = self.offColor.bar
        barView.layer.masksToBounds = true
        barView.layer.cornerRadius = barViewHeight / 2

        self.addSubview(barView)

        circleView = UIView(frame: CGRect(x: 0, y: 0, width: frame.height, height: frame.height))
        circleView.backgroundColor = self.offColor.circle
        circleView.layer.masksToBounds = true
        circleView.layer.cornerRadius = frame.height / 2

        self.addSubview(circleView)
    }

    // 값 세팅
    func setOn(_ newOn: Bool) {
        isOn = newOn
        
        var circleCenter: CGFloat = 0
        var barViewColor: UIColor = .clear
        var circleViewColor: UIColor = .clear

        if newOn {
            circleCenter = self.frame.width - (self.circleView.frame.width / 2)
            barViewColor = self.onColor.bar
            circleViewColor = self.onColor.circle
        } else {
            circleCenter = self.circleView.frame.width / 2
            barViewColor = self.offColor.bar
            circleViewColor = self.offColor.circle
        }
        
        UIView.animate(withDuration: self.animationDuration, animations: { [weak self] in
            guard let self = self else { return }

            self.circleView.center.x = circleCenter
            self.barView.backgroundColor = barViewColor
            self.circleView.backgroundColor = circleViewColor

        }) { [weak self] _ in
            guard let self = self else { return }
            self.delegate?.onChange(isOn: newOn)
        }
    }
}
