//
//  CompleteTransactionControllerTests.swift
//
//
//  Created by Sadat Ahmed on 19.10.2023.
//

import XCTest
import StoreKit
@testable import EasyPurchase

/// A test suite for the `CompleteTransactionController` class.
final class CompleteTransactionControllerTests: XCTestCase {
    var paymentQueue: MockPaymentQueue!
    override func setUp() {
        super.setUp()
        paymentQueue = MockPaymentQueue()
    }

    override func tearDown() {
        super.tearDown()
        paymentQueue = nil
    }
    // MARK: - TEST CASES
    /// Test the processing of zero transactions with atomic processing.
    func testProcessZeroTransactionsWithAtomicProcessing() {
        let transaction: [MockPaymentTransaction] = []
        var isCallbacked = false
        let processedTransaction = ProcessedTransactions { _ in
            isCallbacked = true
            XCTFail("Completion should not back")
        }
        let completeTransactionController = mockCompleteTransactionsController(processedTransactions: processedTransaction)
        let leftoverTransaction = completeTransactionController.processTransactions(transaction, on: paymentQueue)

        XCTAssertFalse(isCallbacked)
        XCTAssertEqual(leftoverTransaction.count, 0)
        XCTAssertEqual(paymentQueue.transactionCount, 0)
    }

    /// Test the processing of transactions with atomic processing and multiple transaction states.
    func testProcessTransactionsWithAtomicProcessingAndMultipleStates() {
        let transactions = [
            MockPaymentTransaction(payment: SKPayment(product: MockProduct(productIdentifier: "com.bjitgroup.easypurchase.consumable.tencoin")), transactionState: .purchased),
            MockPaymentTransaction(payment: SKPayment(product: MockProduct(productIdentifier: "com.bjitgroup.easypurchase.consumable.twentycoin")), transactionState: .failed),
            MockPaymentTransaction(payment: SKPayment(product: MockProduct(productIdentifier: "com.bjitgroup.easypurchase.consumable.thirtycoin")), transactionState: .restored),
            MockPaymentTransaction(payment: SKPayment(product: MockProduct(productIdentifier: "com.bjitgroup.easypurchase.consumable.tencoin")), transactionState: .deferred),
            MockPaymentTransaction(payment: SKPayment(product: MockProduct(productIdentifier: "com.bjitgroup.easypurchase.consumable.twentyoin")), transactionState: .purchasing)
        ]

        var isCallbacked = false
        let processedTransaction = ProcessedTransactions { purchases in
            isCallbacked = true
            XCTAssertEqual(purchases.count, 4)
            for i in 0..<4 {
                XCTAssertEqual(purchases[i].productId, transactions[i].payment.productIdentifier)
            }
        }
        let completeTransactionController = mockCompleteTransactionsController(processedTransactions: processedTransaction)
        let leftoverTransaction = completeTransactionController.processTransactions(transactions, on: paymentQueue)

        XCTAssertEqual(leftoverTransaction.count, 1)
        XCTAssertTrue(isCallbacked)
        XCTAssertEqual(paymentQueue.transactionCount, 4)
    }

    /// Test the processing of a single purchasing transaction with atomic processing.
    func testProcessOnePurchasingTransactionWithAtomicProcessing() {
        // Define a single transaction with a purchasing state
        let id = "com.bjitgroup.easypurchase.consumable.thirtycoin"
        let mockProduct = MockProduct(productIdentifier: id)
        let transaction = MockPaymentTransaction(payment: SKPayment(product: mockProduct), transactionState: .purchasing)

        let processedTransactions = ProcessedTransactions { _ in
            XCTFail("Completion should not back")
        }
        let completeTransactionsController = mockCompleteTransactionsController(processedTransactions: processedTransactions)
        let leftoverTransaction = completeTransactionsController.processTransactions([transaction], on: paymentQueue)
        // Assertions
        XCTAssertEqual(leftoverTransaction.count, 1)
        XCTAssertEqual(paymentQueue.transactionCount, 0)
    }

