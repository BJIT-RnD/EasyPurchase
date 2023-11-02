//
//  PurchaseViewController.swift
//  EasyPurchaseDemo
//
//  Created by rex on 29/9/23.
//

import UIKit
import StoreKit
import EasyPurchase

class PurchaseViewController: UIViewController {
    var selectedPurchaseType: PurchaseType?
    @IBOutlet weak var purchaseTableView: UITableView!
    var productArray = [SKProduct]()
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    private func registerTableViewCell() {
        purchaseTableView.register(UINib(nibName: KPurchaseVCTableViewCell, bundle: nil), forCellReuseIdentifier: KPurchaseVCTableViewCell)
    }
    
    private func initialUISetup() {
        var navigationBarTitle = ""
        if let purchaseType = selectedPurchaseType {
            switch purchaseType {
            case .autoRenewable:
                navigationBarTitle = "Auto Renew Subscription"
            case .nonRenewable:
                navigationBarTitle = "Non-Renewable Subscription"
            case .consumable:
                navigationBarTitle = "Consumable"
            case .nonConsumable:
                navigationBarTitle = "Non-Consumable"
            }
        }
        self.navigationItem.title = navigationBarTitle
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        registerTableViewCell()
        initialUISetup()
        fetchProductFromAppStore()
    }
    
    private func presentAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(okAction)
        self.present(alert, animated: true, completion: nil)
    }
    
    // MARK: - EP Calls
    private func fetchProductFromAppStore() {
        activityIndicator.startAnimating()
        if let selectedPurchaseType = self.selectedPurchaseType {
            IAPManager.shared.fetchProducts(purchaseType: selectedPurchaseType) { [weak self] productList, error in
                guard let self = self else { return }

                if let error = error {
                    let errorMessage = "Failed to fetch products: \(error.localizedDescription)"
                    DispatchQueue.main.async {
                        self.presentAlert(title: "Failed!", message: errorMessage)
                        self.activityIndicator.stopAnimating()
                    }
                } else {
                    if let productList = productList, !productList.isEmpty {
                        self.productArray = productList
                        self.checkOtherSKProductAttributes(productList: self.productArray)
                        DispatchQueue.main.async {
                            self.purchaseTableView.reloadData()
                            self.activityIndicator.stopAnimating()
                        }
                    } else {
                        let errorMessage = "No products fetched or an error occurred."
                        DispatchQueue.main.async {
                            self.presentAlert(title: "Failed!", message: errorMessage)
                            self.activityIndicator.stopAnimating()
                        }
                    }
                }
            }
        } else {
            let errorMessage = "Failed to fetch product"
            self.presentAlert(title: "Failed!", message: errorMessage)
            self.activityIndicator.stopAnimating()
        }
    }
    
    private func checkOtherSKProductAttributes(productList: [SKProduct]) {
        for product in productList {
            print("localizedTitle \(product.localizedTitle)")
            print("localizedDescription \(product.localizedDescription)")
            print("priceLocale \(product.priceLocale)")
            print("isDownloadable \(product.isDownloadable)")
            
            if #available(iOS 11.2, *) {
                if let introductoryPrice = product.introductoryPrice {
                    let numberFormatter = NumberFormatter()
                    numberFormatter.numberStyle = .currency
                    numberFormatter.locale = product.priceLocale
                    let introductoryPrice = numberFormatter.string(from: introductoryPrice.price)
                    print("introductoryPrice: \(String(describing: introductoryPrice))")
                } else {
                    print("introductoryPrice: ")
                }
                
                if let subscriptionPeriod = product.subscriptionPeriod {
                    let numberOfUnits = subscriptionPeriod.numberOfUnits
                    let unit = subscriptionPeriod.unit
                    print("subscriptionPeriod: \(numberOfUnits) \(unit.rawValue)")
                } else {
                    print("subscriptionPeriod:")
                }
            }
            if #available(iOS 12.2, *) {
                print("discounts \(product.discounts)")
            }
            if #available(iOS 14.0, *) {
                print("isFamilyShareable \(product.isFamilyShareable)")
            }
            print("------------------------------")
        }
    }
    
    func handleProductPurchase(product: SKProduct) {
        IAPManager.shared.purchaseProducts(purchaseType: selectedPurchaseType!, product: product) { [weak self] purchaseResult in
            guard let self = self else { return }
            
            var alertTitle: String = ""
            var alertMessage: String = ""
            
            switch purchaseResult {
            case .success(let purchase):
                print("product title: \(purchase.product.localizedTitle)")
                DispatchQueue.main.async {
                    self.activityIndicator.stopAnimating()
                    self.navToMainViewController()
                }
                
            case .failure(let error):
                if error.code == .paymentCancelled {
                    alertTitle = "Oops!"
                    alertMessage = "Your purchase process is cancelled!"
                } else {
                    alertTitle = "Failed!"
                    alertMessage = error.localizedDescription
                }
                DispatchQueue.main.async {
                    self.activityIndicator.stopAnimating()
                    self.presentAlert(title: alertTitle, message: alertMessage)
                }
            }
        }
    }
    
    @objc func restorePurchaseButtonAction() {
        self.activityIndicator.startAnimating()
        IAPManager.shared.restoreProducts { [weak self] restoreResults in
            guard let self = self else { return }
            
            var alertTitle: String = ""
            var alertMessage: String = ""
            
            for restoreResult in restoreResults {
                if restoreResult.restoredProductsFailure.count > 0 {
                    for (error, message) in restoreResult.restoredProductsFailure {
                        print("Failed to restore purchase with error: \(error.localizedDescription), message: \(message ?? "N/A")")
                        alertTitle = "Failed!"
                        alertMessage = error.localizedDescription
                        break
                    }
                    DispatchQueue.main.async {
                        self.presentAlert(title: alertTitle, message: alertMessage)
                        self.activityIndicator.stopAnimating()
                    }
                } else {
                    if restoreResult.restoredProductsSuccess.count > 0 {
                        for purchase in restoreResult.restoredProductsSuccess {
                            print("Restored purchase:", purchase)
                        }
                        DispatchQueue.main.async {
                            self.navToMainViewController()
                        }
                    } else {
                        alertTitle = "Not Found!"
                        alertMessage = "Nothing to restore!"
                        DispatchQueue.main.async {
                            self.presentAlert(title: alertTitle, message: alertMessage)
                        }
                    }
                    DispatchQueue.main.async {
                        self.activityIndicator.stopAnimating()
                    }
                }
            }
        }
    }
    
    func navToMainViewController() {
        if selectedPurchaseType == .autoRenewable || selectedPurchaseType == .nonRenewable {
            let mainViewController = UIStoryboard(name: "Main", bundle: .main).instantiateViewController(withIdentifier: "MainViewController") as! MainViewController
            self.navigationController?.pushViewController(mainViewController, animated: true)
        } else {
            //Handle UI for Non-Consumable here
        }
    }
}

