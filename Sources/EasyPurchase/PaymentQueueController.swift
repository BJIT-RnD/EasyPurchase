//
//  PaymentQueueController.swift
//  EasyPurchase
//
//  Created on 20.09.2023.
//

import Foundation
import StoreKit

// typealias for a closure that takes an SKPayment and SKProduct as input parameters and returns a Bool
public typealias ShouldAddStorePaymentCompletion = (_ payment: SKPayment, _ product: SKProduct) -> Bool

// MARK: - 'Purchase' STRUCT
struct Purchase {
    let productId: String
    let quantity: Int
    let transaction: PaymentTransaction
    let originalTransaction: PaymentTransaction?
    let needsFinishTransaction: Bool
    
    init(productId: String, quantity: Int, transaction: PaymentTransaction, originalTransaction: PaymentTransaction?, needsFinishTransaction: Bool) {
        self.productId = productId
        self.quantity = quantity
        self.transaction = transaction
        self.originalTransaction = originalTransaction
        self.needsFinishTransaction = needsFinishTransaction
    }
}

extension SKPaymentTransaction: PaymentTransaction { }

/// A protocol defining methods for customizing the behavior of a payment queue.
public protocol InAppPaymentQueue: AnyObject {
    /// Adds an observer to the custom payment queue.
    /// - Parameter observer: The observer to be added to the payment queue.
    func add(_ observer: SKPaymentTransactionObserver)
    /// Adds a payment to the custom payment queue.
    /// - Parameter payment: The payment to be added to the payment queue.
    func add(_ payment: SKPayment)
    /// Removes an observer to the custom payment queue
    /// - Parameter payment:  The observer to be removed to the payment queue..
    func remove(_ observer: SKPaymentTransactionObserver)
    
    func finishTransaction(_ transaction: SKPaymentTransaction)
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
    func processTransactions(_ transactions: [SKPaymentTransaction], on paymentQueue: InAppPaymentQueue) -> [SKPaymentTransaction]
}

extension SKPaymentQueue: InAppPaymentQueue { }

/// Manages in-app purchase transactions and coordinates payment-related operations.
public class PaymentQueueController: NSObject {
    private var paymentsController = PaymentsController()
    private let paymentQueue: InAppPaymentQueue
    var shouldAddStorePaymentCompletion: ShouldAddStorePaymentCompletion?
    private let completeTransactionsController: CompleteTransactionController
    
    /// Initializes a PaymentObserver with the specified payments controller and payment queue.
    /// - Parameters:
    ///   - paymentsController: The PaymentsController responsible for managing payment transactions.
    ///   - paymentQueue: The payment queue to observe for updates. Defaults to the system's default payment queue.
    public init(paymentsController: PaymentsController = PaymentsController(), paymentQueue: InAppPaymentQueue, completeTransactionsController: CompleteTransactionController) {
        self.paymentsController = paymentsController
        self.paymentQueue = paymentQueue
        self.completeTransactionsController = completeTransactionsController
        super.init()
        // Add the PaymentObserver to the specified payment queue for observation.
        paymentQueue.add(self)
    }

    /// Initiates a payment transaction for the specified product.
    /// - Parameter payment: The Payment object containing the product to be purchased and its quantity.
    public func startPayment(_ payment: Payment) {
        // Create an SKMutablePayment object using the product and quantity from the Payment object.
        let skPayment = SKMutablePayment(product: payment.product)
        skPayment.quantity = payment.quantity
        // Add the payment to the payment queue.
        paymentQueue.add(skPayment)
        // Append the payment to the paymentsController for tracking.
        paymentsController.append(payment)
    }
    
    func completeTransactions(_ completeTransactions: ProcessedTransactions) {
        guard completeTransactionsController.processedTransactions == nil else {
            return
        }
        completeTransactionsController.processedTransactions = completeTransactions
    }
}

extension PaymentQueueController: SKPaymentTransactionObserver {
    /// Notifies the observer that the payment queue has updated the transactions.
    /// - Parameters:
    ///   - queue: The payment queue responsible for the transactions.
    ///   - transactions: An array of updated payment transactions.
    public func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        var rawTransactions = transactions.filter { $0.transactionState != .purchasing }
        if !rawTransactions.isEmpty {
            // Process the transactions and retrieve any unhandled transactions
            rawTransactions = paymentsController.processTransactions(transactions, on: paymentQueue)
            rawTransactions = completeTransactionsController.processTransactions(rawTransactions, on: paymentQueue)
        }
        
        if !rawTransactions.isEmpty {
            let string = rawTransactions.map { $0.debugDescription }.joined(separator: "/n")
            print("RawTransaction ♦️: /n \(string)")
        }
    }
    
    // Calls the `shouldAddStorePaymentCompletion` closure, passing the provided `SKPayment` and `SKProduct` as parameters,
    // and returns its result. If the closure is nil, it defaults to false.
    public func paymentQueue(_ queue: SKPaymentQueue, shouldAddStorePayment payment: SKPayment, for product: SKProduct) -> Bool {
        return shouldAddStorePaymentCompletion?(payment, product) ?? false
    }
}
