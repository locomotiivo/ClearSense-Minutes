//
//  Step1FirstView.swift
//  clearsenseminutes
//
//  Created by HWANJUN YU on 10/28/24.
//

import UIKit

class Step1FirstView: UIView {
    @IBOutlet weak var descBoxView: UIView!
    
    private var onClickHandler: ((Bool) -> Void)?
    
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
        if let view = Bundle.main.loadNibNamed("Step1FirstView", owner: self, options: nil)?.first as? UIView {
            view.frame = self.bounds
            addSubview(view)
        }
    }
    
    func setOnClickHandler(onClick: @escaping (Bool) -> Void) {
        onClickHandler = onClick
    }
    
    @IBAction func onClickOk(_ sender: UIButton) {
        onClickHandler?(true)
    }
    
    @IBAction func onClickLater(_ sender: UIButton) {
        onClickHandler?(false)
    }
}
