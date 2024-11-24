//
//  notiWebVC.swift
//  clearsenseminutes
//
//  Created by HYUNJUN SHIN on 9/4/24.
//

import UIKit
import WebKit

class notiWeb: UIViewController {
    var webView: WKWebView!
    var navigationBar: UINavigationBar!
    var htmlString: String = ""
    var currentNotiDate: Int = 0
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // WKWebView 초기화
        webView = WKWebView(frame: .zero)
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.scrollView.alwaysBounceHorizontal = false
        webView.scrollView.alwaysBounceVertical = true
        self.view.addSubview(webView)
        
        // 오토레이아웃 설정
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.topAnchor, constant: 30),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30)
        ])
        
        // 네비게이션 바 설정 (하단에 위치)
        setupBottomNavigationBar()

        webView.loadHTMLString(htmlString, baseURL: nil)
    }

    func setupBottomNavigationBar() {
        // 네비게이션 바 초기화
        navigationBar = UINavigationBar(frame: .zero)
        navigationBar.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(navigationBar)
        
        // 네비게이션 바에 아이템 추가
        let navigationItem = UINavigationItem(title: "")
        
        // 왼쪽 X 버튼

        let cancelButton = UIBarButtonItem(image: UIImage(systemName: "xmark.circle.fill"), style: .plain, target: self, action: #selector(cancelAction))
        
        // 오른쪽 "다시 보지 않기" 버튼
        let dontShowButton = UIBarButtonItem(title: "DONOT_SHOW_AGAIN".localized(), style: .plain, target: self, action: #selector(dontShowAgainAction))
        
        navigationItem.leftBarButtonItem = cancelButton
        navigationItem.rightBarButtonItem = dontShowButton
        
        navigationBar.setItems([navigationItem], animated: false)
        
        // 네비게이션 바의 오토레이아웃 설정 (하단에 위치)
        NSLayoutConstraint.activate([
            navigationBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            navigationBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            navigationBar.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 30),
            navigationBar.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.15)
        ])
    }

    @objc func cancelAction() {
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func dontShowAgainAction() {
        UserDefaults.standard.set(currentNotiDate, forKey: "didNotificationDate")
        
        // 현재 화면 닫기
        self.dismiss(animated: true, completion: nil)
    }
}
