//
//  MockPaymentTransaction.swift
//  
//
//  Created by apple on 09.10.2023.
//

import Foundation
import StoreKit

class MockPaymentTransaction: SKPaymentTransaction {
    let _payment: SKPayment
    let _transactionState: SKPaymentTransactionState

    init(payment: SKPayment, transactionState: SKPaymentTransactionState) {
        _payment = payment
        _transactionState = transactionState
    }

    override var transactionState: SKPaymentTransactionState {
        return _transactionState
    }

    override var payment: SKPayment {
        return _payment
    }
}
