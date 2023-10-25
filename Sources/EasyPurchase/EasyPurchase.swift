//
//  InterfaceDemo.swift
//  EasyPurchaseDemo
//
//  Created by BJIT on 25/10/23.
//

import Foundation
import StoreKit

/// An enum representing different types of purchases.
public enum PurchaseType {
    case autoRenewable
    case nonRenewable
    case consumable
    case nonConsumable
}

/// A class responsible for managing in-app purchases.
public class EasyPurchase {
    private let productsInfoController: ProductInfoController
    fileprivate let paymentQueueController: PaymentQueueController

    /// Initialize the EasyPurchase instance with default controllers.
    /// - Parameters:
    ///   - productsInfoController: The product info controller.
    ///   - paymentQueueController: The payment queue controller.
    init(productsInfoController: ProductInfoController = ProductInfoController(),
         paymentQueueController: PaymentQueueController = PaymentQueueController(paymentQueue: SKPaymentQueue.default())) {
        self.productsInfoController = productsInfoController
        self.paymentQueueController = paymentQueueController
    }

    /// Retrieve product information.
    /// - Parameters:
    ///   - productIds: Set of product identifiers.
    ///   - completion: A closure to handle the retrieved product information.
    /// - Returns: An in-app product request.
    fileprivate func fetchProducts(_ productIds: Set<String>, completion: @escaping (InAppProduct) -> Void) -> InAppProductRequest {
        return productsInfoController.fetchProductsInfo(productIds, completion: completion)
    }

    /// Initiate a purchase.
    /// - Parameters:
    ///   - purchaseType: Type of purchase.
    ///   - product: The product to purchase.
    ///   - quantity: The quantity to purchase.
    ///   - completion: A closure to handle the purchase result.
    fileprivate func purchase(purchaseType: PurchaseType, product: SKProduct, quantity: Int, completion: @escaping (PurchaseResult) -> Void) {
        do {
            try paymentQueueController.startPayment(Payment(product: product, quantity: quantity, needToDownloadContent: true) { result in
                completion(self.processPurchaseResult(result))
            })
        } catch let error as NSError {
            // Handle the error and access error information
            print("Payment failed with error: \(error.localizedDescription)")
            print("Error code: \(error.code)")
            print("Error domain: \(error.domain)")
        } catch {
            // Handle other errors here
        }
    }

    /// Process a purchase result.
    ///
    /// - Parameter result: The purchase result to process.
    /// - Returns: The processed purchase result.
    private func processPurchaseResult(_ result: PurchaseResult) -> PurchaseResult {
        switch result {
        case .success(purchase: let purchase):
            return .success(purchase: purchase)
        case .failure(error: let error):
            return .failure(error: error)
        }
    }

    /// Finish a payment transaction.
    /// - Parameter transaction: The payment transaction to finish.
    fileprivate func finishTransaction(_ transaction: PaymentTransaction) {
        paymentQueueController.finishTransaction(transaction)
    }

    /// Process results of restoring purchases.
    /// - Parameter results: An array of InAppTransactionActionsResult.
    /// - Returns: Processed restore products results.
    private func processRestoreResults(_ results: [InAppTransactionActionsResult]) -> RestoreProductsResults {
        var restoredPurchases: [Purchase] = []
        var restoreFailedPurchases: [(SKError, String?)] = []
        for result in results {
            switch result {
            case .purchased(let purchase):
                let error = storeInternalError(description: "Cannot purchase product \(purchase.productId) from restore purchases path")
                restoreFailedPurchases.append((error, purchase.productId))
            case .deferred(let purchase):
                let error = storeInternalError(description: "Cannot purchase product \(purchase.productId) from restore purchases path")
                restoreFailedPurchases.append((error, purchase.productId))
            case .failed(let error):
                restoreFailedPurchases.append((error, nil))
            case .restored(let purchase):
                restoredPurchases.append(purchase)
            }
        }
        return RestoreProductsResults(restoredPurchases: restoredPurchases, restoreFailedPurchases: restoreFailedPurchases)
    }

    /// Create an internal SKError with a specified code and description.
    /// - Parameters:
    ///   - code: The SKError code.
    ///   - description: The description for the error.
    /// - Returns: An SKError instance.
    private func storeInternalError(code: SKError.Code = SKError.unknown, description: String = "") -> SKError {
        let error = NSError(domain: SKErrorDomain, code: code.rawValue, userInfo: [NSLocalizedDescriptionKey: description])
        return SKError(_nsError: error)
    }

    /// Complete transactions.
    /// - Parameters:
    ///   - atomically: A boolean indicating whether to complete transactions atomically.
    ///   - completion: A closure to handle completed purchases.
    fileprivate func completeTransactions(atomically: Bool = true, completion: @escaping ([Purchase]) -> Void) {
        paymentQueueController.completeTransactions(ProcessedTransactions(atomically: atomically, completion: completion))
    }
}

extension EasyPurchase {
    /// A shared instance of EasyPurchase.
    fileprivate static let sharedInstance = EasyPurchase()

    /// Check if making payments is available.
    public class var canMakePayments: Bool {
        return SKPaymentQueue.canMakePayments()
    }

    /// Retrieve product information.
    /// - Parameters:
    ///   - productIds: Set of product identifiers.
    ///   - completion: A closure to handle the retrieved product information.
    /// - Returns: An in-app product request.
    public class func fetchProducts(_ productIds: Set<String>, completion: @escaping (InAppProduct) -> Void) -> InAppProductRequest {
        return sharedInstance.productsInfoController.fetchProductsInfo(productIds, completion: completion)
    }

    /// Purchase a product.
    /// - Parameters:
    ///   - purchaseType: Type of purchase.
    ///   - product: The product to purchase.
    ///   - quantity: The quantity to purchase.
    ///   - completion: A closure to handle the purchase result.
    public class func purchaseProduct(_ purchaseType: PurchaseType, product: SKProduct, quantity: Int, completion: @escaping (PurchaseResult) -> Void) {
        sharedInstance.purchase(purchaseType: purchaseType, product: product, quantity: quantity, completion: completion)
    }

    /// Restore products.
    /// - Parameters:
    ///   - atomically: A boolean indicating whether to restore products atomically.
    ///   - applicationUsername: An optional application username.
    ///   - completion: A closure to handle the restored products results.
    public func restoreProducts(atomically: Bool = true, applicationUsername: String = "", completion: @escaping (RestoreProductsResults) -> Void) {
        paymentQueueController.restorePurchases(RestoreProducts(atomically: atomically, applicationUsername: applicationUsername) { results in
            let results = self.processRestoreResults(results)
            completion(results)
        })
    }

    /// Complete transactions.
    /// - Parameters:
    ///   - atomically: A boolean indicating whether to complete transactions atomically.
    ///   - completion: A closure to handle completed purchases.
    public class func completeTransactions(atomically: Bool = true, completion: @escaping ([Purchase]) -> Void) {
        sharedInstance.completeTransactions(atomically: atomically, completion: completion)
    }

    /// Finish a payment transaction.
    /// - Parameter transaction: The payment transaction to finish.
    public class func finishTransaction(_ transaction: PaymentTransaction) {
        sharedInstance.finishTransaction(transaction)
    }
}
