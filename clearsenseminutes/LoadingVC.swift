//
//  LoadingVC.swift
//  clearsenseminutes
//
//  Created by KooBH on 3/14/24.
//

import Foundation
import UIKit

class LoadingVC: UIViewController {
    
    @IBOutlet weak var label_err: UILabel!
    @IBOutlet weak var btn_retry: UIButton!
    @IBOutlet weak var loaderView: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setup()
    }
    
    func setup() {
        loaderView.isHidden = false
        loaderView.startAnimating()
        self.showMainView()
    }
    
    func catchErr(_ err: Error) {
        loaderView.stopAnimating()
        label_err.text = err.localizedDescription
        btn_retry.isHidden = false
    }
    
    @IBAction func retry() {
        label_err.text = nil
        btn_retry.isHidden = true
        
        setup()
    }
    
    func showMainView() {
        loaderView.stopAnimating()
        let main = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController()!
        main.modalPresentationStyle = .fullScreen
        present(main, animated: true, completion: nil)
    }
    
}
