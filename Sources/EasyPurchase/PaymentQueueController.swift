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
    public let productId: String
    public let quantity: Int
    public let product: SKProduct? //??
    public let transaction: PaymentTransaction
    public let originalTransaction: PaymentTransaction?
    public let needsFinishTransaction: Bool
    
    public init(productId: String, quantity: Int, product: SKProduct?, transaction: PaymentTransaction, originalTransaction: PaymentTransaction?, needsFinishTransaction: Bool) {
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

    // Added for restoration management
    func restoreCompletedTransactions(withApplicationUsername username: String?)
}

extension SKPaymentQueue: InAppPaymentQueue { }

/// Manages in-app purchase transactions and coordinates payment-related operations.
public class PaymentQueueController: NSObject {
    private var paymentsController = PaymentsController()
    private let paymentQueue: InAppPaymentQueue
    var shouldAddStorePaymentCompletion: ShouldAddStorePaymentCompletion?
    private let restoreProductsController: RestoreProductsController
    private let completeTransactionsController: CompleteTransactionController
    
    /// Initializes a PaymentObserver with the specified payments controller and payment queue.
    /// - Parameters:
    ///   - paymentsController: The PaymentsController responsible for managing payment transactions.
    ///   - paymentQueue: The payment queue to observe for updates. Defaults to the system's default payment queue.
    public init(paymentsController: PaymentsController = PaymentsController(), paymentQueue: InAppPaymentQueue = SKPaymentQueue.default(), restoreProductsController: RestoreProductsController = RestoreProductsController(), completeTransactionsController: CompleteTransactionController = CompleteTransactionController()) {
        self.paymentsController = paymentsController
        self.paymentQueue = paymentQueue
        self.restoreProductsController = restoreProductsController
        self.completeTransactionsController = completeTransactionsController
        super.init()
        // Add the PaymentObserver to the specified payment queue for observation.
        paymentQueue.add(self)
    }

    /// Initiates a payment transaction for the specified product.
    /// - Parameter payment: The Payment object containing the product to be purchased and its quantity.
    public func startPayment(_ payment: Payment) throws {
        // Create an SKMutablePayment object using the product and quantity from the Payment object.
        if payment.quantity > 0 {
            let skPayment = SKMutablePayment(product: payment.product)
            skPayment.quantity = payment.quantity

            // Add the payment to the payment queue.
            paymentQueue.add(skPayment)

            // Append the payment to the paymentsController for tracking.
            paymentsController.append(payment)
        } else {
            // Handle the case when 'quantity' is not a positive value (e.g., log an error or perform an alternative action).
            print("Error: Payment quantity must be greater than zero")
            throw NSError(domain: SKErrorDomain, code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid payment quantity: Must be greater than zero"])
            // You can also throw an error, return from the function, or take any other appropriate action.
        }
    }
    
    /// A method to complete transactions by setting the `processedTransactions` property in the `completeTransactionsController`.
    /// - Parameter completeTransactions: A `ProcessedTransactions` instance representing a completion closure.
    func completeTransactions(_ completeTransactions: ProcessedTransactions) {
        /// Ensure that the `processedTransactions` property is not already set.
        guard completeTransactionsController.processedTransactions == nil else {
            return
        }
        /// Set the `processedTransactions` property to the provided `completeTransactions`.
        completeTransactionsController.processedTransactions = completeTransactions
    }

    /// This method is used to complete and finalize an in-app purchase transaction, removing it from the payment queue.
    /// - Parameter transaction: The payment transaction to finish.
    func finishTransaction(_ transaction: PaymentTransaction) {
        guard let inAppTransaction = transaction as? SKPaymentTransaction else {
            return
        }
        paymentQueue.finishTransaction(inAppTransaction)
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
            rawTransactions = restoreProductsController.processTransactions(transactions, on: paymentQueue)
            rawTransactions = completeTransactionsController.processTransactions(rawTransactions, on: paymentQueue)
        }
    }

    // Calls the `shouldAddStorePaymentCompletion` closure, passing the provided `SKPayment` and `SKProduct` as parameters,
    // and returns its result. If the closure is nil, it defaults to false.
    public func paymentQueue(_ queue: SKPaymentQueue, shouldAddStorePayment payment: SKPayment, for product: SKProduct) -> Bool {
        return shouldAddStorePaymentCompletion?(payment, product) ?? false
    }

    /**
     Restores in-app purchases with the provided 'RestoreProducts' configuration.

     - Parameters:
         - restorePurchases: An instance of 'RestoreProducts' that contains the necessary information for the restoration process.

     This function is responsible for initiating the restoration of previously purchased in-app products and subscriptions. It follows a clear sequence of steps:

     1. **Duplicate Request Check:** Initially, it checks whether a restoration process is already underway. If the `restoreProductsController.restoreProducts` is not `nil`, it indicates an ongoing restoration process, and further action is unnecessary to prevent redundant requests.

     2. **Initiate Restoration:** If no restoration process is currently in progress, it proceeds to initiate the restoration process by calling `paymentQueue.restoreCompletedTransactions(withApplicationUsername: restorePurchases.appUserName)`. This method triggers a request to Apple's payment system to restore completed transactions associated with the provided application username. This is a crucial step for users to regain access to their previously purchased items.

     3. **Update Restore Products Controller:** Following the initiation of the restoration, the function sets `restoreProductsController.restoreProducts` to the provided `restorePurchases` object. This assignment serves as an indicator that a restoration process is in progress, preventing additional restoration requests until the current one has completed.

     It is essential to ensure that this function is invoked when users explicitly request to restore their previous in-app purchases, allowing them to recover their purchased content. Additionally, it assumes that a valid 'RestoreProducts' configuration is provided for a seamless restoration process.
    */
    public func restorePurchases(_ restorePurchases: RestoreProducts) {
        paymentQueue.restoreCompletedTransactions(withApplicationUsername: restorePurchases.appUserName)

        restoreProductsController.restoreProducts = restorePurchases
    }

    /**
     Signals the completion of restoring in-app transactions within the payment queue.

     - Parameters:
         - queue: The 'SKPaymentQueue' instance representing the payment queue's state.

     This function is automatically triggered when the payment queue finishes restoring completed in-app transactions. It promptly calls the 'restoreCompletedTransactionsFinished()' method on the 'restorePurchasesController' object to conclude the restoration process and perform any necessary post-restoration tasks.
    */
    public func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
        restoreProductsController.restoreCompletedTransactionsFinished()
    }
}
