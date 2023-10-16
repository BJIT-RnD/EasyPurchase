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
public struct Purchase {
    let productId: String
    let quantity: Int
    let product: SKProduct? //??
    let transaction: PaymentTransaction
    let originalTransaction: PaymentTransaction?
    let needsFinishTransaction: Bool
    
    init(productId: String, quantity: Int, product: SKProduct?, transaction: PaymentTransaction, originalTransaction: PaymentTransaction?, needsFinishTransaction: Bool) {
        self.productId = productId
        self.quantity = quantity
        self.product = product
        self.transaction = transaction
        self.originalTransaction = originalTransaction
        self.needsFinishTransaction = needsFinishTransaction
    }
}

// This Swift enumeration, 'InAppTransactionActionsResult', serves as a clear and structured representation of the potential outcomes for in-app transactions. It effectively categorizes the different states that a transaction can assume, allowing for easy handling and communication of transaction results.

public enum InAppTransactionActionsResult {
    // When a user successfully purchases an in-app item, this case is used to denote the purchase action, and it includes a reference to the associated 'Purchase' object, providing access to transaction details.
    case purchased(purchase: Purchase)

    // For the restoration of previous purchases, such as when a user reinstalls the app or switches devices, this case is employed. It also includes a reference to the 'Purchase' object for accessing restored transaction details.
    case restored(purchase: Purchase)

    // In cases where a transaction is in a deferred state, typically seen with auto-renewable subscriptions requiring user interaction or validation, this case indicates the deferred state, and it includes the 'Purchase' object for convenient access to related transaction details.
    case deferred(purchase: Purchase)

    // If a transaction fails, this case communicates the failure and includes an 'SKError' object to capture and handle the specific error details.
    case failed(error: SKError)
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
    init(paymentsController: PaymentsController = PaymentsController(), paymentQueue: InAppPaymentQueue = SKPaymentQueue.default(), completeTransactionsController: CompleteTransactionController = CompleteTransactionController()) {
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
