# EasyPurchase
A description of this package. Version v1.0.0

**EasyPurchase** is a simple and ready-to-use framework designed for handling In-App Purchases on iOS devices, which is developed using Apple's Storekit framework.

## Features
- **iOS 11+ Ready**: Offers support for in-app purchases initiated from the App Store (compatible with iOS 11 onwards).
- **User-Friendly API**: Enjoy an easily comprehensible block-based API.
- **Product Validation Support**: Easy to validate your products that you have set in your app store connect.
- **Purchase Support**: Handle both consumable and non-consumable in-app purchases.
- **Subscription Support**: Manage free, auto-renewable, and non-renewing subscriptions.

## Requirements

All the features should be available if you are maintaining or developing app with lowest iOS version set as 11.0. So, only requirements for iOS devices:

- **iOS:** 11.0
# Installation

You have multiple options for installing EasyPurchase in your project, with the preferred and recommended approaches being Swift Package Manager, CocoaPods, and Carthage integrations.

Regardless of the method you choose, make sure to import the project wherever you intend to use it:

```swift
import EasyPurchase
```


## Swift Package Manager

The Swift Package Manager (SPM) is a tool for automating the distribution of Swift code and is seamlessly integrated into Xcode and the Swift compiler. It is the recommended installation method for EasyPurchase. With SPM, updates to EasyPurchase are immediately available to your projects. SPM is also directly integrated with Xcode.

If you are using Xcode 11 or later, follow these steps to add EasyPurchase as a dependency:

1. Click on **File**.
2. Select **Swift Packages**.
3. Choose **Add Package Dependency...**.
4. Specify the git URL for EasyPurchase:- 

```swift 
https://github.com/BJIT-RnD/EasyPurchase.git
```

## CocoaPods

EasyPurchase can be installed as a CocoaPod and builds as a Swift framework. 

To install, include this in your Podfile.
```swift
use_frameworks!

pod 'EasyPurchase'
```
