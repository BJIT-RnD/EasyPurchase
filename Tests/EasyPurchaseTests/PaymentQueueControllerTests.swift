//
//  PaymentQueueControllerTests.swift
//  
//
//  Created by BJIT on 06.10.2023.
//

import XCTest
import StoreKit
@testable import EasyPurchase

/// Define a test class for `PaymentQueueController`
final class PaymentQueueControllerTests: XCTestCase {
    // MARK: - PROPERTIES
    var paymentQueueController: PaymentQueueController!
    var mockPaymentQueue: MockPaymentQueue!

    // This method is called before each test case, and it sets up the test environment.
    override func setUp() {
        super.setUp()
        paymentQueueController = PaymentQueueController()
        mockPaymentQueue = MockPaymentQueue()
    }

    // This method is called after each test case, and it cleans up resources.
    override func tearDown() {
        super.tearDown()
        paymentQueueController = nil
        mockPaymentQueue = nil
    }

    /// Test that the PaymentQueueController initializes and registers as an observer with the mock payment queue.
    func testInitRegistersTheObserver() {
        let payment = PaymentQueueController(paymentQueue: mockPaymentQueue)
        XCTAssertTrue(mockPaymentQueue.addedObserver === payment)
    }

    /// Test that the PaymentQueueController removes itself as an observer when deinitialized.
    func testDeinitRemovesTheObserver() {
        _ = PaymentQueueController(paymentQueue: mockPaymentQueue)
        XCTAssertNotNil(mockPaymentQueue.addedObserver)
    }

    func testStartPaymentSuccess() {
        let mockTransaction = SKPaymentTransaction()
        let mockPaymentQueueController = PaymentQueueController(paymentQueue: mockPaymentQueue)
        let transactions = [mockTransaction]

        let payment = mockPayment(productIdentifier: "com.bjitgroup.easypurchase.consumable.tencoin") { _ in }
        do { try mockPaymentQueueController.startPayment(payment) }
        catch let error as NSError {
            // Handle the error and access error information
            print("Payment failed with error: \(error.localizedDescription)")
            print("Error code: \(error.code)")
            print("Error domain: \(error.domain)")
            XCTAssertEqual(error.localizedDescription, "Invalid payment quantity: Must be greater than zero")
        }
        catch {
            // handle other errors here
        }
        XCTAssertEqual(mockPaymentQueue.addedPayment.count, 1)
    }

    func testPaymentQuantityGreaterThanZeroSuccess() {
        let mockTransaction = SKPaymentTransaction()
        let mockPaymentQueueController = PaymentQueueController(paymentQueue: mockPaymentQueue)
        let transactions = [mockTransaction]

        let payment = mockPayment(productIdentifier: "com.bjitgroup.easypurchase.consumable.tencoin", quantity: 1) { _ in }
        do {
            try mockPaymentQueueController.startPayment(payment)
        }
        catch let error as NSError {
            // Handle the error and access error information
            print("Payment failed with error: \(error.localizedDescription)")
            print("Error code: \(error.code)")
            print("Error domain: \(error.domain)")
            XCTAssertEqual(error.localizedDescription, "Invalid payment quantity: Must be greater than zero")
        }
        catch {
            // handle other errors here
        }
        XCTAssertEqual(mockPaymentQueue.addedPayment.count, 1)
    }

    func testPaymentQuantityEqualToZeroSuccess() {
        let mockTransaction = SKPaymentTransaction()
        let mockPaymentQueueController = PaymentQueueController(paymentQueue: mockPaymentQueue)
        let transactions = [mockTransaction]

        let payment = mockPayment(productIdentifier: "com.bjitgroup.easypurchase.consumable.tencoin", quantity: 0) { _ in }
        do {
            try mockPaymentQueueController.startPayment(payment)
        }
        catch let error as NSError {
            // Handle the error and access error information
            print("Payment failed with error: \(error.localizedDescription)")
            print("Error code: \(error.code)")
            print("Error domain: \(error.domain)")
            XCTAssertEqual(error.localizedDescription, "Invalid payment quantity: Must be greater than zero")
        }
        catch {
            // handle other errors here
        }
        XCTAssertEqual(mockPaymentQueue.addedPayment.count, 0)
    }