extension PurchaseViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return productArray.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return KHomeTableViewCellHeight
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: KPurchaseVCTableViewCell) as! PurchaseVCTableViewCell
        cell.selectionStyle = .none
        cell.configureCell(product: productArray[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.activityIndicator.startAnimating()
        handleProductPurchase(product: productArray[indexPath.row])
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if section == 0 {
            if productArray.count > 0 {
                if selectedPurchaseType == .consumable {
                    return nil
                } else {
                    let footerView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: 100))
                    
                    let button = UIButton(type: .system)
                    button.setTitle("Restore in-app purchase", for: .normal)
                    if let customColor = UIColor(named: "DefaultTextColour") {
                        button.setTitleColor(customColor, for: .normal)
                    }
                    button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 17)
                    button.addTarget(self, action: #selector(restorePurchaseButtonAction), for: .touchUpInside)
                    button.frame = CGRect(x: 20, y: 30, width: tableView.frame.size.width - 32, height: 44)
                    footerView.addSubview(button)
                    return footerView
                }
            }
        }
        return nil
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if section == 0 {
            if productArray.count > 0 {
                if selectedPurchaseType == .consumable || selectedPurchaseType == .nonRenewable {
                    return 0
                } else {
                    return 100
                }
            }
        }
        return 0
    }
}
