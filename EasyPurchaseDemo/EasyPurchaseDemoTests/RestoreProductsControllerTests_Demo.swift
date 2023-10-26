//
//  File.swift
//
//
//  Created by BJIT on 18/10/23.
//

import Foundation
import XCTest
import StoreKit
@testable import EasyPurchase

class RestoreProductsControllerTests: XCTestCase {

    var callbackCalled: Bool = false

    override func setUp() {
        super.setUp()
        callbackCalled = false
    }

    // Helper function to verify the callback results
    func verifyCallbackResults(results: [InAppTransactionActionsResult], productIdentifiers: [String]) {
        XCTAssertEqual(results.count, productIdentifiers.count)
        for (index, result) in results.enumerated() {
            if case .restored(let restoredPurchase) = result {
                XCTAssertEqual(restoredPurchase.productId, productIdentifiers[index])
            } else {
                XCTFail("Expected restored callback with product")
            }
        }
    }

    // Test if the processTransactions method correctly handles one restored transaction
    func testProcessTransactions_oneRestoredTransaction() {
        let productIdentifier = "com.bjitgroup.easypurchase.nonconsumable.level"
        let transaction = MockPaymentTransaction(payment: SKPayment(product: MockProduct(productIdentifier: productIdentifier)),transactionState: .restored)

        let restorePurchases = RestoreProducts(atomically: true) { results in
            self.callbackCalled = true
            self.verifyCallbackResults(results: results, productIdentifiers: [productIdentifier])
        }

        let restorePurchasesController = makeRestorePurchasesController(restorePurchases: restorePurchases)

        let mockQueue = MockPaymentQueue()

        let remainingTransactions = restorePurchasesController.processTransactions([transaction], on: mockQueue)
        restorePurchasesController.restoreCompletedTransactionsFinished()

        // Verify that there are no remaining transactions, the callback was called, and finishTransaction was called
        XCTAssertEqual(remainingTransactions.count, 0)
        XCTAssertTrue(callbackCalled)
        XCTAssertEqual(mockQueue.transactionCount, 1)
    }

    // Test if the processTransactions method correctly handles two restored transactions
    func testProcessTransactions_twoRestoredTransactions() {
        let productIdentifiers = [
            "com.bjitgroup.easypurchase.nonconsumable.levelone",
            "com.bjitgroup.easypurchase.nonconsumable.leveltwo"
        ]

        let transactions: [SKPaymentTransaction] = productIdentifiers.map {
            return MockPaymentTransaction(payment: SKPayment(product: MockProduct(productIdentifier: $0)),transactionState: .restored)
        }

        let restorePurchases = RestoreProducts(atomically: true) { results in
            self.callbackCalled = true
            self.verifyCallbackResults(results: results, productIdentifiers: productIdentifiers)
        }

        let restorePurchasesController = makeRestorePurchasesController(restorePurchases: restorePurchases)

        let mockQueue = MockPaymentQueue()

        let remainingTransactions = restorePurchasesController.processTransactions(transactions, on: mockQueue)
        restorePurchasesController.restoreCompletedTransactionsFinished()

        XCTAssertEqual(remainingTransactions.count, 0)
        XCTAssertTrue(callbackCalled)
        XCTAssertEqual(mockQueue.transactionCount, 2)
    }

    // Test if the restoreCompletedTransactionsFailed method correctly calls the callback with an error
    func testRestoreCompletedTransactionsFailed() {
        let error = NSError(domain: "EasyPurchase", code: 0, userInfo: nil)

        let restorePurchases = RestoreProducts(atomically: true) { results in
            self.callbackCalled = true
            XCTAssertEqual(results.count, 1)
            if case .failed = results[0] {
            } else {
                XCTFail("Expected failed callback with error")
            }
        }

        let restorePurchasesController = makeRestorePurchasesController(restorePurchases: restorePurchases)

        restorePurchasesController.restoreCompletedTransactionsFailed(withError: error)
        XCTAssertTrue(callbackCalled)
    }

    // Test if the testRestoreCompletedTransactionsFinished method correctly returns
    func testRestoreCompletedTransactionsFinished() {
        let restorePurchases = RestoreProducts(atomically: true) { results in
            self.callbackCalled = true
            XCTAssertEqual(results.count, 0)
        }
        let restorePurchasesController = makeRestorePurchasesController(restorePurchases: restorePurchases)

        restorePurchasesController.restoreCompletedTransactionsFinished()
        XCTAssertTrue(callbackCalled)
    }

    // Test if the testResetRestorePurchasesToNil method correctly returns nil
    func testResetRestorePurchasesToNil() {
        let restorePurchasesController = RestoreProductsController()

        // Set up a non-nil RestoreProducts
        let restoreProducts = RestoreProducts(atomically: true) { _ in }
        restorePurchasesController.restoreProducts = restoreProducts

        // Call the resetRestorePurchasesToNil method
        restorePurchasesController.resetRestorePurchasesToNil()

        // Verify that restoreProducts is now nil
        XCTAssertNil(restorePurchasesController.restoreProducts)
    }

    // Helper method
    func makeRestorePurchasesController(restorePurchases: RestoreProducts?) -> RestoreProductsController {
        let restorePurchasesController = RestoreProductsController()
        restorePurchasesController.restoreProducts = restorePurchases
        return restorePurchasesController
    }
}
