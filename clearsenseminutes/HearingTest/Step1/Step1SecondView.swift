//
//  Step1SecondView.swift
//  clearsenseminutes
//
//  Created by HWANJUN YU on 10/28/24.
//

import UIKit

class Step1SecondView: UIView {
    
    var onClickHandler: ((Bool) -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    convenience init(onClick: @escaping (Bool) -> Void) {
        self.init(frame: .zero)
        onClickHandler = onClick
    }
    
    private func commonInit() {
        if let view = Bundle.main.loadNibNamed("Step1SecondView", owner: self, options: nil)?.first as? UIView {
            view.frame = self.bounds
            addSubview(view)
        }
    }
    
    @IBAction func onClickOk(_ sender: UIButton) {
        onClickHandler?(true)
    }
    
    @IBAction func onClickNo(_ sender: UIButton) {
        onClickHandler?(false)
    }
}
