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
    
    func fetchProducts(purchaseType: PurchaseType, completion: @escaping ([SKProduct]?, Error?) -> Void) {
        let products = getProductIDsFromBundle(purchaseType: purchaseType)
        productRequest = EasyPurchase.fetchProducts(Set(products!)) { productInfo in
            if productInfo.error != nil {
                completion(nil, productInfo.error)
            } else {
                if let retrievedProducts = productInfo.retrievedProducts {
                    completion(Array(retrievedProducts), nil)
                } else {
                    // invalidProductIDs
                }
            }
        }
        productRequest?.start()
    }
    
    func purchaseProducts(purchaseType: PurchaseType, product: SKProduct, completion: @escaping (PurchaseResult) -> Void) {
        var quantity: Int = 1
        if purchaseType == .consumable {
            quantity = 2
        }
        
        EasyPurchase.purchaseProduct(purchaseType, product: product, quantity: quantity) { purchaseResult in
            switch purchaseResult {
            case .success(let purchase):
                completion(.success(purchase: purchase))
            case .failure(let error):
                completion(.failure(error: error))
            }
        }
    }
    
    func restoreProducts(completion: @escaping ([RestoreProductsResults]) -> Void) {
        EasyPurchase.restorePurchases(atomically: true) { results in
            var successResults: [Purchase] = []
            var failureResults: [(SKError, String?)] = []
            
            for purchase in results.restoredProductsSuccess {
                successResults.append(purchase)
            }
            
            for errorTuple in results.restoredProductsFailure {
                failureResults.append(errorTuple)
            }

            let restoreResults = [RestoreProductsResults(restoredPurchases: successResults, restoreFailedPurchases: failureResults)]
            completion(restoreResults)
        }
    }
}