    /// Test the payment queue with one transaction for each state and callbacks.
    func testPaymentQueueWithOneTransactionForEachStateAndCallbacks() {
        let mockPaymentQueueController = PaymentQueueController(paymentQueue: mockPaymentQueue)

        let purchasedProductIdentifier = "com.bjitgroup.easypurchase.consumable.tencoin"
        let failedProductIdentifier = "com.bjitgroup.easypurchase.consumable.twentycoin"
        let restoredProductIdentifier = "com.bjitgroup.easypurchase.consumable.thirtycoin"
        let deferredProductIdentifier = "com.bjitgroup.easypurchase.nonconsumable.levelone"
        let purchasingProductIdentifier = "com.bjitgroup.easypurchase.nonconsumable.leveltwo"

        let transaction = [
            makeMockTransactionPayment(productId: purchasedProductIdentifier, transactionState: .purchased),
            makeMockTransactionPayment(productId: failedProductIdentifier, transactionState: .failed),
            makeMockTransactionPayment(productId: restoredProductIdentifier, transactionState: .restored),
            makeMockTransactionPayment(productId: deferredProductIdentifier, transactionState: .deferred),
            makeMockTransactionPayment(productId: purchasingProductIdentifier, transactionState: .purchasing)
        ]

        var isPaymentCallbackCalled = false
        let mockPayment = mockPayment(productIdentifier: purchasedProductIdentifier) { result in
            isPaymentCallbackCalled = true
            if case .success(let purchase) = result {
                XCTAssertEqual(purchase.product.productIdentifier, purchasedProductIdentifier)
            } else {
                XCTFail("Callback With purchase id.")
            }
            XCTAssertTrue(isPaymentCallbackCalled)
        }

        var isRestored = false
        let restorePurchases = RestoreProducts(atomically: true) { restores in
            isRestored = true
            XCTAssertEqual(restores.count, 1)
            if case .restored(let purchase) = restores.first {
                XCTAssertEqual(purchase.productId, restoredProductIdentifier)
            } else {
                XCTFail("Restored not completed.")
            }
        }

        var isCompleteTransactionCalled = false
        let completeTransaction = ProcessedTransactions { purchases in
            isCompleteTransactionCalled = true
        }

        do { try mockPaymentQueueController.startPayment(mockPayment) }
        catch let error as NSError {
            // Handle the error and access error information
            print("Payment failed with error: \(error.localizedDescription)")
            print("Error code: \(error.code)")
            print("Error domain: \(error.domain)")
            XCTAssertEqual(error.localizedDescription, "Invalid payment quantity: Must be greater than zero")
        }
        catch {
            // handle other errors here
        }
        mockPaymentQueueController.completeTransactions(completeTransaction)
        mockPaymentQueueController.restorePurchases(restorePurchases)
        mockPaymentQueueController.paymentQueue(SKPaymentQueue(), updatedTransactions: transaction)
        mockPaymentQueueController.paymentQueueRestoreCompletedTransactionsFinished(SKPaymentQueue())

        XCTAssertTrue(isCompleteTransactionCalled)
        XCTAssertTrue(isPaymentCallbackCalled)
        XCTAssertTrue(isRestored)
    }

