//
//  File.swift
//  clearsenseminutes
//
//  Created by greenthings on 7/30/24.
//

import Foundation


final class Minute{
    
    var id : String
    var title : String
    var text : String
    var company : String
    var date : Date
    var idx : Int
    
    init(id: String, title: String, company: String, text: String, date: Date, idx: Int?) {
        self.id = id
        self.title = title
        self.company = company
        self.text = text
        self.date = date
        self.idx = idx ?? -1
    }
}

extension Minute: Hashable {
    static func == (lhs: Minute, rhs: Minute) -> Bool {
        return lhs.id == rhs.id && lhs.title == rhs.title && lhs.company == rhs.company && lhs.text == rhs.text && lhs.date == rhs.date && lhs.idx == rhs.idx
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(title)
        hasher.combine(company)
        hasher.combine(text)
        hasher.combine(date)
        hasher.combine(idx)
    }
    
}
