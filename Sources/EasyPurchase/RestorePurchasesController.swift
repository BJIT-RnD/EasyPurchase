//
//  File.swift
//  
//
//  Created by BJIT on 12/10/23.
//

import Foundation
import StoreKit

// Model for restored product details
struct RestoreProductDetails {
    let productId: String
    let quantity: Int
    let transaction: SKPaymentTransaction
    let originalTransaction: SKPaymentTransaction?
    let needsFinishTransaction: Bool
}
//callback for restore results
struct RestorePurchases {
    let callback: ([RestorePurchaseResult]) -> Void
}

// Model for the result of a restore purchase
enum RestorePurchaseResult {
    case success(restoreProductDetails: RestoreProductDetails)
    case failure(error: SKError)
}

// Protocol defining transaction handling methods for restore.
protocol RestoreTransactionController {
    func processRestoreTransactions(_ transactions: [SKPaymentTransaction], on paymentQueue: InAppPaymentQueue) -> [SKPaymentTransaction]
}

final class RestorePurchaseController: NSObject, RestoreTransactionController {
    var restorePurchases: RestorePurchases?
    private var restoredPurchases: [RestoreProductDetails] = []
    private var restoreFailedPurchases: [(SKError, String?)] = []

    func processRestoreTransactions(_ transactions: [SKPaymentTransaction], on paymentQueue: InAppPaymentQueue) -> [SKPaymentTransaction] {
        var unhandledTransactions: [SKPaymentTransaction] = []

        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased, .restored:
                if let productDetails = processRestoreTransaction(transaction) {
                    restoredPurchases.append(productDetails)
                    // Handle the successful restore result using RestorePurchaseResult
                    let result = RestorePurchaseResult.success(restoreProductDetails: productDetails)
                    handleRestoreResult(result)
                }
                // Finish the transaction
                paymentQueue.finishTransaction(transaction)
            case .failed:
                if let skError = transaction.error as? SKError {
                    restoreFailedPurchases.append((skError, transaction.payment.productIdentifier))
                    // Handle the restore failure result using RestorePurchaseResult
                    let result = RestorePurchaseResult.failure(error: skError)
                    handleRestoreResult(result)
                } else {
                    let defaultError = SKError(_nsError: NSError(domain: SKErrorDomain, code: 0, userInfo: nil))
                    restoreFailedPurchases.append((defaultError, transaction.payment.productIdentifier))
                    let result = RestorePurchaseResult.failure(error: defaultError)
                    handleRestoreResult(result)
                }
                paymentQueue.finishTransaction(transaction)
            default:
                unhandledTransactions.append(transaction)
            }
        }

        return unhandledTransactions
    }

    private func processRestoreTransaction(_ transaction: SKPaymentTransaction) -> RestoreProductDetails? {
        if transaction.transactionState == .restored {
            // Implement your logic to create RestoreProductDetails
            let productDetails = RestoreProductDetails(
                productId: transaction.payment.productIdentifier,
                quantity: transaction.payment.quantity,
                transaction: transaction,
                originalTransaction: transaction.original,
                needsFinishTransaction: false
            )
            return productDetails
        }
        return nil
    }

    private func handleRestoreResult(_ result: RestorePurchaseResult) {
        switch result {
        case .success(let restoreProductDetails):
            // Handle the successful restore result
            print("Restored product: \(restoreProductDetails.productId)")
        case .failure(let error):
            // Handle the restore failure result
            print("Restore failed with error: \(error)")
        }
    }
}
