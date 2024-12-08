//
//  MinuteDetailsVC.swift
//  clearsenseminutes
//
//  Created by KooBH on 11/24/24.
//

import UIKit
import OSLog
import SwiftyJSON
import Foundation

class MinuteDetailsVC: UIViewController, UIPopoverPresentationControllerDelegate {
    var id: String = ""
    
    @IBOutlet weak var minute_title: UITextField!
    @IBOutlet weak var minute_company: UITextField!

    @IBOutlet weak var minute_date: UILabel!
    @IBOutlet weak var minute_text: MPTextView!
    
    @IBOutlet weak var btn_edit: LanguageButton!
    @IBOutlet weak var btn_done: LanguageButton!
    
    @IBOutlet weak var popUpView: UIView!

    private var dateTime: Date!
    private var editMode = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        btn_edit.isHidden = false
        btn_done.isHidden = true

        minute_title.delegate = self
        minute_company.delegate = self
        
        LoadingIndicator.showLoading()
        doQuery()
        LoadingIndicator.hideLoading()
        
        NotificationCenter.default.addObserver(self, selector: #selector(onChangeDate), name: AppNotification.changeDate, object: nil)
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard)))
        minute_date.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onClickDate)))
    }
    
    func doQuery() {
        do {
            try DBconn.DBRequest("GET", false, "/meetings/get-record/\(self.id)", [:]) { [weak self]
                (flag, res, msg, data) in
                guard flag,
                let data = data else {
                    self?.Alert("ERROR".localized(), msg, nil)
                    return
                }
                let jsonObj = JSON(data)["data"].object
                let json = JSON(jsonObj)
                if let title = json["meeting_name"].string,
                   let urlstr = json["summary_txt_url"].string,
                   let company = json["company_name"].string,
                   let date = json["meeting_datetime"].string,
                   let dt = formatterISO.date(from: date) {
                    do {
                        try DBconn.DBRequest("GET", true, urlstr, [:]) { [weak self]
                            (flag, res, msg, data) in
                            guard flag,
                                  let data = data,
                                  let text = String(data: data, encoding: .utf8)
                            else {
                                self?.Alert("ERROR".localized(), msg, nil)
                                return
                            }
                            self?.minute_title.text = title
                            self?.minute_text.text = text
                            self?.minute_company.text = company
                            self?.dateTime = dt
                            self?.minute_date.text = formatterTxt.string(from: dt)
                        }
                    } catch {
                        self?.Alert("ERROR".localized(), "Invalid Minute Data", nil)
                        return
                    }
                }
            }
        }
        catch DBRequestError.invalidURL(let err) {
            Alert("ERROR".localized(), err, nil)
        } catch DBRequestError.missingData(let err) {
            Alert("ERROR".localized(), err, nil)
        } catch DBRequestError.AccessDenied(let err) {
            Alert("ERROR".localized(), err, nil)
        } catch DBRequestError.ErrorCode(let err) {
            Alert("ERROR".localized(), err, nil)
        } catch (let err) {
            Alert("ERROR".localized(), err.localizedDescription, nil)
        }
    }
    
    @IBAction func onClickEdit(_ sender: Any) {
        editMode = true
        btn_edit.isHidden = true
        btn_done.isHidden = false
        
        minute_title.isUserInteractionEnabled = true
        minute_date.isUserInteractionEnabled = true
        minute_company.isUserInteractionEnabled = true
    }
    
    @IBAction func onClickDone(_ sender: Any) {
        do {
            try DBconn.DBRequest("PUT", false, "/meetings/update-record/\(id)", ["meeting-id": id, "update_data" : ["company_name": minute_company.text ?? "", "meeting_name": minute_title.text ?? "", "meeting_datetime": formatterISO.string(from: dateTime)]]) { [weak self]
                (flag, res, msg, data) in
                guard flag,
                      let data = data,
                      res == 200
                else {
                    self?.Alert("ERROR".localized(), msg, nil)
                    return
                }
                
                self?.Alert("DELETE_SUCCESS".localized(),  JSON(data)["message"].string ?? "") {
                    self?.editMode = false
                    
                    self?.btn_done.isHidden = true
                    self?.btn_edit.isHidden = false
                    
                    self?.minute_title.isUserInteractionEnabled = false
                    self?.minute_date.isUserInteractionEnabled = false
                    self?.minute_company.isUserInteractionEnabled = false
                    
                    self?.doQuery()
                }
            }
        }
        catch DBRequestError.invalidURL(let err) {
            Alert("ERROR".localized(), err, nil)
        } catch DBRequestError.missingData(let err) {
            Alert("ERROR".localized(), err, nil)
        } catch DBRequestError.AccessDenied(let err) {
            Alert("ERROR".localized(), err, nil)
        } catch DBRequestError.ErrorCode(let err) {
            Alert("ERROR".localized(), err, nil)
        } catch (let err) {
            Alert("ERROR".localized(), err.localizedDescription, nil)
        }
    }
    
    @IBAction func onClickDelete(_ sender: Any) {
        Alert("DELETE_CONFIRM".localized(), "", { [weak self] in
            do {
                try DBconn.DBRequest("DELETE", false, "/meetings/delete-record/\(self?.id ?? "")", [:]) { [weak self]
                    (flag, res, msg, data) in
                    guard flag,
                          let data = data,
                          res == 200
                    else {
                        self?.Alert("ERROR".localized(), msg, nil)
                        return
                    }
                    
                    self?.Alert("DELETE_SUCCESS".localized(),  JSON(data)["message"].string ?? "") {
                        NotificationCenter.default.post(name: AppNotification.deleteMinute , object: nil)
                        self?.dismiss(animated: true)
                    }
                }
            } catch DBRequestError.invalidURL(let err) {
                self?.Alert("ERROR".localized(), err, nil)
            } catch DBRequestError.missingData(let err) {
                self?.Alert("ERROR".localized(), err, nil)
            } catch DBRequestError.AccessDenied(let err) {
                self?.Alert("ERROR".localized(), err, nil)
            } catch DBRequestError.ErrorCode(let err) {
                self?.Alert("ERROR".localized(), err, nil)
            } catch (let err) {
                self?.Alert("ERROR".localized(), err.localizedDescription, nil)
            }
        })
    }

    @IBAction func onClose(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
    @objc func onClickDate(_ sender: Any) {
        guard editMode,
              let vc = self.storyboard?.instantiateViewController(identifier: "MinuteCalendar") as? MinuteCalendar
        else { return }
        vc.date = dateTime
        vc.delegate = self
        vc.modalPresentationStyle = .popover
        vc.modalTransitionStyle = .crossDissolve
        vc.view.backgroundColor = .black.withAlphaComponent(0.6)
        vc.view.layer.cornerRadius = 8
        present(vc, animated: true, completion: nil)
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.none
    }

    func popoverPresentationControllerShouldDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) -> Bool {
        return true
    }
    
    @objc func onChangeDate(_ sender: NSNotification) {
        guard let date = sender.userInfo?["date"] as? Date else {
            return
        }
        dateTime = date
        minute_date.text = formatterTxt.string(from: date)
    }
}

extension MinuteDetailsVC : UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}
