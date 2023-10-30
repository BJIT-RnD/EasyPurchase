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

public class IAPManager: NSObject {
    public static let shared = IAPManager()
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

        do {
            try paymentQueueController.startPayment(Payment(product: product, quantity: quantity, needToDownloadContent: true) { result in

                completion(self.processPurchaseResult(result))
            })
        }
        catch let error as NSError {
            // Handle the error and access error information
            print("Payment failed with error: \(error.localizedDescription)")
            print("Error code: \(error.code)")
            print("Error domain: \(error.domain)")
        }
        catch {
            // handle other errors here
        }
    }
    private func processPurchaseResult(_ result: PurchaseResult) -> PurchaseResult {
        switch result {
        case .success(purchase: let purchase):
            return .success(purchase: purchase)
        case .failure(error: let error):
            return .failure(error: error)
        }
    }
    private func processRestoreResults(_ results: [InAppTransactionActionsResult]) -> RestoreProductsResults {
        var restoredPurchases: [Purchase] = []
        var restoreFailedPurchases: [(SKError, String?)] = []
        for result in results {
            switch result {
            case .purchased(let purchase):
                let error = PurchaseViewController().storeInternalError(description: "Cannot purchase product from restore purchases path")
            case .deferred(let purchase):
                let error = PurchaseViewController().storeInternalError(description: "Cannot purchase product from restore purchases path")
                //restoreFailedPurchases.append((error, purchase.productId))
            case .failed(let error):
                restoreFailedPurchases.append((error, nil))
            case .restored(let purchase):
                restoredPurchases.append(purchase)
            }
        }
        return RestoreProductsResults(restoredPurchases: restoredPurchases, restoreFailedPurchases: restoreFailedPurchases)
    }    
}
