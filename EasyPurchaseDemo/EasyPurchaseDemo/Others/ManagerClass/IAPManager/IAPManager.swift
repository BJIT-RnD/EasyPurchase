//
//  IAPManager.swift
//  EasyPurchaseDemo
//
//  Created by rex on 29/9/23.
//

import Foundation
import UIKit
import EasyPurchase
import StoreKit

// MARK: - Custom Types
enum IAPManagerError: Error {
    case noProductIDsFound
    case noProductsFound
    case paymentWasCancelled
    case productRequestFailed
}

enum PurchaseType {
    case autoRenewable
    case nonRenewable
    case consumable
    case nonConsumable
}

class IAPManager: NSObject {
    static let shared = IAPManager()
    private override init() { super.init() }
    
//    var productRequest:InAppProductRequest!
//    let productInfoController = ProductInfoController()
//    let paymentQueueController = PaymentQueueController()
//    let restoreProductsController = RestoreProductsController()

    private func getProductIDsByType(purchaseType: PurchaseType) -> String {
        switch purchaseType {
        case .autoRenewable:
            return KAutoRenewable
        case .nonRenewable:
            return KNonRenewable
        case .consumable:
            return KConsumable
        case .nonConsumable:
            return KNonConsumable
        }
    }
    
    func getProductIDsFromBundle(purchaseType: PurchaseType) -> [String]? {
        let resourceURL: String = getProductIDsByType(purchaseType: purchaseType)
        guard let url = Bundle.main.url(forResource: resourceURL, withExtension: "plist") else { return nil }
        do {
            let data = try Data(contentsOf: url)
            let productIDs = try PropertyListSerialization.propertyList(from: data, options: .mutableContainersAndLeaves, format: nil) as? [String] ?? []
            return productIDs
        } catch {
            print("\(error.localizedDescription)")
            return nil
        }
    }
    
//    func getProducts(purchaseType: PurchaseType, completion: @escaping ([SKProduct]?, Error?) -> Void) {
//        let products = getProductIDsFromBundle(purchaseType: purchaseType)
//        self.productRequest = productInfoController.fetchProductsInfo(Set(products!)) { productInfo in
//            if productInfo.error != nil {
//                completion(nil, productInfo.error)
//            } else {
//                if let retrievedProducts = productInfo.retrievedProducts {
//                    completion(Array(retrievedProducts), nil)
//                } else {
//                    
//                }
//            }
//        }
//        self.productRequest.start()
//    }
    
//    func purchaseProduct(purchaseType: PurchaseType, product: SKProduct, completion: @escaping (PurchaseResult) -> Void) {
//        var quantity: Int = 1
//        if purchaseType == .consumable {
//            quantity = 2
//        }
//        
//        let payment = Payment(product: product, quantity: quantity, needToDownloadContent: true) { result in
//            completion(result)
//        }
//        paymentQueueController.startPayment(payment)
//    }
    
//    func restorePurchase() {
//        // Check if the restoration process is already in progress
//        if restoreProductsController.restoreProducts != nil {
//            // Handle this case if needed (e.g., show an alert to inform the user)
//            return
//        }
//
//        // Configure the restoration process using the RestoreProducts struct
//        let restoreProducts = RestoreProducts(atomically: true, applicationUsername: nil) { [weak self] restoredProducts in
//            // Handle the results of the restoration process here
//            if restoredProducts.isEmpty {
//                // Handle the case where no purchases were restored
//                print("No purchases were restored.")
//            } else {
//                // Handle the restored purchases
//                for result in restoredProducts {
//                    switch result {
//                    case .restored(let purchase):
//                        // Handle the restored purchase (e.g., unlock content)
//                        print("Restored purchase: \(purchase.productId)")
//                    case .failed(let error):
//                        // Handle the failed restoration (e.g., show an alert with error details)
//                        print("Failed to restore purchase with error: \(error)")
//                    default:
//                        break
//                    }
//                }
//            }
//
//            // Reset the controller's state after handling the results
//            self?.restoreProductsController.restoreCompletedTransactionsFinished()
//        }
//
//        // Start the restoration process
//        restoreProductsController.restorePurchases(restoreProducts)
//    }
    
}
