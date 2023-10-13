//
//  RestorePurchasesController.swift
//  
//
//  Created by BJIT on 12/10/23.
//

import Foundation
import StoreKit

/// Struct to configure and handle restore purchases operation.
public struct RestorePurchases {
    let atomically: Bool
    let applicationUsername: String?
    let callback: ([InAppTransactionActionsResult]) -> Void

    /// Initialize RestorePurchases with the specified parameters.
    /// - Parameters:
    ///   - atomically: A flag indicating whether purchases should be restored atomically.
    ///   - applicationUsername: An optional application-specific username.
    ///   - callback: A closure to handle the results of the restore operation.
    public init(atomically: Bool, applicationUsername: String? = nil, callback: @escaping ([InAppTransactionActionsResult]) -> Void) {
        self.atomically = atomically
        self.applicationUsername = applicationUsername
        self.callback = callback
    }
}

/// Struct to hold the results of a restore operation.
public struct RestoreResults {
    public let restoredPurchases: [Purchase]
    public let restoreFailedPurchases: [(SKError, String?)]

    /// Initialize RestoreResults with restored and failed purchase results.
    public init(restoredPurchases: [Purchase], restoreFailedPurchases: [(SKError, String?)]) {
        self.restoredPurchases = restoredPurchases
        self.restoreFailedPurchases = restoreFailedPurchases
    }
}

/// A class to manage restoring purchases and handle the related transactions.
public class RestorePurchasesController: TransactionController {
    public var restorePurchases: RestorePurchases?
    private var restoredPurchases: [InAppTransactionActionsResult] = []

    /// Initialize the RestorePurchasesController.
    public init() { }

    /// Process a transaction for restore purchases.
    /// - Parameters:
    ///   - transaction: The transaction to process.
    ///   - atomically: A flag indicating whether the purchase should be restored atomically.
    ///   - paymentQueue: The payment queue responsible for transactions.
    /// - Returns: A Purchase object if the transaction is successfully processed, otherwise nil.
    func processTransaction(_ transaction: SKPaymentTransaction, atomically: Bool, on paymentQueue: InAppPaymentQueue) -> Purchase? {
        let transactionState = transaction.transactionState

        if transactionState == .restored {
            let transactionProductIdentifier = transaction.payment.productIdentifier
            let purchase = Purchase(
                productId: transactionProductIdentifier,
                quantity: transaction.payment.quantity,
                product: nil, // Product information is not available during restore
                transaction: transaction,
                originalTransaction: transaction.original,
                needsFinishTransaction: !atomically
            )
            if atomically {
                paymentQueue.finishTransaction(transaction)
            }
            return purchase
        }
        return nil
    }

    /// Process an array of transactions for restore purchases.
    /// - Parameters:
    ///   - transactions: An array of transactions to process.
    ///   - paymentQueue: The payment queue responsible for transactions.
    /// - Returns: An array of unhandled transactions.
    public func processTransactions(_ transactions: [SKPaymentTransaction], on paymentQueue: InAppPaymentQueue) -> [SKPaymentTransaction] {
        guard let restorePurchases = restorePurchases else {
            return transactions
        }

        var unhandledTransactions: [SKPaymentTransaction] = []
        for transaction in transactions {
            if let restoredPurchase = processTransaction(transaction, atomically: restorePurchases.atomically, on: paymentQueue) {
                restoredPurchases.append(.restored(purchase: restoredPurchase))
            } else {
                unhandledTransactions.append(transaction)
            }
        }

        return unhandledTransactions
    }

    /// Handle the case where restore completed transactions failed.
    func restoreCompletedTransactionsFailed(withError error: Error) {
        guard let restorePurchases = restorePurchases else {
            return
        }
        restoredPurchases.append(.failed(error: SKError(_nsError: error as NSError)))
        restorePurchases.callback(restoredPurchases)

        // Reset the controller's state after an error
        restoredPurchases = []
        self.resetRestorePurchasesToNil()
    }

    /// Handle the case where restore completed transactions finished successfully.
    func restoreCompletedTransactionsFinished() {
        guard let restorePurchases = restorePurchases else {
            return
        }
        restorePurchases.callback(restoredPurchases)

        // Reset the controller's state after successful completion
        restoredPurchases = []
        self.resetRestorePurchasesToNil()
    }

    // Reset the controller's state after successful completion
    func resetRestorePurchasesToNil() {
        self.restorePurchases = nil
    }
}
