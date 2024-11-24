//
//  Step3ThirdView.swift
//  clearsenseminutes
//
//  Created by HWANJUN YU on 10/29/24.
//

import UIKit
import Lottie

class Step3ThirdView: UIView {
    
    @IBOutlet weak var animationView: LottieAnimationView!
    
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
        if let view = Bundle.main.loadNibNamed("Step3ThirdView", owner: self, options: nil)?.first as? UIView {
            view.frame = self.bounds
            addSubview(view)
        }
        
        let animation = LottieAnimation.named("anim_speaker")
        animationView.animation = animation
        animationView.contentMode = .scaleAspectFit
        animationView.loopMode = .loop
        animationView.play()
    }
    
    @IBAction func onClickStart(_ sender: UIButton) {
        onClickHandler?()
    }
}
