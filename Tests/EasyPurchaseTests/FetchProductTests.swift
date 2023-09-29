//
//  FetchProductTests.swift
//  
//
//  Created by BJIT on 29/9/23.
//

import XCTest
import StoreKitTest
@testable import EasyPurchase

class FetchProductTests: XCTestCase {

    // Create a test double for InAppProductFetcherBuilder
    class MockFetchProductBuilder: InAppProductFetcherBuilder {
        override func request(productIds: Set<String>, callback: @escaping ProductCompletionHandler) -> InAppProductRequest {
            return MockInAppProductRequest(productIds: productIds, productCompletionHandler: callback)
        }
    }

    // Mock Products
    class MockSKProduct: SKProduct {
        private var mockProductIdentifier: String

        override var productIdentifier: String {
            return mockProductIdentifier
        }

        // Initialize the mock SKProduct with the necessary information
        init(productIdentifier: String) {
            self.mockProductIdentifier = productIdentifier
            super.init()
        }
    }

    // Create a test double for InAppProductRequest
    class MockInAppProductRequest: InAppProductRequest {
        var isCompleted: Bool = false
        var cachedProducts: Product?
        var productCompletionHandler: ProductCompletionHandler?

        init(productIds: Set<String>, productCompletionHandler: @escaping ProductCompletionHandler) {
            self.productCompletionHandler = productCompletionHandler
        }

        func start() {
            // Simulate the start of the product request
            isCompleted = false
        }

        func cancel() {
            // Simulate the cancellation of the product request
            isCompleted = true
        }
    }

    func testFetchProductsInfo() {
        // Create a ProductInfoController instance with the mock fetch product builder
        let productInfoController = ProductInfoController(fetchProductBuilder: MockFetchProductBuilder())
        var req: InAppProductRequest!

        // Define the expected product identifiers
        let productIdentifiers: Set<String> = ["com.bjitgroup.easypurchase.consumable.tencoin", "com.bjitgroup.easypurchase.consumable.twentycoin"]

        // Create an expectation for the completion handler
        let expectation = XCTestExpectation(description: "Product info fetch failed")

        // Perform the product info fetch
        req = productInfoController.fetchProductsInfo(productIdentifiers) { product in
            // Verify the product response
            XCTAssertNotNil(product)
            XCTAssertEqual(product.retrievedProducts?.count, 2) // Adjust as needed
            XCTAssertNil(product.invalidProductIDs)
            XCTAssertNil(product.error)

            // Fulfill the expectation
            expectation.fulfill()
        }
        req.start()

        // Simulate the response by calling the completion handler of the mock request
        if let mockRequest = productInfoController.fetchProductBuilder.request(productIds: productIdentifiers, callback: { _ in }) as? MockInAppProductRequest {

            // Create mock SKProduct instances (replace with your actual mock products)
            let mockProduct1 = MockSKProduct(productIdentifier: "com.bjitgroup.easypurchase.consumable.tencoin")

            let mockProduct2 = MockSKProduct(productIdentifier: "com.bjitgroup.easypurchase.consumable.twentycoin")

            // Set the retrieved products in the mock response
            mockRequest.cachedProducts = Product(
                retrievedProducts: Set([mockProduct1, mockProduct2]),
                invalidProductIDs: nil,
                error: nil
            )

            mockRequest.isCompleted = true
            mockRequest.productCompletionHandler?(mockRequest.cachedProducts!)
        }

        // Wait for the expectation to be fulfilled (adjust the timeout as needed)
        wait(for: [expectation], timeout: 10.0)
    }
}
