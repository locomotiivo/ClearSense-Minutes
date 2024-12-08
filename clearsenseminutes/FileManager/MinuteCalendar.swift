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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        calendarView.delegate = self
        
        view.addSubview(calendarView)
        
        calendarView.delegate = self
        let dateSelection = UICalendarSelectionSingleDate(delegate: self)
        calendarView.selectionBehavior = dateSelection
        
        let calendarViewConstraints = [
            calendarView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            calendarView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            calendarView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor )
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
        guard let date = date else {
            Alert("ERROR".localized(), "Must Select Date", nil)
            return
        }
        
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
