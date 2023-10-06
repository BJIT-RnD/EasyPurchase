import Foundation
import StoreKit

/// Represents a payment for a product.
public struct Payment {
    public let product: SKProduct         // The product being purchased
    public let quantity: Int              // The quantity of the product (e.g., for consumable items)
    public var needToDownloadContent: Bool // Indicates whether content needs to be downloaded after purchase
    public var completion: (PurchaseResult) -> Void // Completion block to handle purchase result

    public init(product: SKProduct, quantity: Int = 0, needToDownloadContent: Bool, completion: @escaping (PurchaseResult) -> Void) {
        self.product = product
        self.quantity = quantity
        self.needToDownloadContent = needToDownloadContent
        self.completion = completion
    }
}

/// Enum representing the result of a purchase.
public enum PurchaseResult {
    case success
    case failure(error: Error?)
}

/// Protocol defining transaction handling methods.
public protocol TransactionController {

    /// Process an array of payment transactions.
    ///
    /// - Parameters:
    ///   - transactions: An array of `SKPaymentTransaction` objects to be processed.
    ///   - paymentQueue: The payment queue responsible for the transactions.
    /// - Returns: An array of unhandled `SKPaymentTransaction` objects.
    func processTransactions(_ transactions: [SKPaymentTransaction], on paymentQueue: CustomPaymentQueue) -> [SKPaymentTransaction]
}

/// Implementation of the transaction controller.
public class PaymentsController: TransactionController {

    public var payments: [Payment] = []          // Array to hold pending payments
    public init() { }

    /// Add a payment to the pending payments array.
    ///
    /// - Parameter payment: The `Payment` object to be added.
    public func append(_ payment: Payment) {
        payments.append(payment)
    }

    /// Find the corresponding payment for a transaction.
    ///
    /// - Parameter transaction: The `SKPaymentTransaction` to find a payment for.
    /// - Returns: The corresponding `Payment` object, if found.
    private func findPayment(for transaction: SKPaymentTransaction) -> Payment? {
        return payments.first { $0.product.productIdentifier == transaction.payment.productIdentifier }
    }

    /// Process a single transaction.
    ///
    /// - Parameters:
    ///   - transaction: The `SKPaymentTransaction` to be processed.
    ///   - paymentQueue: The payment queue responsible for the transaction.
    /// - Returns: `true` if the transaction was successfully handled; otherwise, `false`.
    func processTransaction(_ transaction: SKPaymentTransaction, on paymentQueue: CustomPaymentQueue) -> Bool {
        switch transaction.transactionState {
        case .purchasing:
            // Transaction is being processed, no action needed for now
            return true

        case .purchased:
            // Transaction was successful, unlock content or provide the purchased item
            let payment = findPayment(for: transaction)
            payment?.completion(.success)
            return true

        case .failed:
            // Transaction failed, handle the error and potentially provide a way for the user to retry
            let payment = findPayment(for: transaction)
            payment?.completion(.failure(error: transaction.error))
            return false

        case .restored:
            // Transaction was restored (e.g., for a previously purchased non-consumable)
            // You may want to unlock content or provide the restored item
            return true

        case .deferred:
            // Transaction is in a deferred state (e.g., for family sharing)
            // Handle as needed based on your app's requirements
            return true

        @unknown default:
            fatalError()
        }
    }

    /// Process a batch of transactions.
    ///
    /// - Parameters:
    ///   - transactions: An array of `SKPaymentTransaction` objects to be processed.
    ///   - paymentQueue: The payment queue responsible for the transactions.
    /// - Returns: An array of unhandled `SKPaymentTransaction` objects.
    public func processTransactions(_ transactions: [SKPaymentTransaction], on paymentQueue: CustomPaymentQueue) -> [SKPaymentTransaction] {
        var unhandledTransactions: [SKPaymentTransaction] = []

        for transaction in transactions {
            if !processTransaction(transaction, on: paymentQueue) {
                // If a transaction wasn't handled successfully, add it to the unhandledTransactions array
                unhandledTransactions.append(transaction)
            }
        }
        return unhandledTransactions
    }
}
