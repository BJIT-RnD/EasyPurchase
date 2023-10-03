//
//  InAppProductFetcherBuilder.Swift
//
//
//  Created by BJIT on 19/9/23.
//
import Foundation
import StoreKit
// Define a typealias for a product completion handler closure.
public typealias ProductCompletionHandler = (Product) -> Void

// MARK: Protocols

// A protocol for a product request builder.
public protocol FetchProductBuilder: AnyObject {
    // A method to create and initiate a product retrieval request.
    // - Parameters:
    //   - productIds: A set of product IDs to fetch information for.
    //   - callback: A closure that takes a `Products` object as its parameter
    //     and is called when the product information retrieval is completed.
    // - Returns: An `InAppProductRequest` object representing the request.
    func request(productIds: Set<String>, callback: @escaping ProductCompletionHandler) -> InAppProductRequest
}

// MARK: Classes

// A class that implements the `FetchProductBuilder` protocol.
public class InAppProductFetcherBuilder: FetchProductBuilder {
    // Implementation of the `request` method as required by the protocol.
    // It creates an `InAppProductRequest` object for product retrieval.
    public init() {}
    public func request(productIds: Set<String>, callback: @escaping ProductCompletionHandler) -> InAppProductRequest {
        // Create and return an `InAppProductRequest` with the provided product IDs and callback.
        return FetchProduct(productIds: productIds, productCompletionHandler: callback)
    }
}

