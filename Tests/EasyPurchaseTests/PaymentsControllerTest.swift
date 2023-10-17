//
//  PaymentsControllerTest.swift
//  
//
//  Created by apple on 17.10.2023.
//

import XCTest
import StoreKit
@testable import EasyPurchase


// MARK: - PaymentsControllerTests
class PaymentsControllerTest: XCTestCase {
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

   func testProcessTransactionPurchasing() {
       let transaction = MockPaymentTransaction(payment: SKPayment(product: MockProduct(productIdentifier: "com.bjitgroup.easypurchase.consumable.tencoin")), transactionState: .purchasing)
       let result = paymentsController.processTransaction(transaction, on: mockPaymentQueue)
       XCTAssertTrue(result)
   }

   func testProcessTransactionPurchased() {
       let transaction = MockPaymentTransaction(payment: SKPayment(product: MockProduct(productIdentifier: "com.bjitgroup.easypurchase.consumable.twentycoin")), transactionState: .purchased)
       let result = paymentsController.processTransaction(transaction, on: mockPaymentQueue)
       XCTAssertTrue(result)
   }

   func testProcessTransactionFailed() {
       let transaction = MockPaymentTransaction(payment: SKPayment(product: MockProduct(productIdentifier: "com.bjitgroup.easypurchase.consumable.thirtycoin")), transactionState: .failed)
       let result = paymentsController.processTransaction(transaction, on: mockPaymentQueue)
       XCTAssertTrue(result)
   }

   func testProcessTransactionRestored() {
       let transaction = MockPaymentTransaction(payment: SKPayment(product: MockProduct(productIdentifier: "com.bjitgroup.easypurchase.consumable.tencoin")), transactionState: .restored)
       let result = paymentsController.processTransaction(transaction, on: mockPaymentQueue)
       XCTAssertFalse(result)
   }

   func testProcessTransactionDeferred() {
       let transaction = MockPaymentTransaction(payment: SKPayment(product: MockProduct(productIdentifier: "com.bjitgroup.easypurchase.consumable.twentycoin")), transactionState: .deferred)
       let result = paymentsController.processTransaction(transaction, on: mockPaymentQueue)
       XCTAssertTrue(result)
   }

    // TODO: NOT COMPLETED YET......
   func testProcessTransactions() {
       let productId = "com.bjitgroup.easypurchase.consumable.tencoin"
       let productOne = MockProduct(productIdentifier: productId)
       let productTwo = MockProduct(productIdentifier: productId)
       
       var isCompletionCalled = false
       let paymentOne = MockPayment(product: productOne) { result in
           isCompletionCalled = true
           if case .success(let purchase) = result {
               XCTAssertEqual(purchase.product.productIdentifier, productId)
           } else if case .failure(let error) = result {
               XCTAssertNotNil(error)
           }
       }
       
       var isCompletionCalledTwo = false
       let paymentTwo = MockPayment(product: productTwo) { result in
           isCompletionCalledTwo = true
           if case .failure(let error) = result {
               XCTAssertNotNil(error)
           } else if case .success(let purchase) = result {
               XCTAssertEqual(purchase.product.productIdentifier, productId)
           }
       }
       let paymentsCon = MockPaymentsController(appendPayments: [paymentOne, paymentTwo])
       let transactionOne = MockPaymentTransaction(payment: SKPayment(product: productOne), transactionState: .purchased)
       let transactionTwo = MockPaymentTransaction(payment: SKPayment(product: productTwo), transactionState: .failed)
       let remainingTransactions = paymentsCon.processTransactions([transactionOne, transactionTwo], on: mockPaymentQueue)
       
       XCTAssertEqual(remainingTransactions.count, 1)

       // XCTAssertFalse(paymentsController.hasPayment(payment1))
       // XCTAssertFalse(paymentsController.hasPayment(payment2))

       XCTAssertTrue(isCompletionCalled)
       XCTAssertTrue(!isCompletionCalledTwo)

       XCTAssertEqual(mockPaymentQueue.transactionCount, 0)
       
//        let transaction1 = makeMockTransaction(withState: .purchased)
//        let transaction2 = makeMockTransaction(withState: .failed)
//
//        let transactions = [transaction1, transaction2]
//        let unhandledTransactions = paymentsController.processTransactions(transactions, on: mockPaymentQueue)
//
//        XCTAssertEqual(unhandledTransactions.count, 1)
       // XCTAssertEqual(paymentsController.unhandledTransactions.count, 1)
   }
   
   func MockPayment(product: SKProduct, quantity: Int = 1, needToDownloadContent: Bool = true, completion: @escaping (PurchaseResult) -> Void) -> Payment {
       return Payment(product: product, quantity: quantity, needToDownloadContent: needToDownloadContent, completion: completion)
   }
   
   func MockPaymentsController(appendPayments payments: [Payment]) -> PaymentsController {
       let paymentsController = PaymentsController()
       payments.forEach { paymentsController.append($0) }
       return paymentsController
   }
}
