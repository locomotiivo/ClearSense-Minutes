//
//  LanguageVC.swift
//  clearsenseminutes
//
//  Created by KooBH on 7/20/24.
//

import Foundation
import UIKit
import DropDown
import CoreData
import OSLog

class LanguageVC: UIViewController {
    
    @IBOutlet weak var label_lan: LanguageLabel!
    @IBOutlet weak var btn_down: UIImageView!
    @IBOutlet weak var btn_close: LanguageButton!
    @IBOutlet weak var dropView: UIView!
    
    @IBOutlet weak var popUpView: UIView!
    
    let dropdown = DropDown()
    let language =  ["ko": "LANGUAGE_ko".localized(), "en": "LANGUAGE_en".localized()]

    var container: NSPersistentContainer!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        popUpView.layer.cornerRadius = 20
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        container = appDelegate.persistentContainer
        
        DropDown.appearance().textColor = .black
        DropDown.appearance().selectedTextColor = .separator
        DropDown.appearance().backgroundColor = .white
        DropDown.appearance().selectionBackgroundColor = .lightGray
        DropDown.appearance().setupCornerRadius(8)
        dropdown.dismissMode = .automatic
        
        label_lan.localized = "LANGUAGE_SELECT"
        
        dropdown.dataSource = Array(language.values)
        dropdown.anchorView = dropView
        dropdown.bottomOffset = CGPoint(x: 0, y: dropView.bounds.height)
        
        dropdown.selectionAction = { [weak self] (index, item) in
            self!.label_lan.localized = "LANGUAGE_" + (self!.language.first(where: { $1 == item })?.key ?? "ko")
            lan = self!.language.first(where: { $1 == item })?.key ?? "ko"
            
            do {
                let flags = try self!.container.viewContext.fetch(Flag.fetchRequest())
                if flags.count > 0 {
                    let flag = flags[0]
                    flag.lan = lan
                } else {
                    let entity = NSEntityDescription.entity(forEntityName: "Flag", in: self!.container.viewContext)
                    let flags = NSManagedObject(entity: entity!, insertInto: self!.container.viewContext)
                    flags.setValue(lan, forKey: "lan")
                }

                try self!.container.viewContext.save()
                self!.showToast("SUCCESS_MSG".localized())
            } catch {
                self!.Alert("ERROR".localized(), "ERR_1000".localized(), nil)
            }

            NotificationCenter.default.post(name: AppNotification.changeLanguage , object: nil)
        }
        
        dropdown.cancelAction = {
            os_log(.debug, log: .system, "Dropdown Menu Closed")
        }
        
        dropView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onClickDropDown)))
        dropView.isUserInteractionEnabled = true
    }
    
    @objc func onClickDropDown(_ sender: Any) {
        dropdown.show()
    }
    
    @IBAction func onClickClose(_ sender: Any) {
        self.dismiss(animated: true)
    }
}
