//
//  Step3FourthView.swift
//  clearsenseminutes
//
//  Created by HWANJUN YU on 10/29/24.
//

import UIKit

class Step3FourthView: UIView {
    
    @IBOutlet weak var topLabel: UILabel!
    @IBOutlet weak var bottomLabel: UILabel!
    
    @IBOutlet weak var seContraint1: NSLayoutConstraint!
    @IBOutlet weak var seContraint2: NSLayoutConstraint!
    @IBOutlet weak var seContraint3: NSLayoutConstraint!
    
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
        if let view = Bundle.main.loadNibNamed("Step3FourthView", owner: self, options: nil)?.first as? UIView {
            view.frame = self.bounds
            addSubview(view)
        }
        
        let topAttrText = NSMutableAttributedString(
            string: "EAR_LEFT".localized(), // TODO: 방금 측정한 귀
            attributes: [.font: UIFont(name: "PretendardGOVVariable-ExtraBold", size: 30) ?? UIFont.systemFont(ofSize: 30, weight: .heavy)]
        )
        topAttrText.append(NSAttributedString(
            string: "STEP_3_4_TOP".localized(),
            attributes: [.font: UIFont(name: "PretendardGOVVariable-SemiBold", size: 30) ?? UIFont.systemFont(ofSize: 30, weight: .semibold)]
        ))
        topLabel.attributedText = topAttrText
        
        let bottomAttrText = NSMutableAttributedString(
            string: "EAR_RIGHT".localized(), // TODO: 반대쪽 귀
            attributes: [.font: UIFont(name: "PretendardGOVVariable-ExtraBold", size: 30) ?? UIFont.systemFont(ofSize: 30, weight: .heavy)]
        )
        bottomAttrText.append(NSAttributedString(
            string: "STEP_3_4_BOTTOM".localized(),
            attributes: [.font: UIFont(name: "PretendardGOVVariable-SemiBold", size: 30) ?? UIFont.systemFont(ofSize: 30, weight: .semibold)]
        ))
        bottomLabel.attributedText = bottomAttrText
        
        
        if Utils.isSeDevice() {
            seContraint1.constant = 9
            seContraint2.constant = 11
            seContraint3.constant = -42
        }
    }
    
    @IBAction func onClickOtherEar(_ sender: UIButton) {
        onClickHandler?(true)
    }
    
    @IBAction func onClickSameResult(_ sender: UIButton) {
        onClickHandler?(false)
    }
}
