//
//  CompleteTransactionController.swift
//  
//
//  Created by Sadat Ahmed on 11.10.2023.
//

import Foundation
import StoreKit

// MARK: - ProcessedTransactions

/// A struct that encapsulates a completion closure for processed transactions.
struct ProcessedTransactions {
    var completion: ([Purchase]) -> Void
    
    init(completion: @escaping ([Purchase]) -> Void) {
        self.completion = completion
    }
}

/// Payment transaction protocol
public protocol PaymentTransaction {
    var transactionState: SKPaymentTransactionState { get }
    var transactionIdentifier: String? { get }
}

/// A class representing a complete transaction controller.
public class CompleteTransactionController: TransactionController {
    // MARK: - PROPERTIES
    var processedTransactions: ProcessedTransactions?
    var purchases: [Purchase] = []
    var rawTransactions: [SKPaymentTransaction] = []

    /// Process an array of payment transactions.
    /// - Parameters:
    ///   - transactions: An array of `SKPaymentTransaction` to be processed.
    ///   - paymentQueue: An `InAppPaymentQueue` instance.
    /// - Returns: An array of `SKPaymentTransaction` representing unprocessed transactions.
    public func processTransactions(_ transactions: [SKPaymentTransaction], on paymentQueue: InAppPaymentQueue) -> [SKPaymentTransaction] {
        /// Check if processedTransactions is set; if not, log the provided transactions and return them as unprocessed.
        guard let processedTransactions = processedTransactions else {
            print(transactions)
            return transactions
        }
        for transaction in transactions {
            let transactionState = transaction.transactionState
            if transactionState != .purchasing {
                let willFinishTransaction = transactionState == .failed
                // Create a Purchase object with transaction details.
                let purchase = Purchase(productId: transaction.payment.productIdentifier, quantity: transaction.payment.quantity, product: nil, transaction: transaction, originalTransaction: transaction.original, needsFinishTransaction: !willFinishTransaction)
                // Append the purchase to the purchases array.
                purchases.append(purchase)
                
                if willFinishTransaction {
                    // Finish the transaction if it failed.
                    paymentQueue.finishTransaction(transaction)
                }
            } else {
                // Add the transaction to the rawTransactions array if it's still in the purchasing state.
                rawTransactions.append(transaction)
            }
        }

        // If there are purchases, call the completion closure with the purchased items.
        if !purchases.isEmpty {
            processedTransactions.completion(purchases)
        }
        // Return the raw (unprocessed) transactions.
        return rawTransactions
    }
}
