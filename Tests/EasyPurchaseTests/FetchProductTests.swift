//
//  FetchProductTests.swift
//  
//
//  Created by BJIT on 29/9/23.
//
import XCTest
import StoreKit
@testable import EasyPurchase

// A mock implementation of InAppProductRequest for testing purposes
class MockInAppProductRequest: InAppProductRequest {
    var isCompleted: Bool = false
    var cachedProducts: InAppProduct?

    var completionHandler: ProductCompletionHandler?
    var mockError: Error?
    var mockInvalidProductIDs: Set<String>?

    init(productIds: Set<String>, productCompletionHandler: @escaping ProductCompletionHandler) {
        self.completionHandler = productCompletionHandler
    }

    // Simulate starting the mock product request
    func start() {
        if let mockError = mockError {
            // If a mock error is provided, simulate an error response
            let products = InAppProduct(retrievedProducts: nil, invalidProductIDs: mockInvalidProductIDs, error: mockError)
            cachedProducts = products
            isCompleted = true
            completionHandler?(products)
        } else {
            // Simulate a successful response with a dummy SKProduct
            let retrievedProducts: Set<SKProduct> = [SKProduct()]
            let invalidProductIDs: Set<String> = []
            let products = InAppProduct(retrievedProducts: retrievedProducts, invalidProductIDs: invalidProductIDs, error: nil)
            cachedProducts = products
            isCompleted = true
            completionHandler?(products)
        }
    }

    // Simulate canceling the mock product request
    func cancel() {
        isCompleted = true
        completionHandler?(InAppProduct(retrievedProducts: nil, invalidProductIDs: nil, error: nil))
    }
}

// A mock implementation of FetchProductBuilder for creating MockInAppProductRequest instances
class MockProductFetcherBuilder: FetchProductBuilder {
    func request(productIds: Set<String>, callback: @escaping ProductCompletionHandler) -> InAppProductRequest {
        // Create and return a MockInAppProductRequest instance
        return MockInAppProductRequest(productIds: productIds, productCompletionHandler: callback)
    }
}


// ProductInfoControllerTestsDemo is a test case class designed to test the functionality
// of the ProductInfoController class. It contains a test case that verifies the behavior of
// fetching a product with a valid identifier.
class FetchProductTests: XCTestCase {
    var productInfoController: ProductInfoController!
    var fetchProduct: FetchProduct!
    var mockProductCompletionHandler: ProductCompletionHandler!

    override func setUp() {
        super.setUp()
        // Create an instance of the ProductInfoController
        productInfoController = ProductInfoController()
        // Create a mock product completion handler
        mockProductCompletionHandler = { products in }
        // Initialize the FetchProduct instance with a mock SKProductsRequest
        fetchProduct = FetchProduct(productIds: ["com.example.product"], productCompletionHandler: mockProductCompletionHandler)
    }

    override func tearDown() {
        // Clean up resources if needed
        productInfoController = nil
        fetchProduct = nil
        mockProductCompletionHandler = nil
        super.tearDown()
    }

    func testFetchProductWithValidIdentifier() {
        let expectation = XCTestExpectation(description: "Product fetch completed")

        // Trigger the fetchProductsInfo method
        let expectedProductIdentifier = "com.bjitgroup.easypurchase.consumable.tencoin"

        // Trigger the fetchProductsInfo method
        let productIds: Set<String> = [expectedProductIdentifier]
        let productReq = productInfoController.fetchProductsInfo(productIds) { product in
            // Verify the product identifier
            if let retrievedProductIdentifier = product.retrievedProducts?.first?.productIdentifier {
                // Check if the retrieved identifier is a valid non-empty string
                XCTAssertTrue(!retrievedProductIdentifier.isEmpty)
                // You can add more specific criteria here if needed
            } else {
                XCTFail("No product identifier retrieved")
            }
            XCTAssertEqual(product.retrievedProducts?.first?.productIdentifier, expectedProductIdentifier)
            XCTAssertEqual(product.invalidProductIDs, [])
            XCTAssertNil(product.error)
            expectation.fulfill()
        }
        productReq.start()
        // Wait for the expectation to be fulfilled (or timeout)
        wait(for: [expectation], timeout: 5.0)
    }

    func testFetchProductWithInvalidIdentifier() {
        let expectation = XCTestExpectation(description: "Product fetch completed")
        // Define an invalid product identifier for testing
        let invalidProductIdentifier = "invalid.product.identifier"
        // Create a set containing the invalid product identifier
        let productIds: Set<String> = [invalidProductIdentifier]
        // Trigger the fetchProductsInfo method with the invalid product identifier
        let productReq = productInfoController.fetchProductsInfo(productIds) { product in
            if let retrievedProducts = product.retrievedProducts {
                // Ensure that retrievedProducts is an empty set for an invalid identifier
                XCTAssertTrue(retrievedProducts.isEmpty, "retrievedProducts should be an empty set for an invalid identifier")
            } else {
                // If retrievedProducts is nil, it means no products were retrieved
                XCTAssertNil(product.retrievedProducts)
            }
            // Check if the invalid product identifier is reported as invalid
            XCTAssertEqual(product.invalidProductIDs, [invalidProductIdentifier])
            // Ensure that there is no error reported
            XCTAssertNil(product.error)
            // Fulfill the expectation to signal the completion of the test
            expectation.fulfill()
        }
        // Start the product request
        productReq.start()
        // Wait for the expectation to be fulfilled (or timeout after 5 seconds)
        wait(for: [expectation], timeout: 5.0)
    }

