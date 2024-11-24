//
//  Products.swift
//  clearsenseminutes
//
//  Created by KooBH on 2/13/24.
//

import Foundation

enum Products {
    static var IAPService : IAPManager = IAPManager(
        productIDs: Set<String>(["clearsenseminutes.subscription.month", "clearsenseminutes.subscription.year"])
    )
    static func getResourceProductName(_ id: String) -> String? {
        id.components(separatedBy: ".").last
    }
}
