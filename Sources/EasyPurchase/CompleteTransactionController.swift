//
//  CompleteTransactionController.swift
//  
//
//  Created by Sadat Ahmed on 11.10.2023.
//

import Foundation
import StoreKit

/// MARK: - CALLBACK OF `CompleteTransactionController`
struct ProcessedTransactions {
    var completion: ([Purchase]) -> Void
    
    init(completion: @escaping ([Purchase]) -> Void) {
        self.completion = completion
    }
}

/// Payment transaction
public protocol PaymentTransaction {
    var transactionState: SKPaymentTransactionState { get }
    var transactionIdentifier: String? { get }
}

public class CompleteTransactionController: TransactionController {
    // MARK: - PROPERTIES
    var processedTransactions: ProcessedTransactions?
    var purchases: [Purchase] = []
    var rawTransactions: [SKPaymentTransaction] = []
    
    public func processTransactions(_ transactions: [SKPaymentTransaction], on paymentQueue: InAppPaymentQueue) -> [SKPaymentTransaction] {
        guard let processedTransactions = processedTransactions else {
            print(transactions)
            return transactions
        }
        for transaction in transactions {
            let transactionState = transaction.transactionState
            if transactionState != .purchasing {
                let willFinishTransaction = transactionState == .failed
                let purchase = Purchase(productId: transaction.payment.productIdentifier, quantity: transaction.payment.quantity, product: nil, transaction: transaction, originalTransaction: transaction.original, needsFinishTransaction: !willFinishTransaction)
                purchases.append(purchase)
                
                if willFinishTransaction {
                    paymentQueue.finishTransaction(transaction)
                }
            } else {
                rawTransactions.append(transaction)
            }
        }
        
        if !purchases.isEmpty {
            processedTransactions.completion(purchases)
        }
        return rawTransactions
    }
}
