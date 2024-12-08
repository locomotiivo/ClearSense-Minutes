//
//  MinuteCalendar.swift
//  clearsenseminutes
//
//  Created by KooBH on 12/8/24.
//
import UIKit
import Foundation

class MinuteCalendar: UIViewController {
    let cal = Calendar.current
    
    lazy var calendarView: UICalendarView = {
        let view = UICalendarView()
        view.wantsDateDecorations = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    var selectedDate: DateComponents?
    var date: Date?
    var delegate: UIPopoverPresentationControllerDelegate?
    
    @IBOutlet weak var containerView: UICalendarView!
    @IBOutlet weak var popUpView: UIView!

    override func viewDidLoad() {
        super.viewDidLoad()
        calendarView.delegate = self
        
        containerView.addSubview(calendarView)
        
        calendarView.delegate = self
        let dateSelection = UICalendarSelectionSingleDate(delegate: self)
        calendarView.selectionBehavior = dateSelection
        
        let calendarViewConstraints = [
            calendarView.leadingAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.leadingAnchor),
            calendarView.trailingAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.trailingAnchor),
            calendarView.topAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.topAnchor),
            calendarView.bottomAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.bottomAnchor)
        ]
        NSLayoutConstraint.activate(calendarViewConstraints)
        
        reloadCalendar(date: date)
    }
    
    func reloadCalendar(date: Date?) {
        guard let date = date else { return }
        let calendar = Calendar.current
        calendarView.reloadDecorations(forDateComponents: [calendar.dateComponents([.day, .month, .year, .hour, .minute], from: date)], animated: true)
    }
        
    @IBAction func onClickClose(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
    @IBAction func onClickApply(_ sender: Any) {
        guard let date = date else {
            Alert("ERROR".localized(), "Must Select Date", nil)
            return
        }
        let dict : [String: Date] = ["date": date]
        NotificationCenter.default.post(name: AppNotification.changeDate , object: nil, userInfo: dict)
        self.dismiss(animated: true)
    }
}

extension MinuteCalendar: UICalendarViewDelegate, UICalendarSelectionSingleDateDelegate {
    
    func dateSelection(_ selection: UICalendarSelectionSingleDate, didSelectDate dateComponents: DateComponents?) {
        selection.setSelected(dateComponents, animated: true)
        selectedDate = dateComponents
        date = dateComponents?.date
        reloadCalendar(date: Calendar.current.date(from: dateComponents!))
    }
    
    func calendarView(_ calendarView: UICalendarView, decorationFor dateComponents: DateComponents) -> UICalendarView.Decoration? {
        let date = dateComponents.date!
        return nil
    }
}