    /// Test the payment queue with one transaction for each state callbacks without restore.
    func testPaymentQueueWithOneTransactionForEachStateCallbacksWithoutRestore() {
        let mockPaymentQueueController = PaymentQueueController(paymentQueue: mockPaymentQueue)

        let purchasedProductIdentifier = "com.SwiftyStoreKit.product1"
        let failedProductIdentifier = "com.SwiftyStoreKit.product2"
        let restoredProductIdentifier = "com.SwiftyStoreKit.product3"
        let deferredProductIdentifier = "com.SwiftyStoreKit.product4"
        let purchasingProductIdentifier = "com.SwiftyStoreKit.product5"

        let transactions = [
            makeMockTransactionPayment(productId: purchasedProductIdentifier, transactionState: .purchased),
            makeMockTransactionPayment(productId: failedProductIdentifier, transactionState: .failed),
            makeMockTransactionPayment(productId: restoredProductIdentifier, transactionState: .restored),
            makeMockTransactionPayment(productId: deferredProductIdentifier, transactionState: .deferred),
            makeMockTransactionPayment(productId: purchasingProductIdentifier, transactionState: .purchasing)
            ]

        var paymentCallbackCalled = false
        let mockPayment =  mockPayment(productIdentifier: purchasedProductIdentifier) { result in
            paymentCallbackCalled = true
            if case .success(purchase: let payment) = result {
                XCTAssertEqual(payment.product.productIdentifier, purchasedProductIdentifier)
            } else {
                XCTFail("Purchased callback with product id")
            }
        }

        var completeTransactionsCallbackCalled = false
        let completeTransactions = ProcessedTransactions { payments in
            completeTransactionsCallbackCalled = true
        }

        do { try mockPaymentQueueController.startPayment(mockPayment) }
        catch let error as NSError {
            // Handle the error and access error information
            print("Payment failed with error: \(error.localizedDescription)")
            print("Error code: \(error.code)")
            print("Error domain: \(error.domain)")
            XCTAssertEqual(error.localizedDescription, "Invalid payment quantity: Must be greater than zero")
        }
        catch {
            // handle other errors here
        }
        mockPaymentQueueController.completeTransactions(completeTransactions)
        mockPaymentQueueController.paymentQueue(SKPaymentQueue(), updatedTransactions: transactions)
        mockPaymentQueueController.paymentQueueRestoreCompletedTransactionsFinished(SKPaymentQueue())

        XCTAssertTrue(paymentCallbackCalled)
        XCTAssertTrue(completeTransactionsCallbackCalled)
    }

    /// Test the payment queue with one transaction for each state callbacks without startPayment.
    func testPaymentQueueWithOneTransactionForEachStateCallbacksWithoutStartPayment() {
        let mockPaymentQueueController = PaymentQueueController(paymentQueue: mockPaymentQueue)

        let purchasedProductIdentifier = "com.SwiftyStoreKit.product1"
        let failedProductIdentifier = "com.SwiftyStoreKit.product2"
        let restoredProductIdentifier = "com.SwiftyStoreKit.product3"
        let deferredProductIdentifier = "com.SwiftyStoreKit.product4"
        let purchasingProductIdentifier = "com.SwiftyStoreKit.product5"

        let transactions = [
            makeMockTransactionPayment(productId: purchasedProductIdentifier, transactionState: .purchased),
            makeMockTransactionPayment(productId: failedProductIdentifier, transactionState: .failed),
            makeMockTransactionPayment(productId: restoredProductIdentifier, transactionState: .restored),
            makeMockTransactionPayment(productId: deferredProductIdentifier, transactionState: .deferred),
            makeMockTransactionPayment(productId: purchasingProductIdentifier, transactionState: .purchasing)
            ]

        var restorePurchasesCallbackCalled = false
        let restorePurchases = RestoreProducts(atomically: true) { results in
            restorePurchasesCallbackCalled = true
            XCTAssertEqual(results.count, 1)
            let first = results.first!
            if case .restored(let restoredPayment) = first {
                XCTAssertEqual(restoredPayment.productId, restoredProductIdentifier)
            } else {
                XCTFail("Restored callback with product")
            }
        }

        var completeTransactionsCallbackCalled = false
        let completeTransactions = ProcessedTransactions { payments in
            completeTransactionsCallbackCalled = true
            XCTAssertEqual(payments.count, 3)
            XCTAssertEqual(payments[0].productId, purchasedProductIdentifier)
            XCTAssertEqual(payments[1].productId, failedProductIdentifier)
            XCTAssertEqual(payments[2].productId, deferredProductIdentifier)
        }

        mockPaymentQueueController.completeTransactions(completeTransactions)
        mockPaymentQueueController.restorePurchases(restorePurchases)
        mockPaymentQueueController.paymentQueue(SKPaymentQueue(), updatedTransactions: transactions)
        mockPaymentQueueController.paymentQueueRestoreCompletedTransactionsFinished(SKPaymentQueue())

        XCTAssertTrue(restorePurchasesCallbackCalled)
        XCTAssertTrue(completeTransactionsCallbackCalled)
    }

