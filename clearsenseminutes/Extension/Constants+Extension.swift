//
//  Constants.swift
//  clearsenseminutes
//
//  Created by KooBH on 3/14/24.
//

import Foundation
import CoreData
import UIKit
import OSLog

var versionStr: String = ""

var mpWAVURL = URL(string: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0])!.appendingPathComponent("mpWAV", isDirectory: true)

var isPro: Bool = false

var audioEngine : AudioEngineManager = AudioEngineManager.shared
var DBconn : DBConnectionManager = DBConnectionManager.shared
var STTconn : SSTConnectionManager = SSTConnectionManager.shared

extension UIViewController {
    var navBackBtn: UIBarButtonItem {
        let backButton = UIButton(frame: CGRect(origin: .zero, size: CGSize(width: 31, height: 24)))
        backButton.setImage(UIImage(named: "ic_back"), for: .normal)
        backButton.contentHorizontalAlignment = .right
        backButton.addTarget(self, action: #selector(onClickBack), for: .touchUpInside)
        return UIBarButtonItem(customView: backButton)
    }
    
    // 백버튼 클릭
    @IBAction @objc func onClickBack(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    func Alert(_ title: String, _ message : String, _ handler: (() -> Void)?) {
        let sheet = UIAlertController(title: title, message: message, preferredStyle: .alert)
        sheet.addAction(UIAlertAction(title: "OK".localized(), style: .default) {_ in
            handler?()
        })
        present(sheet, animated: true, completion: nil)
    }
    
    func Alert(_ title: String, _ message: String, _ handlerOK: (() -> Void)?, _ handlerCancel: (() -> Void)?) {
        let sheet = UIAlertController(title: title, message: message, preferredStyle: .alert)
        sheet.addAction(UIAlertAction(title: "YES".localized(), style: .destructive) {_ in
            handlerOK?()
        })
        sheet.addAction(UIAlertAction(title: "CANCEL".localized(), style: .default) {_ in
            handlerCancel?()
        })
        present(sheet, animated: true, completion: nil)
    }
    
    func showToast(_ message : String) {
        let toastLabel = UILabel(frame: CGRect(x: view.center.x - (view.frame.size.width - 10) / 2.0,
                                               y: view.frame.size.height - 100,
                                               width: view.frame.size.width - 10,
                                               height: 35))
        toastLabel.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        toastLabel.textColor = UIColor.white
        toastLabel.textAlignment = .center
        toastLabel.text = message
        toastLabel.alpha = 1.0
        toastLabel.layer.cornerRadius = 10
        toastLabel.clipsToBounds  =  true
        view.addSubview(toastLabel)
        UIView.animate(withDuration: 4.0, delay: 0.1, options: .curveEaseOut, animations: {
            toastLabel.alpha = 0.0
        }, completion: {(isCompleted) in
            toastLabel.removeFromSuperview()
        })
    }
    
    /// Present over a given view controller
    func present(over viewController: UIViewController?) {
        guard let viewController = viewController else { return }
        if let popoverController = self.popoverPresentationController {
            popoverController.sourceView = viewController.view
            popoverController.permittedArrowDirections = []
            popoverController.sourceRect = CGRect(x: viewController.view.bounds.midX, y: viewController.view.bounds.midY, width: 0, height: 0)
        }
        viewController.present(self, animated: true)
    }
    
    func topMostViewController() -> UIViewController {
        if self.presentedViewController == nil {
            return self
        }
        
        if let navigation = self.presentedViewController as? UINavigationController {
            return navigation.visibleViewController!.topMostViewController()
        }
        
        if let tab = self.presentedViewController as? UITabBarController {
            if let selectedTab = tab.selectedViewController {
                return selectedTab.topMostViewController()
            }
            return tab.topMostViewController()
        }
        
        return self.presentedViewController!.topMostViewController()
    }
}

extension UIAlertController {
    class func errorAlert(message: String) -> UIAlertController {
        let errorAlert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        errorAlert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        return errorAlert
    }
}

extension UIApplication {
    var windowObj: UIWindow? {
        return self.connectedScenes
            .flatMap{ ($0 as? UIWindowScene)?.windows ?? [] }
            .last { $0.isKeyWindow }
    }
}

extension String {
    public func localized(_ lang:String) -> String {
        
        let path = Bundle.main.path(forResource: lang, ofType: "lproj")
        let bundle = Bundle(path: path!)
        
        return NSLocalizedString(self, tableName: nil, bundle: bundle!, value: "", comment: "")
    }
    
    public func localized() -> String {
        let path = Bundle.main.path(forResource: lan, ofType: "lproj")
        let bundle = Bundle(path: path!)
        
        return NSLocalizedString(self, tableName: nil, bundle: bundle!, value: "", comment: "")
    }
    
    public func localized(with argument: CVarArg = []) -> String {
        return String(format: self.localized(), argument)
    }
    
    var underLined: NSAttributedString {
        NSMutableAttributedString(string: self, attributes: [.underlineStyle: NSUnderlineStyle.single.rawValue])
    }
}

extension OSLog {
    private static var subsystem = Bundle.main.bundleIdentifier!
    static let files = OSLog(subsystem: subsystem, category: "Files")
    static let audio = OSLog(subsystem: subsystem, category: "Audio")
    static let paywall = OSLog(subsystem: subsystem, category: "Paywall")
    static let system = OSLog(subsystem: subsystem, category: "System")
}

extension Double {
    var toEqVal : String {
        let val = Float(self).rounded() == 0 ? 0 : Float(self).rounded()
        return Float.EqFormat.string(for: Float(val)) ?? "+0"
    }
}

extension Float {
    static let EqFormat: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .none
        formatter.positivePrefix = formatter.plusSign
        return formatter
    }()
    
    var toEqVal : String {
        let val = self.rounded() == 0 ? 0 : self.rounded()
        return Float.EqFormat.string(for: val) ?? "+0"
    }
}

struct AppNotification{
    static let changeLanguage = Notification.Name("changeLanguage")
    static let changeEq = Notification.Name("changeEq")
}

extension UIButton {
    func setBackgroundColor(_ color: UIColor?, for state: UIControl.State) {
        guard let color = color else { return }
        
        let minimumSize: CGSize = CGSize(width: 1.0, height: 1.0)
        UIGraphicsBeginImageContext(minimumSize)
        
        if let context = UIGraphicsGetCurrentContext() {
            context.setFillColor(color.cgColor)
            context.fill(CGRect(origin: .zero, size: minimumSize))
        }

        let colorImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        self.setBackgroundImage(colorImage, for: state)
    }
}

extension UIImage {
    func makeCircle(size: CGSize, backgroundColor: UIColor) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(backgroundColor.cgColor)
        context?.setStrokeColor(UIColor.clear.cgColor)
        context?.addEllipse(in: CGRect(origin: .zero, size: size))
        context?.drawPath(using: .fill)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}

extension UIColor {
    convenience init(hex: String, alpha: CGFloat = 1.0) {
        var hexFormatted: String = hex.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).uppercased()
        
        if hexFormatted.hasPrefix("#") {
            hexFormatted = String(hexFormatted.dropFirst())
        }
        
        assert(hexFormatted.count == 6, "Invalid hex code used.")
        
        var rgbValue: UInt64 = 0
        Scanner(string: hexFormatted).scanHexInt64(&rgbValue)
        
        self.init(red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
                  green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
                  blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
                  alpha: alpha)
    }
}

extension KeyedDecodingContainer {
    // String 키를 Int로 변환하는 유틸리티 확장
    func decodeStringKeyedDictionary(forKey key: Key) throws -> [Int: Double] {
        let stringKeyedDict = try self.decode([String: Double].self, forKey: key)
        var intKeyedDict: [Int: Double] = [:]
        for (stringKey, value) in stringKeyedDict {
            if let intKey = Int(stringKey) {
                intKeyedDict[intKey] = value
            } else {
                throw DecodingError.dataCorruptedError(forKey: key, in: self, debugDescription: "Invalid key: \(stringKey)")
            }
        }
        return intKeyedDict
    }
}
