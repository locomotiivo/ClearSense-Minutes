//
//  MinuteVC.swift
//  clearsenseminutes
//
//  Created by KooBH on 11/24/24.
//

import UIKit
import OSLog
import SwiftyJSON
import Foundation

class MinuteVC: UIViewController {
    var id: String = ""
    
    @IBOutlet weak var minute_title: UITextField!
    @IBOutlet weak var minute_company: UITextField!

    @IBOutlet weak var minute_date: UILabel!
    @IBOutlet weak var minute_text: UITextView!
    
    @IBOutlet weak var btn_edit: LanguageButton!
    @IBOutlet weak var btn_done: LanguageButton!
    
    var dateTime: Date!
    let formatterISO = ISO8601DateFormatter()
    let formatterTxt = DateFormatter()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        formatterISO.formatOptions = [
            .withFullDate,
            .withSpaceBetweenDateAndTime
        ]
        formatterTxt.dateFormat = "yyyy/MM/dd"
        
        btn_edit.isHidden = false
        btn_done.isHidden = true
        
        LoadingIndicator.showLoading()
        Task {
            guard let json = try? await DBconn.DBRequest("GET", ["URL":"/meetings/get-record/\(self.id)"]) else {
                os_log(.error, log: .system, "Invalid JSON data")
                LoadingIndicator.hideLoading()
                return
            }
            minute_title.text = json["meeting_name"].string
            minute_text.text = json["meeting_txt"].string
            minute_company.text = json["company_name"].string
            dateTime = formatterISO.date(from: json["meeting_datetime"].string ?? "")
            minute_date.text = self.formatterTxt.string(from: dateTime)
        }
        LoadingIndicator.hideLoading()
    }
    
    @IBAction func onClickEdit(_ sender: Any) {
        btn_edit.isHidden = true
        btn_edit.isHidden = false
        
        minute_title.isUserInteractionEnabled = true
        minute_date.isUserInteractionEnabled = true
        minute_company.isUserInteractionEnabled = true
    }
    
    @IBAction func onClickDone(_ sender: Any) {
        btn_edit.isHidden = true
        btn_edit.isHidden = false
        
        minute_title.isUserInteractionEnabled = false
        minute_date.isUserInteractionEnabled = false
        minute_company.isUserInteractionEnabled = false
        
        LoadingIndicator.showLoading()
        Task {
            guard let json = try? await DBconn.DBRequest("GET", ["URL":"/meetings/update-record/\(id)", "meeting-id": id, "meeting_name": minute_title.text ?? "", "meeting_date": formatterISO.string(from: dateTime)]) else {
                os_log(.error, log: .system, "Invalid JSON data")
                LoadingIndicator.hideLoading()
                return
            }
            minute_title.text = json["meeting_name"].string
            minute_text.text = json[""].string
            minute_company.text = json["company_name"].string
            minute_date.text = json["meeting_datetime"].string
        }
        LoadingIndicator.hideLoading()
    }
    
    @IBAction func onClickDelete(_ sender: Any) {
        LoadingIndicator.showLoading()
        Task {
            guard let json = try? await DBconn.DBRequest("GET", ["URL":"/meetings/delete-record/\(id)"]) else {
                os_log(.error, log: .system, "Invalid JSON data")
                LoadingIndicator.hideLoading()
                return
            }
            os_log("")
            self.dismiss(animated: true)
        }
        LoadingIndicator.hideLoading()
    }
}
