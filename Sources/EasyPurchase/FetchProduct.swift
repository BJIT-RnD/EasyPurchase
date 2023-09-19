//
//  FetchProduct.swift
//  EasyPurchase
//
//  Created by Sadat Ahmed on 19.09.2023.
//

import Foundation
import StoreKit

// Protocol defining actions that can be performed on an in-app product request
protocol InAppRequestActions: AnyObject {
    func start()
    func cancel()
}

// Protocol extending InAppRequestActions and adding additional properties
protocol InAppProductRequest: InAppRequestActions {
    var isCompleted: Bool { get }
    var cachedProducts: Products? { get }
}

class FetchProduct : NSObject, SKProductsRequestDelegate, InAppProductRequest {
    private var productCompletionHandler: ProductComplitionHandler?
    private var productRequest: SKProductsRequest?

    // Boolean to track if the request is completed
    var isCompleted: Bool = false

    // Cached products result
    var cachedProducts: Products?

    init(productIds: Set<String>, productComplitionHandler: @escaping ProductComplitionHandler) {
        super.init()
        self.productCompletionHandler = productComplitionHandler
        productRequest = SKProductsRequest(productIdentifiers: productIds)
        productRequest?.delegate = self
    }

    // SKProductsRequestDelegate method for handling successful responses
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        let retrievedProducts = response.products
        let invalidProductIDs = response.invalidProductIdentifiers

        let products = Products(retrievedProducts: Set(retrievedProducts), invalidProductIDs: Set(invalidProductIDs), error: nil)
        cachedProducts = products
        isCompleted = true
        productCompletionHandler?(products)
        productRequest = nil
    }

    // Method to start the product request
    func start() {
        productRequest?.start()
    }

    // Method to cancel the product request
    func cancel() {
        productRequest?.cancel()
    }

    // SKRequestDelegate method for handling errors
    func request(_ request: SKRequest, didFailWithError error: Error) {
        let products = Products(retrievedProducts: nil, invalidProductIDs: nil, error: error)
        cachedProducts = products
        isCompleted = true
        productCompletionHandler?(products)
        productRequest = nil
    }
}

