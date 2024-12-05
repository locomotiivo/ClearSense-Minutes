//
//  SettingVC.swift
//  clearsenseminutes
//
//  Created by HWANJUN YU on 10/30/24.
//

import UIKit
import AVKit
import CoreData
import OSLog

class SettingVC: UIViewController {
    // 메뉴들
    @IBOutlet weak var menualMenu: UIView!  // 도움말 메뉴
    @IBOutlet weak var outputMenu: UIView!  // 출력
    @IBOutlet weak var contactMenu: UIView! // 고객문의 메뉴
    @IBOutlet weak var devMenu: UIView!     // 개발자 메뉴
    
    // 네비게이션 아이템
    lazy var btn_language = UIBarButtonItem(image: UIImage(named: "ic_global"), style: .plain, target: self, action: #selector(onClickLanguage))
    
    var container: NSPersistentContainer!
    let routePickerView = AVRoutePickerView()
    private var eqLabelArr: [UILabel] = []

    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
#if RELEASE
        devMenu.isHidden = true
#endif
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        container = appDelegate.persistentContainer
        
        setupLayout()
        setupControl()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    // MARK: - Init
    private func setupLayout() {
        // 네비게이션 바
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.shadowImage = UIImage()
        appearance.shadowColor = .clear // 하단 구분선 색상을 투명하게 설정
        appearance.backgroundColor = .clear
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationItem.setLeftBarButton(navBackBtn, animated: false)
        navigationItem.title = "SETTINGS".localized()
        navigationItem.setRightBarButton(btn_language, animated: false)
    }
    
    private func setupControl() {
        // 메뉴 클릭 이벤트 세팅
        menualMenu.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onClickMenual)))
        contactMenu.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onClickContact)))
        devMenu.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(gotoAdvanced)))
    }
    
    // MARK: - onClick Event
    // 언어설정 버튼 클릭
    @objc func onClickLanguage(_ sender: Any) {
        guard let vc = self.storyboard?.instantiateViewController(identifier: "LanguageVC") as? LanguageVC else {
            return
        }
        
        vc.modalPresentationStyle = .overCurrentContext
        vc.view.backgroundColor = .black.withAlphaComponent(0.6)
        vc.view.layer.cornerRadius = 8
        navigationController?.present(vc, animated: true, completion: nil)
    }
    
    // 도움말 버튼 클릭
    @objc func onClickMenual(_ sender: Any) {
        guard let vc = self.storyboard?.instantiateViewController(identifier: "WebVC") as? WebVC else { return }
        guard let url = Bundle.main.url(forResource: "MANUAL_HTML".localized(), withExtension: "html") else { return }
        
        vc.url = url
        vc.mode = 2
        
        present(vc, animated: true, completion: nil)
    }

    // 고객문의 메뉴 클릭
    @objc func onClickContact(_ sender: Any) {
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = "clearsenseminutes@mpwav.com" // 메일 주소
        components.queryItems = [URLQueryItem(name: "subject", value: "Contact")] // 메일 제목
        
        guard let url = components.url else { return }

        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    
    // 개발자 메뉴 클릭
    @objc func gotoAdvanced(_ sender: Any) {
//        guard let nextVC = self.storyboard?.instantiateViewController(withIdentifier: "AdvancedSettingVC") as? AdvancedSettingVC else { return }
//        self.navigationController?.pushViewController(nextVC, animated: true)
    }
}
