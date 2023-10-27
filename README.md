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
## App startup

### Complete Transactions
> 
To ensure that your app consistently receives all payment queue notifications, it's essential to add your app's observer at launch. This way, your app will persistently listen for these notifications every time it is launched. EasyPurchase simplifies this process by invoking the `completeTransaction()` function when your app starts.

```swift
// This method is called when the app finishes launching.
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        EasyPurchase.completeTransactions { purchases in
            for purchase in purchases {
                switch purchase.transaction.transactionState {
                case .purchased, .restored:
                    if purchase.needsFinishTransaction {
                        EasyPurchase.finishTransaction(purchase.transaction)
                    }
                case .failed, .purchasing, .deferred:
                    break
                @unknown default:
                    break
                }
            }
        }
        return true
    }
```

If there are any pending transactions during this initialization, the `completeTransactions()` function will report them through a completion block. This enables your app to update its state and user interface accordingly.

It's important to emphasize that you should call `completeTransactions()` just **once** in your code, specifically within the application`(:didFinishLaunchingWithOptions:)` method.

## Purchases

### Fetch Products

```swift
var productRequest: InAppProductRequest?

let products = "productIdentifier"
productRequest = EasyPurchase.fetchProducts(Set(products!)) { productInfo in
    if productInfo.error != nil {
        completion(nil, productInfo.error)
    } else {
        if let retrievedProducts = productInfo.retrievedProducts {
            completion(Array(retrievedProducts), nil)
        } else {
            // invalidProductIDs
        }
    }
}
productRequest?.start()
```
### Purchase Product
```swift
EasyPurchase.purchaseProduct(.nonConsumable, product: productArray[indexPath.row], quantity: 1) { [weak self] purchaseResult in
    guard let self = self else { return }

    switch purchaseResult {
    case .success(let purchase):
        alertTitle = "Successful!"
        alertMessage = "Successfully purchased: \(purchase.product.localizedTitle)"

    case .failure(let error):
        if error.code == .paymentCancelled {
            alertTitle = "Oops!"
            alertMessage = "Your purchase process is cancelled!"
        } else {
            alertTitle = "Failed!"
            alertMessage = error.localizedDescription
        }
    }
}
```
### Restore Purchases

This part explains how to recover past transactions using the `restorePurchases()` method. When this method is executed successfully, it provides you with all non-consumable purchases and all auto-renewable subscription purchases, regardless of whether they have expired or not.

```swift
EasyPurchase.restorePurchases(atomically: true) { results in
    print(results, "results")
    for purchase in results.restoredProductsSuccess {
        print("purchase", purchase)
    }
}
```
## Demo Implementation
>
The project incorporates [iOS demo](https://github.com/BJIT-RnD/EasyPurchase/tree/main/EasyPurchaseDemo/EasyPurchaseDemo) applications that serve as examples of how to utilize EasyPurchase. It's crucial to understand that the in-app purchases pre-registered in these demo apps are intended solely for demonstration and instructional purposes. It's worth noting that their functionality may not be reliable since iTunes Connect has the potential to invalidate them.

## N.B.

EasyPurchase does not retain in-app purchase data on a local level. The responsibility for managing and storing this data falls upon the clients or developers who use EasyPurchase. They have the flexibility to choose their preferred storage solution, which could include options such as NSUserDefaults, CoreData, or the Keychain. In other words, EasyPurchase doesn't handle the local storage of in-app purchase information; that task is left to the discretion of the clients, allowing them to select the most suitable method for their specific needs.
