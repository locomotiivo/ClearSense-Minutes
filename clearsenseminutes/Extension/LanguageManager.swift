//
//  LanguageManager.swift
//  clearsenseminutes
//
//  Created by KooBH on 1/3/24.
//

import Foundation
import UIKit

var lan = Locale.current.language.languageCode?.identifier ?? "ko"

class LanguageLabel: UILabel {
    required init() {
        super.init(frame: .zero)
        NotificationCenter.default.addObserver(self, selector: #selector(updateUI), name: AppNotification.changeLanguage, object: nil)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        NotificationCenter.default.addObserver(self, selector: #selector(updateUI), name: AppNotification.changeLanguage, object: nil)
    }
    
    @IBInspectable var localized: String? {
        didSet{
            updateUI()
        }
    }
    
    @objc func updateUI(){
        if let string = localized {
            text = string.localized()
        }
    }
}

class LanguageTabbarItem: UITabBarItem {
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        NotificationCenter.default.addObserver(self, selector: #selector(updateUI), name: AppNotification.changeLanguage, object: nil)
    }
    
    @IBInspectable var localized: String? {
        didSet{
            updateUI()
        }
    }
    
    @objc func updateUI(){
        if let string = localized {
            title = string.localized()
        }
    }
}

class LanguageButton: UIButton{
    required init() {
        super.init(frame: .zero)
        NotificationCenter.default.addObserver(self, selector: #selector(updateUI), name: AppNotification.changeLanguage, object: nil)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        NotificationCenter.default.addObserver(self, selector: #selector(updateUI), name: AppNotification.changeLanguage, object: nil)
    }

    @IBInspectable var localized: String? {
        didSet {
            updateUI()
        }
    }
    
    @objc func updateUI(){
        if let string = localized {
//            configuration?.attributedTitle?.characters = .init(string.localized())
            setTitle(string.localized(), for: .normal)
        }
    }
}


class LanguageNavController: UINavigationController {
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(updateUI), name: AppNotification.changeLanguage, object: nil)
    }

    @IBInspectable var localized: String? {
        didSet {
            updateUI()
        }
    }
    
    @objc func updateUI(){
        if let string = localized {
            navigationBar.topItem?.title = string.localized()
        }
    }
}

class LanguageLogo: UIImageView {
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        NotificationCenter.default.addObserver(self, selector: #selector(updateUI), name: AppNotification.changeLanguage, object: nil)
    }

    @IBInspectable var localizedImageName: String? {
         didSet {
             updateUI()
         }
     }
    
    @objc func updateUI() {
        if let imageName = localizedImageName {
            let localizedImageName = imageName.localized()
            self.image = UIImage(named: localizedImageName)
        }
    }
}

@IBDesignable class MPTextView : UITextView {
    @IBInspectable open var top: CGFloat = 15 {
        didSet {
            refresh()
        }
    }
    
    @IBInspectable open var bottom: CGFloat = 15 {
        didSet {
            refresh()
        }
    }
    
    @IBInspectable open var left: CGFloat = 15 {
        didSet {
            refresh()
        }
    }
    
    @IBInspectable open var right: CGFloat = 15 {
        didSet {
            refresh()
        }
    }
    
    required override public init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        refresh()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        refresh()
    }
    
    func refresh() {
        textContainerInset = UIEdgeInsets(top: top, left: left, bottom: bottom, right: right)
    }
    
    func centerVerticalText() {
        let topCorrection = (bounds.size.height - contentSize.height * zoomScale) / 2
        top = max(0, topCorrection)
        contentInset = UIEdgeInsets(top: topCorrection, left: 0, bottom: 0, right: 0)
    }
 }
