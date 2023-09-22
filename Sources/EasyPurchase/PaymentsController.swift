//
//  PaymentsController.swift
//  
//
//  Created by BJIT on 22/9/23.
//

import Foundation
import StoreKit

// Structure representing a payment
struct Payment {
    let product: SKProduct         // The product being purchased
    let quantity: Int              // The quantity of the product (e.g., for consumable items)
    var needToDownloadContent: Bool // Indicates whether content needs to be downloaded after purchase
    var completion: (PurchaseResult) -> Void // Completion block to handle purchase result
}

// Enum representing the result of a purchase
enum PurchaseResult {
    case success
    case failure(error: Error?)
}

// Protocol defining transaction handling methods
protocol TransactionController {
    func processTransactions(_ transactions: [SKPaymentTransaction], on paymentQueue: PaymentQueue) -> [SKPaymentTransaction]
}

// Implementation of the transaction controller
class PaymentsController: TransactionController {

    var payments: [Payment] = []          // Array to hold pending payments
    var unhandledTransactions: [SKPaymentTransaction] = [] // Array to hold unhandled transactions

    // Add a payment to the pending payments array
    func append(_ payment: Payment) {
        payments.append(payment)
    }

    // Find the corresponding payment for a transaction
    private func findPayment(for transaction: SKPaymentTransaction) -> Payment? {
        return payments.first { $0.product.productIdentifier == transaction.payment.productIdentifier }
    }

    // Process a single transaction
    func processTransaction(_ transaction: SKPaymentTransaction, on paymentQueue: PaymentQueue) -> Bool {
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

    // Process a batch of transactions
    func processTransactions(_ transactions: [SKPaymentTransaction], on paymentQueue: PaymentQueue) -> [SKPaymentTransaction] {
        var unhandledTransactions: [SKPaymentTransaction] = []

        for transaction in transactions {
            if !processTransaction(transaction, on: paymentQueue) {
                // If a transaction wasn't handled successfully, add it to the unhandledTransactions array
                unhandledTransactions.append(transaction)
            }
        }

        // Store unhandled transactions in the property
        self.unhandledTransactions = unhandledTransactions

        return unhandledTransactions
    }
}
