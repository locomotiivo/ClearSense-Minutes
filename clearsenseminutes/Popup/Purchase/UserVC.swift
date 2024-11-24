////
////  UserVC.swift
////  Magic Weather
////
////  Created by Cody Kerns on 12/14/20.
////
//
//import UIKit
//import RevenueCat
//
///*
// View controller to display user's details like subscription status and ID's.
// Configured in /Resources/UI/Main.storyboard
// */
//
//class UserVC: UIViewController {
//    
//    @IBOutlet weak var popUpView: UIView!
//    @IBOutlet weak var optionLabel: LanguageLabel!
//    @IBOutlet weak var dateLabel: UILabel!
//    
//    override func viewDidAppear(_ animated: Bool) {
//        super.viewDidAppear(animated)
//        
//        popUpView.layer.cornerRadius = 20
//        
//        refreshUserDetails()
//    }
//    
//    private func refreshUserDetails() {
//        Purchases.shared.getCustomerInfo { [weak self] (purchaserInfo, error) in
//            guard let self = self else { return }
//            
//            let entitlementID = Bundle.main.infoDictionary?["EntitlementID"] as! String
//            
//            if purchaserInfo?.entitlements[entitlementID]?.isActive == true {
//                optionLabel.text = purchaserInfo?.entitlements[entitlementID]?.description
//                
//                let dateFormat = DateFormatter()
//                dateFormat.dateFormat = "yyyy/MM/dd"
//                dateLabel.text = dateFormat.string(from:(purchaserInfo?.entitlements[entitlementID]?.latestPurchaseDate)!) + " ~ " + dateFormat.string(from:(purchaserInfo?.entitlements[entitlementID]?.expirationDate)!)
//            } else {
//                optionLabel.text = "OPTION_N".localized()
//                dateLabel.text = "n/a"
//            }
//            
//            optionLabel.text = "SUB_MSG_BETA".localized()
//            dateLabel.text = "SUB_MSG_BETA".localized()
//        }
//    }
//    
//    @IBAction func restorePurchases() {
//        Purchases.shared.restorePurchases { [weak self] (purchaserInfo, error) in
//            if let error = error {
//                self?.present(UIAlertController.errorAlert(message: error.localizedDescription), animated: true, completion: nil)
//            }
//            self?.refreshUserDetails()
//        }
//    }
//    
//    @IBAction func onClickClose(_ sender: Any) {
//        self.dismiss(animated: true)
//    }
//}
