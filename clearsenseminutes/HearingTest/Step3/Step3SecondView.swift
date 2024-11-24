//
//  Step3SecondeView.swift
//  clearsenseminutes
//
//  Created by HWANJUN YU on 10/29/24.
//

import UIKit
import Lottie

class Step3SecondView: UIView {
    
    @IBOutlet weak var animationView: LottieAnimationView!
    
    var onClickNumHandler: ((Int) -> Void)? // 숫자 클릭 핸들러
    var onClickRetryHandler: (() -> Void)?  // 다시하기 클릭 핸들러
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    convenience init(onClickNum: @escaping (Int) -> Void, onClickRetry: @escaping () -> Void) {
        self.init(frame: .zero)
        onClickNumHandler = onClickNum
        onClickRetryHandler = onClickRetry
    }
    
    private func commonInit() {
        if let view = Bundle.main.loadNibNamed("Step3SecondView", owner: self, options: nil)?.first as? UIView {
            view.frame = self.bounds
            addSubview(view)
        }
        
        let animation = LottieAnimation.named("anim_speaker")
        animationView.animation = animation
        animationView.contentMode = .scaleAspectFit
        animationView.loopMode = .loop
        animationView.play()
    }
    
    @IBAction func onClickNum(_ sender: UIButton) {
        onClickNumHandler?(sender.tag)
    }
    
    @IBAction func onClickRetry(_ sender: UIButton) {
        onClickRetryHandler?()
    }
}
