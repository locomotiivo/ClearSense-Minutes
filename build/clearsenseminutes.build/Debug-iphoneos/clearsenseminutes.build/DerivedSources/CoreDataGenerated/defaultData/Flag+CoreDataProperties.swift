//
//  Flag+CoreDataProperties.swift
//  
//
//  Created by KooBH on 2024. 12. 8..
//
//  This file was automatically generated and should not be edited.
//

import Foundation
import CoreData


extension Flag {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Flag> {
        return NSFetchRequest<Flag>(entityName: "Flag")
    }

    @NSManaged public var agc: Bool
    @NSManaged public var bypass: Bool
    @NSManaged public var lan: String?
    @NSManaged public var raw: Bool
    @NSManaged public var record: Bool
    @NSManaged public var spatial: Bool
    @NSManaged public var versionStr: String?

}

extension Flag : Identifiable {

}
