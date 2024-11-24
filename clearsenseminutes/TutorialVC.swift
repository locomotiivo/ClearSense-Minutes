//
//  TutorialVC.swift
//  backup_mpwav
//
//  Created by KooBH on 4/11/24.
//

import Foundation
import UIKit

class TutorialVC : UIViewController {
    @IBOutlet weak var view_img: UIImageView!
    @IBOutlet weak var btn_toggle: LanguageButton!
    @IBOutlet weak var btn_close: LanguageButton!
    var flag = false;
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view_img.image = UIImage(named: "tutorial");
        
        btn_toggle.setImage(UIImage(systemName: "circle"), for: .normal)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func onClickToggle(_ target: LanguageButton) {
        flag = !flag
        if (flag) {
            btn_toggle.setImage(UIImage(systemName: "circle.fill"), for: .normal)
        }
        else {
            btn_toggle.setImage(UIImage(systemName: "circle"), for: .normal)
        }
    }
    
    @IBAction func onClickClose(_ target: LanguageButton) {
        UserDefaults.standard.set(flag, forKey: "noTutorial")
        self.dismiss(animated: true)
    }
}
