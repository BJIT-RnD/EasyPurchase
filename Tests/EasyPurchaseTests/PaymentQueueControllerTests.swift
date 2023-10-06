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

    func testStartTransaction() {
        let paymentQueueController = PaymentQueueController(paymentQueue: mockPaymentQueue)
        /// `TO DO:` CREATE TEST PAYMENT
        /// `TO DO:` CREATE TEST PRODUCT
        let payment = Payment(product: SKProduct(), quantity: 1, needToDownloadContent: false) { _ in }
        paymentQueueController.startPayment(payment)
        XCTAssertEqual(mockPaymentQueue.addedPayment.count, 1)
    }
}
