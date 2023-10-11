//
//  MockProduct.swift
//  
//
//  Created by apple on 09.10.2023.
//

import Foundation
import StoreKit

class MockProduct: SKProduct {
    var _productIdentifier: String = ""

    override var productIdentifier: String {
        return _productIdentifier
    }

    init(productIdentifier: String) {
        super.init()
        self._productIdentifier = productIdentifier
    }
}
