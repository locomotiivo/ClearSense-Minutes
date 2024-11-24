//
//  File.swift
//  clearsenseminutes
//
//  Created by greenthings on 7/30/24.
//

import Foundation


final class File{
    
    var fileTitle : String
    var fileDuration : String
    var fileDate : Date
    var idx : Int
    
    init(title: String, duration: String, date: Date, idx: Int?) {
        self.fileTitle = title
        self.fileDuration = duration
        self.fileDate = date
        self.idx = idx ?? -1
    }
}

extension File: Hashable {
    static func == (lhs: File, rhs: File) -> Bool {
        return lhs.fileTitle == rhs.fileTitle && lhs.fileDuration == rhs.fileDuration && lhs.fileDate == rhs.fileDate && lhs.idx == rhs.idx
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(fileTitle)
        hasher.combine(fileDuration)
        hasher.combine(fileDate)
        hasher.combine(idx)
    }
    
}
