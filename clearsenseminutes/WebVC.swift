//
//  WebVC.swift
//
//  Created by KooBH on 3/28/24.
//

import Foundation
import UIKit
import WebKit

class WebVC: UIViewController, WKUIDelegate {
    @IBOutlet weak var webView: WKWebView!
    
    var url: URL!
    var urlRequest: URLRequest!
    var mode: Int = 0
    var htmlString: String = ""
    var currentNotiDate: Int = 0
    @IBOutlet weak var popUpView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        popUpView.layer.cornerRadius = 10
        
        webView.uiDelegate = self
        webView.scrollView.isScrollEnabled = true
        webView.contentMode = .center
        
        if mode == 0 {
            urlRequest = URLRequest(url: url)
            webView.load(urlRequest)
        }
        else if mode == 1 {
            webView.loadHTMLString(htmlString, baseURL: nil)
        }
        else {
            webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        }
    }
    
    @IBAction func onClose(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
    @IBAction func onCloseWithFlag(_ sender: Any) {
        UserDefaults.standard.set(currentNotiDate, forKey: "didNotificationDate")
        
        self.dismiss(animated: true)
    }
    
    func webViewDidClose(_ webView: WKWebView) {
        self.dismiss(animated: true)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        let script = """
                          var elements = document.getElementsByTagName("*")
                          for (var i = 0; i < elements.length; i++) {
                            if (elements[i].target == '_blank') {
                              elements[i].target = '_self'
                            }
                          }
                       """
        webView.evaluateJavaScript(script, completionHandler: nil)
    }
}
