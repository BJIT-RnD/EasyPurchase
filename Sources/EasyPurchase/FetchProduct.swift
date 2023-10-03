//
//  FetchProduct.swift
//  EasyPurchase
//
//  Created by Sadat Ahmed on 19.09.2023.
//

import Foundation
import StoreKit

/// A protocol defining the fundamental actions for managing in-app purchase requests, allowing them to be started and canceled.
public protocol InAppRequestActions: AnyObject {
    func start()
    func cancel()
}

extension SKProductsRequest: InAppRequestActions{  }

/// A protocol defining the requirements for an in-app product request, including actions to start and cancel the request, tracking completion status, and caching product information.
public protocol InAppProductRequest: InAppRequestActions {
    var isCompleted: Bool { get }
    var cachedProducts: Product? { get }
}

/// A class responsible for fetching in-app products from the Apple Store and managing the product request lifecycle.
class FetchProduct : NSObject, InAppProductRequest {
    var productCompletionHandler: ProductCompletionHandler?
    var productRequest: SKProductsRequest?

    var isCompleted: Bool = false
    var cachedProducts: Product?

    /// Initializes a FetchProduct instance with the specified product identifiers and a completion handler.
    /// - Parameters:
    ///   - productIds: A set of product identifiers for the requested in-app products.
    ///   - productComplitionHandler: A closure to be called when the product request is completed.
    init(productIds: Set<String>, productCompletionHandler: @escaping ProductCompletionHandler) {
        super.init()
        self.productCompletionHandler = productCompletionHandler
        productRequest = SKProductsRequest(productIdentifiers: productIds)
        productRequest?.delegate = self
    }

    // Method to start the product request
    func start() {
        productRequest?.start()
    }

    // Method to cancel the product request
    func cancel() {
        productRequest?.cancel()
    }
}

extension FetchProduct: SKProductsRequestDelegate {
    /// Called when an SKProductsRequest receives a response containing product information.
    /// - Parameters:
    ///   - request: The SKProductsRequest that received the response.
    ///   - response: The SKProductsResponse containing product information.
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        let retrievedProducts = response.products
        let invalidProductIDs = response.invalidProductIdentifiers

        let products = Product(retrievedProducts: Set(retrievedProducts), invalidProductIDs: Set(invalidProductIDs), error: nil)
        cachedProducts = products
        isCompleted = true
        productCompletionHandler?(products)
        productRequest = nil
    }

    /// Called when an SKRequest encounters an error during execution.
    /// - Parameters:
    ///   - request: The SKRequest that encountered an error.
    ///   - error: The error that occurred during the request.
    func request(_ request: SKRequest, didFailWithError error: Error) {
        let products = Product(retrievedProducts: nil, invalidProductIDs: nil, error: error)
        cachedProducts = products
        isCompleted = true
        productCompletionHandler?(products)
        productRequest = nil
    }
}
