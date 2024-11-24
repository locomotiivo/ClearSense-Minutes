//
//import StoreKit
//import UIKit
//import RevenueCat
//import Gifu
//import OSLog
//
//class PaywallVC: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {
//    
//    var offering: Offering?
//    
//    @IBOutlet weak var bgGif : GIFImageView!
//    @IBOutlet weak var tableView: UITableView!
//    @IBOutlet weak var stackView: UIStackView!
//    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        
//        bgGif.prepareForAnimation(withGIFNamed: "BG")
//                
//        tableView.translatesAutoresizingMaskIntoConstraints = false
//        tableView.delegate = self
//        tableView.dataSource = self
//        
//        navigationItem.setLeftBarButton(navBackBtn, animated: false)
//        
//        let nav = self.navigationController as? LanguageNavController
//        nav?.localized = "SUBSCRIPTION"
//        self.navigationItem.title = "SUBSCRIPTION".localized()
//        
//        Purchases.shared.getOfferings { (offerings, error) in
//            if let error = error {
//                self.present(UIAlertController.errorAlert(message: error.localizedDescription), animated: true, completion: nil)
//            }
//            self.offering = offerings?.current
//            self.tableView.reloadData()
//        }
//    }
//}
//
//extension PaywallVC {
//    @IBAction func restorePurchase() {
//        Purchases.shared.restorePurchases { customerInfo, error in
//            if let error = error {
//                let message = "[App Startup] Error Restoring Purchase \(error.localizedDescription)"
//                os_log(.error, log: .paywall, "%@", message)
//                self.topMostViewController().Alert("ERROR", message, nil)
//                return
//            }
//            Purchases.shared.getCustomerInfo { (purchaserInfo, error) in
//                if let error = error {
//                    let message = "[App Startup] Error Fetching Customer Info \(error.localizedDescription)"
//                    os_log(.error, log: .paywall, "%@", message)
//                    self.topMostViewController().Alert("ERROR", message, nil)
//                    return
//                }
//                
//                let entitlementID = Bundle.main.infoDictionary?["EntitlementID"] as! String
//                if purchaserInfo?.entitlements[entitlementID]?.isActive == true {
//                    isPro = true
//                } else {
////                    isPro = false
//                    isPro = true
//                }
//            }
//        }
//    }
//    
//    @IBAction func gotoTOS(_ sender: Any) {
//        if let url = URL(string: "URL_TOS".localized()) ?? URL(string: "https://clearsenseaudio.com/"),
//           let vc = self.storyboard?.instantiateViewController(identifier: "WebVC") as? WebVC {
//            vc.url = url
//            vc.mode = 0
//            present(vc, animated: true, completion: nil)
//        }
//    }
//    
//    @IBAction func gotoPrivacy(_ sender: Any) {
//        if let url = URL(string: "URL_PRIVACY".localized()) ?? URL(string: "https://clearsenseaudio.com/"),
//           let vc = self.storyboard?.instantiateViewController(identifier: "WebVC") as? WebVC {
//            vc.url = url
//            vc.mode = 0
//            present(vc, animated: true, completion: nil)
//        }
//    }
//}
//
//extension PaywallVC {
//    func numberOfSections(in tableView: UITableView) -> Int {
//        return 1
//    }
//    
//    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        return offering?.availablePackages.count ?? 0
//    }
//    
//    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
//        return 100
//    }
//    
//    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        let cell = tableView.dequeueReusableCell(withIdentifier: "PackageCell", for: indexPath) as! PackageCell
//        
//        if let package = offering?.availablePackages[indexPath.row] {
//            cell.title.text = package.storeProduct.localizedTitle
//            
//            let price = package.localizedPriceString
//            cell.price.text = package.localizedPriceString
//            
//            if let intro = package.storeProduct.introductoryDiscount {
//                let packageTermsLabelText = intro.price == 0
//                ? " after \(intro.subscriptionPeriod.periodTitle()) " + "FREE_TRIAL".localized()
//                : " after \(package.localizedIntroductoryPriceString!) / \(intro.subscriptionPeriod.periodTitle())"
//
//                cell.price.text = price + packageTermsLabelText
//            } else {
//                cell.price.text = price
//            }
//        }
//        
//        cell.container.layer.masksToBounds = true
//        cell.container.layer.cornerRadius = 8
//        cell.container.layer.borderWidth = 1
//        cell.container.layer.shadowOffset = CGSize(width: -1, height: 1)
//        cell.container.layer.borderColor = UIColor.white.cgColor
//        
//        return cell
//    }
//    
//    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        tableView.deselectRow(at: indexPath, animated: true)
//        
//        if let package = offering?.availablePackages[indexPath.row] {
//            LoadingIndicator.showLoading()
//            Purchases.shared.purchase(package: package) { (transaction, purchaserInfo, error, userCancelled) in
//                LoadingIndicator.hideLoading()
//                if let error = error {
//                    self.present(UIAlertController.errorAlert(message: error.localizedDescription), animated: true, completion: nil)
//                } else {
//                    let entitlementID = Bundle.main.infoDictionary?["EntitlementID"] as! String
//                    if purchaserInfo?.entitlements[entitlementID]?.isActive == true {
//                        self.onClickBack(())
//                    }
//                }
//            }
//        }
//    }
//}
//
//extension SubscriptionPeriod {
//    var durationTitle: String {
//        switch unit {
//        case .day: return "DAY".localized()
//        case .week: return "WEEK".localized()
//        case .month: return "MONTH".localized()
//        case .year: return "YEAR".localized()
//        default: return "UNKNOWN"
//        }
//    }
//    
//    func periodTitle() -> String {
//        let periodString = "\(value) \(durationTitle)"
//        
//        if (lan == "en") {
//            return value > 1 ?  periodString + "s" : periodString
//        } else {
//            return periodString
//        }
//    }
//}
