//
//  PaymentQueueController.swift
//  EasyPurchase
//
//  Created on 20.09.2023.
//

import Foundation
import StoreKit

/// A protocol defining methods for customizing the behavior of a payment queue.
public protocol CustomPaymentQueue: AnyObject {
    /// Adds an observer to the custom payment queue.
    /// - Parameter observer: The observer to be added to the payment queue.
    func add(_ observer: SKPaymentTransactionObserver)
    /// Adds a payment to the custom payment queue.
    /// - Parameter payment: The payment to be added to the payment queue.
    func add(_ payment: SKPayment)
}

/// Defines methods for handling in-app purchase transaction outcomes and processing transactions.
public protocol PaymentQueueDelegate: AnyObject {
    /// Handles successful transactions for a specific product.
    /// - Parameter productIdentifier: The identifier of the successfully purchased product.
    func handleTransactionSuccess(for productIdentifier: String)

    /// Handles failed transactions for a specific product.
    /// - Parameters:
    ///   - productIdentifier: The identifier of the product that encountered an error.
    ///   - error: An optional error object describing the failure.
    func handleTransactionFailure(for productIdentifier: String, with error: Error?)

    /// Processes and manages in-app purchase transactions.
    /// - Parameters:
    ///   - transactions: An array of payment transactions to be processed.
    ///   - paymentQueue: The payment queue responsible for the transactions.
    /// - Returns: An array of unhandled transactions that need further processing.
    func processTransactions(_ transactions: [SKPaymentTransaction], on paymentQueue: CustomPaymentQueue) -> [SKPaymentTransaction]
}

extension SKPaymentQueue: CustomPaymentQueue { }

/// Manages in-app purchase transactions and coordinates payment-related operations.
public class PaymentQueueController: NSObject {
    private var paymentsController = PaymentsController()
    private let paymentQueue: CustomPaymentQueue

    /// Initializes a PaymentObserver with the specified payments controller and payment queue.
    /// - Parameters:
    ///   - paymentsController: The PaymentsController responsible for managing payment transactions.
    ///   - paymentQueue: The payment queue to observe for updates. Defaults to the system's default payment queue.
    public init(paymentsController: PaymentsController = PaymentsController(), paymentQueue: CustomPaymentQueue = SKPaymentQueue.default()) {
        self.paymentsController = paymentsController
        self.paymentQueue = paymentQueue
        super.init()
        // Add the PaymentObserver to the specified payment queue for observation.
        paymentQueue.add(self)
    }

    /// Initiates a payment transaction for the specified product.
    /// - Parameter payment: The Payment object containing the product to be purchased and its quantity.
    func startPayment(_ payment: Payment) {
        // Create an SKMutablePayment object using the product and quantity from the Payment object.
        let skPayment = SKMutablePayment(product: payment.product)
        skPayment.quantity = payment.quantity
        // Retrieve the default payment queue.
        let defaultQueue = SKPaymentQueue.default()
        // Add the payment to the payment queue.
        defaultQueue.add(skPayment)
        // Append the payment to the paymentsController for tracking.
        paymentsController.append(payment)
    }
}

extension PaymentQueueController: SKPaymentTransactionObserver {
    /// Notifies the observer that the payment queue has updated the transactions.
    /// - Parameters:
    ///   - queue: The payment queue responsible for the transactions.
    ///   - transactions: An array of updated payment transactions.
    public func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        // Process the transactions and retrieve any unhandled transactions
        let unhandledTransactions = paymentsController.processTransactions(transactions, on: paymentQueue)

        // Iterate through unhandled transactions and handle them accordingly
        for transaction in unhandledTransactions {
            switch transaction.transactionState {
            case .purchased:
                // Handle a successful transaction, e.g., deliver the purchased content
                let productIdentifier = transaction.payment.productIdentifier
                queue.finishTransaction(transaction)

            case .failed:
                // Handle a failed transaction, e.g., inform the user of the failure
                let productIdentifier = transaction.payment.productIdentifier
                queue.finishTransaction(transaction)

            default:
                // Additional handling for other transaction states may be required in the future
                break
            }
        }
    }
}
