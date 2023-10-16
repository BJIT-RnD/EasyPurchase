//
//  MockPaymentQueue.swift
//  
//
//  Created by apple on 09.10.2023.
//

import Foundation
import StoreKit
@testable import EasyPurchase

/// Define a mock payment queue that conforms to the `InAppPaymentQueue` protocol
class MockPaymentQueue: InAppPaymentQueue {
    func restoreCompletedTransactions(withApplicationUsername username: String?) {
        //
    }

    // MARK: - PROPERTIES
    var addedObserver: SKPaymentTransactionObserver?
    var addedPayment: [SKPayment] = []
    var transactionCount = 0

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
    
    func finishTransaction(_ transaction: SKPaymentTransaction) {
        transactionCount += 1
    }
}
