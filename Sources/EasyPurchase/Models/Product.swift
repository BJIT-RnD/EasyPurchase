//
//  File.swift
//  
//
//  Created by BJIT on 19/9/23.
//
import Foundation
import StoreKit

// A struct to represent the result of a product retrieval operation.
public struct InAppProduct {
    // A set of retrieved products (SKProduct) if the operation was successful,
    // otherwise, it will be nil.
    public let retrievedProducts: Set<SKProduct>?

    // A set of invalid product IDs, which couldn't be retrieved, if any.
    // If the operation was successful for all products, this will be nil.
    public let invalidProductIDs: Set<String>?

    // An error object that holds any errors encountered during the retrieval
    // operation. If the operation was successful, this will be nil.
    public let error: Error?
}

// A struct to represent the result of a product retrieval operation.
public struct RefreshReceiptStatus {
    public let status: Result
}

public enum Result {
    case success
    case failed
}

