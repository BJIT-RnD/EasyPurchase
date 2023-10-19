//
//  PaymentsControllerTest.swift
//  
//
//  Created by apple on 17.10.2023.
//

import XCTest
import StoreKit
@testable import EasyPurchase

/// Unit tests for the `PaymentsController` class.
class PaymentsControllerTests: XCTestCase {
    // MARK: - PROPERTIES
    var paymentsController: PaymentsController!
    var mockPaymentQueue: MockPaymentQueue!

    override func setUp() {
        super.setUp()
        paymentsController = PaymentsController()
        mockPaymentQueue = MockPaymentQueue()
    }

    override func tearDown() {
        super.tearDown()
        paymentsController = nil
        mockPaymentQueue = nil
    }

    // MARK: - TEST CASES
    /// Tests the processing of a transaction with a purchasing state and successful completion.
    func testProcessTransactionPurchasingSuccess() {
        let productId = "com.bjitgroup.easypurchase.consumable.tencoin"
        let mockProduct = MockProduct(productIdentifier: productId)
        let payment = mockPayment(product: mockProduct) { result in
            if case .success(let purchase) = result {
                XCTAssertEqual(purchase.product, mockProduct)
            } else {
                XCTFail("Expected a callback.")
            }
        }
         paymentsController.append(payment)
        let transaction = MockPaymentTransaction(payment: SKPayment(product: mockProduct), transactionState: .purchasing)
        XCTAssertTrue(paymentsController.processTransaction(transaction, on: mockPaymentQueue))
        XCTAssertTrue(!paymentsController.payments.isEmpty)
    }

    /// Tests the processing of a transaction with a restored state and successful completion.
    func testProcessTransactionRestoredAndFinishedTransactionSuccess() {
        let productId = "com.bjitgroup.easypurchase.consumable.tencoin"
        let mockProduct = MockProduct(productIdentifier: productId)
        let payment = mockPayment(product: mockProduct) { result in
            if case .success(let purchase) = result {
                XCTAssertEqual(purchase.product, mockProduct)
            } else {
                XCTFail("Expected a callback.")
            }
        }
         paymentsController.append(payment)
        let transaction = MockPaymentTransaction(payment: SKPayment(product: mockProduct), transactionState: .restored)
        XCTAssertTrue(paymentsController.processTransaction(transaction, on: mockPaymentQueue))
        XCTAssertTrue(paymentsController.payments.isEmpty)
        XCTAssertEqual(mockPaymentQueue.transactionCount, 1)
    }

    /// Tests the processing of a transaction with a restored state and failed completion.
    func testProcessTransactionRestoredAndFinishedTransactionFailure() {
        let productId = "com.bjitgroup.easypurchase.consumable.tencoin"
        let mockProduct = MockProduct(productIdentifier: productId)
        let payment = mockPayment(product: mockProduct) { result in
            if case .success(let purchase) = result {
                XCTAssertEqual(purchase.product, mockProduct)
            } else {
                XCTFail("Expected a callback.")
            }
        }
         paymentsController.append(payment)
        let transaction = MockPaymentTransaction(payment: SKPayment(product: mockProduct), transactionState: .deferred)
        XCTAssertTrue(paymentsController.processTransaction(transaction, on: mockPaymentQueue))
        XCTAssertTrue(!paymentsController.payments.isEmpty)
        XCTAssertEqual(mockPaymentQueue.transactionCount, 0)
    }

    /// Tests the processing of a transaction with a deferred state.
    func testProcessTransactionDeferred() {
        let productId = "com.bjitgroup.easypurchase.consumable.tencoin"
        let mockProduct = MockProduct(productIdentifier: productId)
        let payment = mockPayment(product: mockProduct) { result in
            if case .success(let purchase) = result {
                XCTAssertEqual(purchase.product, mockProduct)
            } else {
                XCTFail("Expected a callback.")
            }
        }
         paymentsController.append(payment)
        let transaction = MockPaymentTransaction(payment: SKPayment(product: mockProduct), transactionState: .deferred)
        XCTAssertTrue(paymentsController.processTransaction(transaction, on: mockPaymentQueue))
        XCTAssertTrue(!paymentsController.payments.isEmpty)
    }

    /// Tests the processing of two transactions with the same product identifier, one successful and one failed.
    func testProcessTransactionsOfTwoPaymentWithSameProductIdPurchasedAndFailure() {
        let productId = "com.bjitgroup.easypurchase.consumable.tencoin"
        let productOne = MockProduct(productIdentifier: productId)
        let productTwo = MockProduct(productIdentifier: productId)

        var isCompletionCalled = false
        let paymentOne = mockPayment(product: productOne) { result in
            isCompletionCalled = true
            if case .success(let purchase) = result {
                XCTAssertEqual(purchase.product.productIdentifier, productId)
            } else {
                XCTFail("Purchased Callback with id")
            }
        }

        var isCompletionCalledTwo = false
        let paymentTwo = mockPayment(product: productTwo) { result in
            isCompletionCalledTwo = true
            if case .failure(let error) = result {
                XCTAssertNotNil(error)
            } else {
                XCTFail("Failed Callback With Error")
            }
        }
        let mockPaymentsController = mockPaymentsController([paymentOne, paymentTwo])
        let transactionOne = MockPaymentTransaction(payment: SKPayment(product: productOne), transactionState: .purchased)
        let transactionTwo = MockPaymentTransaction(payment: SKPayment(product: productTwo), transactionState: .failed)
        let remainingTransactions = mockPaymentsController.processTransactions([transactionOne, transactionTwo], on: mockPaymentQueue)

        XCTAssertEqual(remainingTransactions.count, 0)
        XCTAssertEqual(mockPaymentQueue.transactionCount, 2)
        XCTAssertTrue(isCompletionCalled)
        XCTAssertTrue(isCompletionCalledTwo)
    }

