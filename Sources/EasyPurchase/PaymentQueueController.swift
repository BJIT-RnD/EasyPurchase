//
//  PaymentQueueController.swift
//  EasyPurchase
//
//  Created by Sadat Ahmed on 20.09.2023.
//

import Foundation
import StoreKit

// Protocol for a payment queue
protocol PaymentQueue {
    func add(_ payment: SKPayment)
}

// Define the PaymentQueueDelegate protocol for handling payment queue events
protocol PaymentQueueDelegate: AnyObject {
    func handleTransactionSuccess(for productIdentifier: String)
    func handleTransactionFailure(for productIdentifier: String, with error: Error?)
    func processTransactions(_ transactions: [SKPaymentTransaction], on paymentQueue: PaymentQueue) -> [SKPaymentTransaction]
}

// PaymentQueueController class responsible for managing the payment queue
class PaymentQueueController: NSObject, PaymentQueue, SKPaymentTransactionObserver {
    var paymentsController: PaymentsController

    init(paymentsController: PaymentsController = PaymentsController()) {
        // super.init()
        self.paymentsController = paymentsController
        // SKPaymentQueue.default().add(self)
    }

    // Start a payment process with the given payment information
    func startPayment(_ payment: Payment) {
        // Add the PaymentQueueController as a transaction observer to the default payment queue
        SKPaymentQueue.default().add(self)
        paymentsController.append(payment)
        let skPayment = SKMutablePayment(product: payment.product)
        skPayment.quantity = payment.quantity
        let defaultQueue = SKPaymentQueue.default()
        // Append the payment to the PaymentsController for tracking
        defaultQueue.add(skPayment)
    }

    func add(_ payment: SKPayment) {
        // May need to work on this function.
    }

    // Implement TransactionObserver methods to handle transaction updates
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        let unhandledTransactions = paymentsController.processTransactions(transactions, on: self)

        // Handle unhandled transactions if needed
        for transaction in unhandledTransactions {
            switch transaction.transactionState {
            case .purchased:
                // Handle a successful transaction
                let productIdentifier = transaction.payment.productIdentifier
                queue.finishTransaction(transaction)

            case .failed:
                // Handle a failed transaction
                let productIdentifier = transaction.payment.productIdentifier
                queue.finishTransaction(transaction)

            default:
                break
            }
        }
    }
}
