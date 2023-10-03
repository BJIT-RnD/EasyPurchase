//
//  FetchProductTests.swift
//  
//
//  Created by BJIT on 29/9/23.
//
import XCTest
import StoreKit
@testable import EasyPurchase

// ProductInfoControllerTestsDemo is a test case class designed to test the functionality
// of the ProductInfoController class. It contains a test case that verifies the behavior of
// fetching a product with a valid identifier.
class FetchProductTests: XCTestCase {
    var productInfoController: ProductInfoController!

    override func setUp() {
        super.setUp()
        // Create an instance of the ProductInfoController
        productInfoController = ProductInfoController()
    }

    override func tearDown() {
        // Clean up resources if needed
        productInfoController = nil
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
}
