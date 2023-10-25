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
    
    var productRequest:InAppProductRequest!
    let productInfoController = ProductInfoController()
    let paymentQueueController = PaymentQueueController()
    let restoreProductsController = RestoreProductsController()

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
    
    func getProducts(purchaseType: PurchaseType, completion: @escaping ([SKProduct]?, Error?) -> Void) {
        let products = getProductIDsFromBundle(purchaseType: purchaseType)
        self.productRequest = productInfoController.fetchProductsInfo(Set(products!)) { productInfo in
            if productInfo.error != nil {
                completion(nil, productInfo.error)
            } else {
                if let retrievedProducts = productInfo.retrievedProducts {
                    completion(Array(retrievedProducts), nil)
                } else {
                    
                }
            }
        }
        self.productRequest.start()
    }
    
    func purchaseProduct(purchaseType: PurchaseType, product: SKProduct, completion: @escaping (PurchaseResult) -> Void) {
        var quantity: Int = 1
        if purchaseType == .consumable {
            quantity = 2
        }
        
        let payment = Payment(product: product, quantity: quantity, needToDownloadContent: true) { result in
            completion(result)
        }
        
        do {
            try paymentQueueController.startPayment(payment)
        } catch {
            print("Error: \(error)")
        }
    }
    
    func restorePurchases(completion: @escaping ([Purchase], [SKError]) -> Void) {
        let restoreConfig = RestoreProducts(atomically: true) { results in
            var restoredPurchases: [Purchase] = []
            var restoreErrors: [SKError] = []

            for result in results {
                switch result {
                case .restored(let purchase):
                    print("YES")
                    restoredPurchases.append(purchase)
                case .failed(let error):
                    print("NO")
                    restoreErrors.append(error)
                default:
                    break
                }
            }
            completion(restoredPurchases, restoreErrors)
        }
        paymentQueueController.restorePurchases(restoreConfig)
    }
}
