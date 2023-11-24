//
//  ProductInfoController.swift
//
//
//  Created by BJIT on 19/9/23.
//
import Foundation
import StoreKit

// A protocol for handling product information retrieval.
protocol ProductsInfoHandler: AnyObject {
    // A method to fetch product information for a set of product IDs.
    // - Parameters:
    //   - productIds: A set of product IDs to fetch information for.
    //   - completion: A closure that takes a `Products` object as its parameter
    //     and is called when the product information retrieval is completed.
    // - Returns: An `InAppProductRequest` object that can be used to start the request.
    func fetchProductsInfo(_ productIds: Set<String>, completion: @escaping (InAppProduct) -> Void) -> InAppProductRequest
}

// A class that conforms to the `ProductsInfoHandler` protocol.
public class ProductInfoController: NSObject, ProductsInfoHandler {
    // An instance of `InAppProductFetcherBuilder` used to build product retrieval requests.
    public var fetchProductBuilder = InAppProductFetcherBuilder()

    public init(fetchProductBuilder: InAppProductFetcherBuilder = InAppProductFetcherBuilder()) {
        self.fetchProductBuilder = fetchProductBuilder
    }

    // Implementation of the `fetchProductsInfo` method as required by the protocol.
    // It initiates the product retrieval request and returns an `InAppProductRequest` object.
    public func fetchProductsInfo(_ productIds: Set<String>, completion: @escaping (InAppProduct) -> Void) -> InAppProductRequest {
        // Use the builder to create the request, passing in the product IDs and completion closure.
        return fetchProductBuilder.request(productIds: productIds, callback: completion)
    }
    // Implementation of the `refreshReceipt` method as required by the protocol.
    // It initiates the product retrieval request and returns an `InAppProductRequest` object.
    public func refreshReceipt(completion: @escaping (RefreshReceiptStatus) -> Void) -> InAppProductRequest {
        return fetchProductBuilder.requestReceipt(callback: completion)
    }
}
