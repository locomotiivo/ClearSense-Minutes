//
//  Eq+CoreDataProperties.swift
//  
//
//  Created by KooBH on 2024. 12. 8..
//
//  This file was automatically generated and should not be edited.
//

import Foundation
import CoreData


extension Eq {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Eq> {
        return NSFetchRequest<Eq>(entityName: "Eq")
    }

    @NSManaged public var eq_amp: Double
    @NSManaged public var eq_l0: Double
    @NSManaged public var eq_l1: Double
    @NSManaged public var eq_l2: Double
    @NSManaged public var eq_l3: Double
    @NSManaged public var eq_l4: Double
    @NSManaged public var eq_l5: Double
    @NSManaged public var eq_l6: Double
    @NSManaged public var eq_l7: Double
    @NSManaged public var eq_r0: Double
    @NSManaged public var eq_r1: Double
    @NSManaged public var eq_r2: Double
    @NSManaged public var eq_r3: Double
    @NSManaged public var eq_r4: Double
    @NSManaged public var eq_r5: Double
    @NSManaged public var eq_r6: Double
    @NSManaged public var eq_r7: Double
    @NSManaged public var noiseFloor: Double
    @NSManaged public var on: Bool

}

extension Eq : Identifiable {

}
