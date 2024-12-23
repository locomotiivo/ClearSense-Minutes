//
//  LicenseVC.swift
//  clearsenseminutes
//
//  Created by KooBH on 7/20/24.
//

import Foundation
import UIKit

class LicenseVC: UIViewController {
    
    @IBOutlet weak var link_img: UIImageView!
    
    @IBOutlet weak var privacy_label: LanguageLabel!
    @IBOutlet weak var terms_label: LanguageLabel!
    @IBOutlet weak var cancel_button: LanguageButton!
    
    @IBOutlet weak var popUpView: UIView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        popUpView.layer.cornerRadius = 20
        
        
        terms_label.font = UIFont.systemFont(ofSize: 14)
        terms_label.textColor = UIColor(named: "btn_color")
        terms_label.numberOfLines = 0
        terms_label.isUserInteractionEnabled = true
      
        let terms_tapGesture = UITapGestureRecognizer(target: self, action: #selector(terms_of_use_urlTapped))
        terms_label.addGestureRecognizer(terms_tapGesture)
        
        
        privacy_label.font = UIFont.systemFont(ofSize: 14)
        privacy_label.textColor = UIColor(named: "btn_color")
        privacy_label.numberOfLines = 0
        privacy_label.isUserInteractionEnabled = true
        let privacy_tapGesture = UITapGestureRecognizer(target: self, action: #selector(privacy_policy_urlTapped))
        privacy_label.addGestureRecognizer(privacy_tapGesture)
        
        
        // UIScrollView 및 UIStackView 초기화
        let scrollView = UIScrollView()
        let stackView = UIStackView()
        
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(scrollView)
        scrollView.addSubview(stackView)
        
        // StackView 설정
        stackView.axis = .vertical
        stackView.spacing = 10
        stackView.alignment = .leading
        stackView.distribution = .fill
        
        // ScrollView와 StackView의 제약 조건 설정
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: link_img.bottomAnchor, constant: 5),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            scrollView.bottomAnchor.constraint(equalTo: cancel_button.topAnchor, constant: -10),
            
            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
        
        // 오픈소스 데이터 배열
        let openSourceLibraries = [
            ("Lottie", "4.5.0", "https://github.com/airbnb/lottie-spm"),
            ("SwiftyJSON", "5.0.2", "https://github.com/SwiftyJSON/SwiftyJSON"),
            ("TPCircularBuffer", "1.6.2", "https://github.com/michaeltyson/TPCircularBuffer"),
        ]
        
        // 데이터를 stackView에 추가
        for (name, version, url) in openSourceLibraries {
            let nameLabel = UILabel()
            nameLabel.text = "Name: \(name)"
            nameLabel.font = UIFont.boldSystemFont(ofSize: 16)
            
            let versionLabel = UILabel()
            versionLabel.text = "Version: \(version.isEmpty ? "N/A" : version)"
            versionLabel.font = UIFont.systemFont(ofSize: 14)
            versionLabel.textColor = .gray
            
            let urlLabel = UILabel()
            urlLabel.text = "Source: \(url)"
            urlLabel.font = UIFont.systemFont(ofSize: 14)
            urlLabel.textColor = UIColor(named: "btn_color")
            urlLabel.numberOfLines = 0
            urlLabel.isUserInteractionEnabled = true
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(urlTapped(_:)))
            urlLabel.addGestureRecognizer(tapGesture)
            
            let itemStackView = UIStackView(arrangedSubviews: [nameLabel, versionLabel, urlLabel])
            itemStackView.axis = .vertical
            itemStackView.spacing = 5
            stackView.addArrangedSubview(itemStackView)
        }
    }
    
    @objc func urlTapped(_ sender: UITapGestureRecognizer) {
        if let label = sender.view as? UILabel,
           let urlText = label.text?.replacingOccurrences(of: "Source: ", with: ""),
           let url = URL(string: urlText),
           let vc = self.storyboard?.instantiateViewController(identifier: "WebVC") as? WebVC {
            vc.url = url
            vc.mode = 0
            present(vc, animated: true, completion: nil)
        }
    }
    
    @objc func privacy_policy_urlTapped(_ sender: UITapGestureRecognizer) {
        if let label = sender.view as? UILabel,
           let url = URL(string: "URL_PRIVACY".localized()) ?? URL(string: "https://clearsenseaudio.com/"),
           let vc = self.storyboard?.instantiateViewController(identifier: "WebVC") as? WebVC {
            vc.url = url
            vc.mode = 0
            present(vc, animated: true, completion: nil)
        }
    }

    @objc func terms_of_use_urlTapped(_ sender: UITapGestureRecognizer) {
        if let label = sender.view as? UILabel,
           let url = URL(string: "URL_TOS".localized()) ?? URL(string: "https://clearsenseaudio.com/"),
           let vc = self.storyboard?.instantiateViewController(identifier: "WebVC") as? WebVC {
            vc.url = url
            vc.mode = 0
            present(vc, animated: true, completion: nil)
        }
    }
    
    
    @IBAction func onClickClose(_ sender: Any) {
        self.dismiss(animated: true)
    }
}
