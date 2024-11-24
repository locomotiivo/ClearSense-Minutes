//
//  IAPManager.swift
//  clearsenseminutes
//
//  Created by KooBH on 1/26/24.
//

import Foundation
import StoreKit
import OSLog

public typealias ProductsRequestCompletion = (_ success: Bool, _ products: [SKProduct]?) -> Void

final class IAPManager: NSObject {
    var canMakePayments: Bool {
        SKPaymentQueue.canMakePayments()
    }
    
    private let productIDs: Set<String>
    private var purchasedProductIDs: Set<String>
    private var productsRequest: SKProductsRequest?
    private var productsCompletion: ProductsRequestCompletion?
    private var processedTransactionIDs: Set<String> = Set()
    
    init(productIDs: Set<String>) {
        self.productIDs = productIDs
        self.purchasedProductIDs = productIDs.filter {
            UserDefaults.standard.bool(forKey: $0) == true
        }
        
        super.init()
        SKPaymentQueue.default().add(self)
    }
    
    func getProducts(completion: @escaping ProductsRequestCompletion) {
        self.productsRequest?.cancel()
        self.productsCompletion = completion
        self.productsRequest = SKProductsRequest(productIdentifiers: productIDs)
        self.productsRequest?.delegate = self
        self.productsRequest?.start()
    }
}

extension IAPManager {
    func buyProduct(_ product: SKProduct) {
        SKPaymentQueue.default().add(SKPayment(product: product))
    }
    
    func isProductPurchased(_ productID: String) -> Bool {
        self.purchasedProductIDs.contains(productID)
    }
    
    func getReceiptData() -> String? {
        if let receiptURL = Bundle.main.appStoreReceiptURL,
           FileManager.default.fileExists(atPath: receiptURL.path) {
            do {
                let receiptData = try Data(contentsOf: receiptURL, options: .alwaysMapped)
                let receiptStr = receiptData.base64EncodedString(options: [])
                return receiptStr
            } catch {
                let message = "Couldn't read receipt data: \(error.localizedDescription)"
                os_log(.error, log: .paywall, "%@", message)
                return nil
            }
        } else {
            return nil
        }
    }
    
    func restorePurchases() {
        SKPaymentQueue.default().restoreCompletedTransactions()
    }

}

extension IAPManager: SKProductsRequestDelegate {
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        let products = response.products
        self.productsCompletion?(true, products)
        self.clear()
        
        products.forEach {
            let message = "Found : \($0.productIdentifier) \($0.localizedTitle) \($0.price.floatValue)"
            os_log(.info, log: .paywall, "%@", message)
        }
    }
    
    func request(_ request: SKRequest, didFailWithError error: Error) {
        let message = "Error while Purchasing: \(error.localizedDescription)"
        os_log(.error, log: .paywall, "%@", message)
        self.productsCompletion?(false, nil)
        self.clear()
    }
    
    private func clear() {
        self.productsRequest = nil
        self.productsCompletion = nil
    }
}

extension IAPManager: SKPaymentTransactionObserver {
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        transactions.forEach {
            switch $0.transactionState {
            case .purchasing:
                os_log(.error, log: .paywall, "Customer is Purchasing...")
                
            case .purchased:
                os_log(.error, log: .paywall, "Finished Purchase!")
                
                let productID = $0.payment.productIdentifier
                let transactionID = $0.transactionIdentifier
                
                self.deliverPurchaseNotification(state: 0, message: "", id: productID, transaction: $0)
                SKPaymentQueue.default().finishTransaction($0)
            case .failed:
                if let transactionErr = $0.error as NSError?,
                   let description = $0.error?.localizedDescription,
                   transactionErr.code != SKError.paymentCancelled.rawValue {

                    let message = "Transaction Error: \(description)"
                    os_log(.error, log: .paywall, "%@", message)
                    
                    self.deliverPurchaseNotification(state: 1, message: description, id: nil, transaction: $0)
                }
                SKPaymentQueue.default().finishTransaction($0)
            case .restored:
                os_log(.error, log: .paywall, "Restored")
                
                self.deliverPurchaseNotification(state: 2, message: "", id: $0.original?.payment.productIdentifier, transaction: $0)
                SKPaymentQueue.default().finishTransaction($0)
            case .deferred:
                os_log(.error, log: .paywall, "Deferred")
            default:
                if let transactionErr = $0.error as NSError?,
                   let description = $0.error?.localizedDescription,
                   transactionErr.code != SKError.paymentCancelled.rawValue {
                    let message = "Unexpected Error: \(description)"
                    os_log(.error, log: .paywall, "%@", message)
                }
                
                self.deliverPurchaseNotification(state: -1, message: "", id: $0.original?.payment.productIdentifier, transaction: $0)
            }
        }
    }
    
    private func deliverPurchaseNotification(state: Int, message: String, id: String?, transaction: SKPaymentTransaction) {
//        guard let id = id else {

        //            return
//        }
        
        let transactionID = transaction.transactionIdentifier ?? ""
        
        if !processedTransactionIDs.contains(transactionID) {
            if let id = id {
                processedTransactionIDs.insert(transactionID)
                self.purchasedProductIDs.insert(id)
                UserDefaults.standard.set(true, forKey: id)
            }
            
            NotificationCenter.default.post(
                name: .iapServicePurchaseNotification,
                object: ["state": state, "message": message, "id": id ?? ""],
                userInfo: ["transactionID": transactionID]
            )
        }
    }
}

extension Notification.Name {
    static let iapServicePurchaseNotification = Notification.Name("IAPServicePurchaseNotification")
}