    /// Tests the processing of a transaction with a purchased state and quantity set to 2, with successful completion.
    func testProcessTransactionsOfATransactionStatePurchased_QuantityIs2CallbackWithCurrectQuantitySuccess() {
        let productIdentifier = "com.bjitgroup.easypurchase.consumable.tencoin"
        let quantity = 3
        let mockProduct = MockProduct(productIdentifier: productIdentifier)
        var isCalledBack = false
        let payment = mockPayment(product: mockProduct, quantity: quantity) { result in
            isCalledBack = true
            if case .success(let purchase) = result {
                XCTAssertEqual(purchase.product.productIdentifier, productIdentifier)
                XCTAssertEqual(purchase.quantity, quantity)
            } else {
                XCTFail("Product Id Callback of Purchased.")
            }
        }
        let mockPaymentsController = mockPaymentsController([payment])
        let skPayment = SKMutablePayment(product: mockProduct)
        skPayment.quantity = quantity
        let transaction = MockPaymentTransaction(payment: skPayment, transactionState: .purchased)
        let remainingTransaction = mockPaymentsController.processTransactions([transaction], on: mockPaymentQueue)
        XCTAssertEqual(remainingTransaction.count, 0)
        XCTAssertTrue(isCalledBack)
        XCTAssertEqual(mockPaymentQueue.transactionCount, 1)
    }

    /// Tests the processing of a single transaction with a purchased state and successful completion.
    func testProcessTransactionsOfSinglePaymentPurchasedStateAndCallbackSuccess() {
        let id = "com.bjitgroup.easypurchase.consumable.tencoin"
        let mockProduct = MockProduct(productIdentifier: id)
        var isCallBacked = false
        let payment = mockPayment(product: mockProduct) { result in
            isCallBacked = true
            if case .success(let purchase) = result {
                XCTAssertEqual(purchase.product.productIdentifier, id)
            } else {
                XCTFail("Callback with product id")
            }
        }
        let mockPaymentsController = mockPaymentsController([payment])
        let transaction = MockPaymentTransaction(payment: SKPayment(product: mockProduct), transactionState: .purchased)
        let remainingTransaction = mockPaymentsController.processTransactions([transaction], on: mockPaymentQueue)

        XCTAssertEqual(remainingTransaction.count, 0)
        XCTAssertEqual(mockPaymentQueue.transactionCount, 1)
        XCTAssertTrue(isCallBacked)
    }

    /// Tests the processing of a single transaction with a failed state and successful completion.
    func testProcessTransactionsOfSinglePaymentFailedTransactionStateAndCallbackSuccess() {
        let id = "com.bjitgroup.easypurchase.consumable.twentycoin"
        let mockProduct = MockProduct(productIdentifier: id)
        var isCallbackCalled = false
        let payment = mockPayment(product: mockProduct) { result in
            isCallbackCalled = true
            if case .failure(let error) = result {
                XCTAssertNotNil(error)
            } else {
                XCTFail("Should Callback with error")
            }
        }
        let mockPaymentsController = mockPaymentsController([payment])
        let mockTransaction = MockPaymentTransaction(payment: SKPayment(product: mockProduct), transactionState: .failed)
        let remainingTransaction = mockPaymentsController.processTransactions([mockTransaction], on: mockPaymentQueue)

        XCTAssertEqual(remainingTransaction.count, 0)
        XCTAssertTrue(isCallbackCalled)
        XCTAssertEqual(mockPaymentQueue.transactionCount, 1)
    }

    // MARK: - HELPER METHODS

    /// Creates a mock `Payment` with the specified parameters and completion handler.
        ///
        /// - Parameters:
        ///   - product: The product associated with the payment.
        ///   - quantity: The quantity of the product.
        ///   - needToDownloadContent: A flag indicating whether content download is needed.
        ///   - completion: A callback for handling the purchase result.
        /// - Returns: The created `Payment` object.
    func mockPayment(product: SKProduct, quantity: Int = 1, needToDownloadContent: Bool = true, completion: @escaping (PurchaseResult) -> Void) -> Payment {
        return Payment(product: product, quantity: quantity, needToDownloadContent: needToDownloadContent, completion: completion)
    }

    /// Creates a `PaymentsController` and appends a list of payments to it.
        /// - Parameter payments: An array of `Payment` objects to be added to the controller.
        /// - Returns: The initialized `PaymentsController` with added payments.
    func mockPaymentsController(_ payments: [Payment]) -> PaymentsController {
        let paymentsController = PaymentsController()
        payments.forEach { paymentsController.append($0) }
        return paymentsController
    }
}
