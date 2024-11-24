//
//  Step4FirstView.swift
//  clearsenseminutes
//
//  Created by HWANJUN YU on 10/29/24.
//

import UIKit

class Step4FirstView: UIView {
    
    var completeHandler: (() -> Void)?
    var overwriteHandler: (() -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    convenience init(complete: @escaping () -> Void, overwrite: @escaping () -> Void) {
        self.init(frame: .zero)
        completeHandler = complete
        overwriteHandler = overwrite
    }
    
    private func commonInit() {
        if let view = Bundle.main.loadNibNamed("Step4FirstView", owner: self, options: nil)?.first as? UIView {
            view.frame = self.bounds
            addSubview(view)
        }
    }
    
    @IBAction func onClickComplete(_ sender: UIButton) {
        completeHandler?()
    }
    
    @IBAction func onClickOverwrite(_ sender: UIButton) {
        overwriteHandler?()
    }
}
