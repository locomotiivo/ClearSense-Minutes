//
//  Step2SecondView.swift
//  clearsenseminutes
//
//  Created by HWANJUN YU on 10/29/24.
//

import UIKit

class Step2SecondView: UIView {
    @IBOutlet weak var textLabel: UILabel!
    
    var onClickHandler: (() -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    convenience init(onClick: @escaping () -> Void) {
        self.init(frame: .zero)
        onClickHandler = onClick
    }
    
    private func commonInit() {
        if let view = Bundle.main.loadNibNamed("Step2SecondView", owner: self, options: nil)?.first as? UIView {
            view.frame = self.bounds
            addSubview(view)
        }
        
        let attributedText = NSMutableAttributedString(
            string: "SELECT_EAR".localized(),
            attributes: [.font: UIFont(name: "PretendardGOVVariable-ExtraBold", size: 30) ?? UIFont.systemFont(ofSize: 30, weight: .heavy)]
        )
        attributedText.append(NSAttributedString(
            string: "STEP_2_2_TEXT".localized(),
            attributes: [.font: UIFont(name: "PretendardGOVVariable-SemiBold", size: 30) ?? UIFont.systemFont(ofSize: 30, weight: .semibold)]
        ))
        textLabel.attributedText = attributedText
    }
    
    @IBAction func onClickNext(_ sender: UIButton) {
        onClickHandler?()
    }
}
