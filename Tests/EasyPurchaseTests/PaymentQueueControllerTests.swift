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
        mockPaymentQueueController.startPayment(payment)
        XCTAssertEqual(mockPaymentQueue.addedPayment.count, 1)
    }

    func testPaymentQueueCallbacks_whenHandlingTransactions() {
        let mockTransaction = SKPaymentTransaction()
        let mockPaymentQueueController = PaymentQueueController(paymentQueue: mockPaymentQueue)
        let transactions = [mockTransaction]

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
                XCTFail("Callback With PID:")
            }
            XCTAssertTrue(isPaymentCallbackCalled)
        }
        paymentQueueController.startPayment(mockPayment)
        paymentQueueController.paymentQueue(SKPaymentQueue(), updatedTransactions: transactions)
    }

    func mockPayment(productIdentifier: String, quantity:Int = 1, needToDownloadContent: Bool = true, completion: @escaping (PurchaseResult) -> Void) -> Payment {
        let mockProduct = MockProduct(productIdentifier: productIdentifier)

        return Payment(product: mockProduct, quantity: quantity, needToDownloadContent: needToDownloadContent, completion: completion)
    }

    func makeMockTransactionPayment(productId: String, transactionState: SKPaymentTransactionState) -> MockPaymentTransaction {
        let mockProduct = MockProduct(productIdentifier: productId)
        return MockPaymentTransaction(payment: SKPayment(product: mockProduct),transactionState: transactionState)
    }
}
