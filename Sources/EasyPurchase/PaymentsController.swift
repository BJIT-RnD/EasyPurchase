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
    case success(purchase: Payment)
    case failure(error: SKError)
}

/// Protocol defining transaction handling methods.
public protocol TransactionController {

    /// Process an array of payment transactions.
    ///
    /// - Parameters:
    ///   - transactions: An array of `SKPaymentTransaction` objects to be processed.
    ///   - paymentQueue: The payment queue responsible for the transactions.
    /// - Returns: An array of unhandled `SKPaymentTransaction` objects.
    func processTransactions(_ transactions: [SKPaymentTransaction], on paymentQueue: InAppPaymentQueue) -> [SKPaymentTransaction]
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
    private func findPurchase(for transaction: SKPaymentTransaction) -> Payment? {
        return payments.first { $0.product.productIdentifier == transaction.payment.productIdentifier }
    }

    /// Finds the position of a payment in the list of payments based on its product identifier.
    /// - Parameter identifier: The unique product identifier of the payment to locate.
    /// - Returns: The index of the payment in the `payments` array, or `nil` if not found.
    private func paymentIndexPosition(withIdentifier identifier: String) -> Int? {
        for (index, payment) in payments.enumerated() {
            if payment.product.productIdentifier == identifier {
                return index
            }
        }
        return nil
    }

    /// Process a single transaction.
    ///
    /// - Parameters:
    ///   - transaction: The `SKPaymentTransaction` to be processed.
    ///   - paymentQueue: The payment queue responsible for the transaction.
    /// - Returns: `true` if the transaction was successfully handled; otherwise, `false`.
    func processTransaction(_ transaction: SKPaymentTransaction, on paymentQueue: InAppPaymentQueue) -> Bool {
        let transactionId = transaction.payment.productIdentifier
        guard let paymentIndex = paymentIndexPosition(withIdentifier: transactionId) else {
            return false
        }
        let payment = payments[paymentIndex]

        switch transaction.transactionState {
        case .purchasing:
            // Transaction is being processed, no action needed for now
            return true

        case .purchased:
            if let purchase = findPurchase(for: transaction) {
                payment.completion(.success(purchase: purchase))
                paymentQueue.finishTransaction(transaction)
                payments.remove(at: paymentIndex)
                return true
            }
            // Handle the case when 'findPayment' returns nil
            return false

        case .failed:
            let purchase = findPurchase(for: transaction)
            payment.completion(.failure(error: failedTransactionError(for: transaction.error as NSError?)))
            paymentQueue.finishTransaction(transaction)
            payments.remove(at: paymentIndex)
            return true

        case .restored:
            // Transaction was restored (e.g., for a previously purchased non-consumable)
            // You may want to unlock content or provide the restored item
            if let purchase = findPurchase(for: transaction) {
                payment.completion(.success(purchase: purchase))
                paymentQueue.finishTransaction(transaction)
                payments.remove(at: paymentIndex)
                return true
            } else {
                // Handle the case when 'findPayment' returns nil
                return false
            }
        case .deferred:
            // Transaction is in a deferred state (e.g., for family sharing)
            // Handle as needed based on your app's requirements
            if let purchase = findPurchase(for: transaction) {
                payment.completion(.success(purchase: purchase))
                paymentQueue.finishTransaction(transaction)
                payments.remove(at: paymentIndex)
                return true
            } else {
                // Handle the case when 'findPayment' returns nil
                return false
            }

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
    public func processTransactions(_ transactions: [SKPaymentTransaction], on paymentQueue: InAppPaymentQueue) -> [SKPaymentTransaction] {
        var unhandledTransactions: [SKPaymentTransaction] = []

        for transaction in transactions {
            if !processTransaction(transaction, on: paymentQueue) {
                // If a transaction wasn't handled successfully, add it to the unhandledTransactions array
                unhandledTransactions.append(transaction)
            }
        }
        return unhandledTransactions
    }

    /// Generate an `SKError` for a failed transaction.
    /// - Parameter error: An optional `NSError` object that represents the underlying error.
    /// - Returns: An `SKError` instance with the appropriate error code and message.
    func failedTransactionError(for error: NSError?) -> SKError {
        let errorMessage = error?.localizedDescription ?? "Unknown error"
        return SKError(_nsError: NSError(domain: SKErrorDomain, code: SKError.unknown.rawValue, userInfo: [NSLocalizedDescriptionKey: errorMessage]))
    }
}