    /// Test the processing of a restored transaction with a successful callback.
    func testProcessRestoredTransactionWithSucessfulCallback() {
        let id = "com.bjitgroup.easypurchase.consumable.tencoin"
        let mockProduct = MockProduct(productIdentifier: id)

        var isCallbacked = false
        let processedTransactions = ProcessedTransactions { purchases in
            isCallbacked = true
            XCTAssertEqual(purchases.count, 1)
            XCTAssertEqual(purchases.first?.productId, id)
        }

        let mockPaytransaction = MockPaymentTransaction(payment: SKPayment(product: mockProduct), transactionState: .restored)
        let completeTransactionsController = mockCompleteTransactionsController(processedTransactions: processedTransactions)
        let leftoverTransactions = completeTransactionsController.processTransactions([mockPaytransaction], on: paymentQueue)

        XCTAssertEqual(leftoverTransactions.count, 0)
        XCTAssertTrue(isCallbacked)
        XCTAssertEqual(paymentQueue.transactionCount, 1)
    }

    /// Test the processing of a failed transaction with a failed completion callback and no need to finish the transaction.
    func testProcessFailedTransactionWithFailedCompletionBackAndNoNeedFinishTransaction() {
        let id = "com.bjitgroup.easypurchase.consumable.twentycoin"
        let mockProduct = MockProduct(productIdentifier: id)
        var isCallbacked = false
        let processedTransaction = ProcessedTransactions { purchases in
            isCallbacked = true
            XCTAssertEqual(purchases.count, 1)
            XCTAssertEqual(purchases.first?.productId, id)
            XCTAssertFalse(purchases.first!.needsFinishTransaction)
        }
        let mockPayTransaction = MockPaymentTransaction(payment: SKPayment(product: mockProduct), transactionState: .failed)
        let completeTransactionController = mockCompleteTransactionsController(processedTransactions: processedTransaction)
        let leftoverTransactions = completeTransactionController.processTransactions([mockPayTransaction], on: paymentQueue)
        XCTAssertEqual(leftoverTransactions.count, 0)
        XCTAssertTrue(isCallbacked)
        XCTAssertEqual(paymentQueue.transactionCount, 1)
    }

    /// Test the processing of failed transactions without atomic processing.
    func testProcessFailedTransactionsWithoutAtomicProcessing() {
        let id = "com.bjitgroup.easypurchase.consumable.twentycoin"
        let mockProduct = MockProduct(productIdentifier: id)
        var isCallbacked = false
        let processedTransaction = ProcessedTransactions(atomically: false) { purchases in
            isCallbacked = true
            XCTAssertEqual(purchases.count, 1)
            XCTAssertEqual(purchases.first?.productId, id)
            XCTAssertFalse(purchases.first!.needsFinishTransaction)
        }

        let mockPayTransaction = MockPaymentTransaction(payment: SKPayment(product: mockProduct), transactionState: .failed)
        let completeTransactionController = mockCompleteTransactionsController(processedTransactions: processedTransaction)
        let leftoverTransaction = completeTransactionController.processTransactions([mockPayTransaction], on: paymentQueue)

        XCTAssertEqual(paymentQueue.transactionCount, 1)
        XCTAssertEqual(leftoverTransaction.count, 0)
        XCTAssertTrue(isCallbacked)
    }

    // MARK: - HELPER METHODS
    /// Helper method to create a `CompleteTransactionController` with the provided `ProcessedTransactions`.
    /// - Parameter processedTransactions: The `ProcessedTransactions` to associate with the controller.
    /// - Returns: A `CompleteTransactionController` with the specified `ProcessedTransactions`.
    func mockCompleteTransactionsController(processedTransactions: ProcessedTransactions?) -> CompleteTransactionController {
        let completeTransactionsController = CompleteTransactionController()
        completeTransactionsController.processedTransactions = processedTransactions
        return completeTransactionsController
    }
}