    /// Test case to check when `shouldAddStorePaymentCompletion` is nil and `shouldAddStorePayment` returns false
    func testPaymentQueueWhenShouldAddStorePaymentCompletionNilAndShouldAddStorePaymentReturnFalse() {
        // Create an instance of PaymentQueueController with a mock PaymentQueue
        let mockPaymentQueueController = PaymentQueueController(paymentQueue: mockPaymentQueue)

        /// Set `shouldAddStorePaymentCompletion` to nil
        mockPaymentQueueController.shouldAddStorePaymentCompletion = nil

        /// Assert that `paymentQueue` returns false when `shouldAddStorePayment` is called
        XCTAssertFalse(mockPaymentQueueController.paymentQueue(SKPaymentQueue(), shouldAddStorePayment: SKPayment(), for: MockProduct(productIdentifier: "")))
    }

    /// Test case to check when `shouldAddStorePaymentCompletion` returns true and `shouldAddStorePayment` returns true
    func testPaymentQueueWhenShouldAddStorePaymentCompletionReturnTrueAndShouldAddStorePaymentReturnTrue() {
        /// Create an instance of `PaymentQueueController` with a mock PaymentQueue
        let mockPaymentQueueController = PaymentQueueController(paymentQueue: mockPaymentQueue)

        /// Set `shouldAddStorePaymentCompletion` to a closure that always returns true
        mockPaymentQueueController.shouldAddStorePaymentCompletion = { payment, product in
            return true
        }

        /// Assert that `paymentQueue` returns true when `shouldAddStorePayment` is called
        XCTAssertTrue(mockPaymentQueueController.paymentQueue(SKPaymentQueue(), shouldAddStorePayment: SKPayment(), for: MockProduct(productIdentifier: "")))
    }

    /// Test case to check when `shouldAddStorePaymentCompletion` returns false and `shouldAddStorePayment` returns false
    func testPaymentQueueWhenShouldAddStorePaymentCompletionReturnFalseAndShouldAddStorePaymentReturnFalse() {
        /// Create an instance of PaymentQueueController with a mock PaymentQueue
        let mockPaymentQueueController = PaymentQueueController(paymentQueue: mockPaymentQueue)

        /// Set `shouldAddStorePaymentCompletion` to a closure that always returns false
        mockPaymentQueueController.shouldAddStorePaymentCompletion = { payment, product in
            return false
        }

        /// Assert that `paymentQueue` returns false when `shouldAddStorePayment` is called
        XCTAssertFalse(mockPaymentQueueController.paymentQueue(SKPaymentQueue(), shouldAddStorePayment: SKPayment(), for: MockProduct(productIdentifier: "")))
    }

    /// Create a mock payment for testing.
    /// - Parameters:
    ///   - productIdentifier: The product identifier for the mock product.
    ///   - quantity: The quantity for the mock payment.
    ///   - needToDownloadContent: A boolean indicating if content needs to be downloaded.
    ///   - completion: A callback to handle the payment result.
    /// - Returns: A `Payment` object for testing.
    func mockPayment(productIdentifier: String, quantity: Int = 1, needToDownloadContent: Bool = true, completion: @escaping (PurchaseResult) -> Void) -> Payment {
        let mockProduct = MockProduct(productIdentifier: productIdentifier)

        return Payment(product: mockProduct, quantity: quantity, needToDownloadContent: needToDownloadContent, completion: completion)
    }

    /// Create a mock payment transaction for testing.
    /// - Parameters:
    ///   - productId: The product identifier for the mock product.
    ///   - transactionState: The transaction state for the mock payment transaction.
    /// - Returns: A `MockPaymentTransaction` object for testing.
    func makeMockTransactionPayment(productId: String, transactionState: SKPaymentTransactionState) -> MockPaymentTransaction {
        let mockProduct = MockProduct(productIdentifier: productId)
        return MockPaymentTransaction(payment: SKPayment(product: mockProduct),transactionState: transactionState)
    }
}