    func testCancelProductFetch() {
        let expectation = XCTestExpectation(description: "Product Fetch canceled")
        // Define the product identifier for testing
        let productIds: Set<String> = ["com.bjitgroup.easypurchase.consumable.tencoin"]
        // Trigger the fetchProductsInfo method with the product identifier
        let productReq = productInfoController.fetchProductsInfo(productIds) { _ in
            // This completion handler should not be called after canceling,
            // so we fail the test if it's invoked
            XCTFail("Completion handler should not be called after canceling")
        }
        // Cancel the product request
        productReq.cancel()
        // Create a delay to allow time for the cancellation to take effect
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // Fulfill the expectation to signal the completion of the test
            expectation.fulfill()
        }
        // Wait for the expectation to be fulfilled (or timeout after 2 seconds)
        wait(for: [expectation], timeout: 2.0)
    }

    func testFetchProductWithError() {
        let expectation = XCTestExpectation(description: "Product fetch completed with error")
        // Define an invalid product identifier for testing
        let invalidProductIdentifier = "invalid.product.identifier"
        // Create a set containing the invalid product identifier
        let productIds: Set<String> = [invalidProductIdentifier]
        // Create a mock product request for testing with a custom completion handler
        let mockProductRequest = MockInAppProductRequest(productIds: productIds) { product in
            // Verify that an error is reported
            XCTAssertNotNil(product.error)
            // Check if the error's localized description matches the expected value
            XCTAssertEqual(product.error?.localizedDescription, "An error occurred")
            // Ensure that no products were retrieved in this case
            XCTAssertNil(product.retrievedProducts)
            // Check if the invalid product identifier is reported as invalid
            XCTAssertEqual(product.invalidProductIDs, [invalidProductIdentifier])
            // Fulfill the expectation to signal the completion of the test
            expectation.fulfill()
        }
        // Set a mock error for the product request
        mockProductRequest.mockError = NSError(domain: "TestDomain", code: 123, userInfo: [NSLocalizedDescriptionKey: "An error occurred"])
        // Set mock invalid product identifiers for the product request
        mockProductRequest.mockInvalidProductIDs = Set([invalidProductIdentifier])
        // Start the mock product request
        mockProductRequest.start()
        // Wait for the expectation to be fulfilled (or timeout after 5 seconds)
        wait(for: [expectation], timeout: 5.0)
    }

    func testTryToFetchMultipleProducts() {
        let expectation = XCTestExpectation(description: "Multiple product fetch completed")
        // Define a set of product identifiers to fetch
        let productIds: Set<String> = [
            "com.bjitgroup.easypurchase.consumable.tencoin",
            "com.bjitgroup.easypurchase.consumable.twentycoin",
            "com.bjitgroup.easypurchase.consumable.thirtycoin"
        ]
        // Perform the multiple product fetch using the productInfoController
        let multiProductReq = productInfoController.fetchProductsInfo(productIds) { product in
            // Verify that retrieved products are not nil
            XCTAssertNil(product.retrievedProducts)
            // Ensure that the number of retrieved products is not equal to the expected count
            XCTAssertEqual(product.retrievedProducts?.count, productIds.count)
            // Verify that there are invalid product identifiers reported
            XCTAssertNotEqual(product.invalidProductIDs, [])
            // Ensure that no error occurred during the fetch
            XCTAssertNil(product.error)
            // Fulfill the expectation to signal the completion of the test
            expectation.fulfill()
        }
        // Start the multiple product fetch request
        multiProductReq.start()
        // Wait for the expectation to be fulfilled (or timeout after 5 seconds)
        wait(for: [expectation], timeout: 5.0)
    }
    // Test the request(_:didFailWithError:) method
    func testRequestDidFailWithError() {
        // Given
        let mockError = NSError(domain: "com.example", code: 1001, userInfo: nil)

        // When
        fetchProduct.request(SKRequest(), didFailWithError: mockError)

        // Then
        XCTAssertTrue(fetchProduct.isCompleted)
        XCTAssertEqual(fetchProduct.cachedProducts?.error as NSError?, mockError)

        // Verify that the completion handler is called with the correct products.
        XCTAssertNotNil(fetchProduct.productCompletionHandler)
        fetchProduct.productCompletionHandler?(fetchProduct.cachedProducts!) // Simulate calling the completion handler
        // Check that retrievedProducts & invalidProductIDs arrays are nil
        XCTAssertNil(fetchProduct.cachedProducts?.retrievedProducts)
        XCTAssertNil(fetchProduct.cachedProducts?.invalidProductIDs)
    }
}
