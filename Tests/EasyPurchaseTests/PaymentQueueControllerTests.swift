//
//  PaymentQueueControllerTests.swift
//  
//
//  Created by BJIT on 06.10.2023.
//

import XCTest
import StoreKit
@testable import EasyPurchase

/// Define a mock payment queue that conforms to the `InAppPaymentQueue` protocol
class MockPaymentQueue: InAppPaymentQueue {
    // MARK: - PROPERTIES
    var addedObserver: SKPaymentTransactionObserver?
    var addedPayment: [SKPayment] = []

    // Mock implementation of adding an observer to the payment queue
    func add(_ observer: SKPaymentTransactionObserver) {
        self.addedObserver = observer
    }

    // Mock implementation of adding a payment to the payment queue
    func add(_ payment: SKPayment) {
        addedPayment.append(payment)
    }

    // Mock implementation of removing an observer from the payment queue
    func remove(_ observer: SKPaymentTransactionObserver) {
        if self.addedObserver === observer {
            self.addedObserver = nil
        }
    }
}

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
        XCTAssertTrue(mockPaymentQueue.addedObserver === pay)
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

    func mockPayment(productIdentifier: String, quantity:Int = 1, needToDownloadContent: Bool = true, completion: @escaping (PurchaseResult) -> Void) -> Payment {
        let mockProduct = MockProduct(productIdentifier: productIdentifier)

        return Payment(product: mockProduct, quantity: quantity, needToDownloadContent: needToDownloadContent, completion: completion)
    }
}
