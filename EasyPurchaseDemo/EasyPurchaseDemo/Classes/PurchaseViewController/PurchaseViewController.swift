//
//  PurchaseViewController.swift
//  EasyPurchaseDemo
//
//  Created by rex on 29/9/23.
//

import UIKit
import StoreKit

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
    
    private func setTableViewIntheMiddle() {
        let viewHeight = view.frame.size.height/1.5
        let numberOfRowsInSection = CGFloat(purchaseTableView.numberOfRows(inSection: 0))
        let headerHeight = (viewHeight - (KHomeTableViewCellHeight * numberOfRowsInSection)) / 2.0
        purchaseTableView.contentInset = UIEdgeInsets(top: headerHeight, left: 0, bottom: -headerHeight, right: 0)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        registerTableViewCell()
        initialUISetup()
        setTableViewIntheMiddle()
        fetchProductFromAppStore()
    }
    
    private func fetchProductFromAppStore() {
        activityIndicator.startAnimating()
        if let selectedPurchaseType = self.selectedPurchaseType {
            IAPManager.shared.getProducts(purchaseType: selectedPurchaseType) { [weak self] productList, error in
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
                        //self.checkOtherSKProductAttributes(productList: self.productArray)
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
    
    private func presentAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(okAction)
        self.present(alert, animated: true, completion: nil)
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
    
    @objc func restorePurchaseButtonAction() {
        self.activityIndicator.startAnimating()
        IAPManager.shared.restorePurchases { restoredPurchases, restoreErrors in
            if !restoredPurchases.isEmpty {
                for purchase in restoredPurchases {
                    print("Successfully restored: \(purchase.productId)")
                }
                DispatchQueue.main.async {
                    self.activityIndicator.stopAnimating()
                }
            }

            if !restoreErrors.isEmpty {
                for error in restoreErrors {
                    print("Restore failed with error: \(error.localizedDescription)")
                }
                DispatchQueue.main.async {
                    self.activityIndicator.stopAnimating()
                }
            }
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
        IAPManager.shared.purchaseProduct(purchaseType: selectedPurchaseType!, product: productArray[indexPath.row]) { [weak self] purchaseResult in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.activityIndicator.stopAnimating()
            }
            
            var alertTitle: String = ""
            var alertMessage: String = ""
            
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
            
            DispatchQueue.main.async {
                self.presentAlert(title: alertTitle, message: alertMessage)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if section == 0 {
            if productArray.count > 0 {
                if selectedPurchaseType == .consumable {
                    return nil
                } else {
                    let footerView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: 100))
                    let restoreButton = UIButton(type: .system)
                    restoreButton.setTitle("Restore in-app purchase", for: .normal)
                    if let customColor = UIColor(named: "DefaultTextColour") {
                        restoreButton.setTitleColor(customColor, for: .normal)
                    }
                    restoreButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 17)
                    let buttonWidth: CGFloat = tableView.frame.size.width - 40
                    let buttonHeight: CGFloat = 44
                    let xPosition = (footerView.frame.size.width - buttonWidth) / 2
                    let yPosition = (footerView.frame.size.height - buttonHeight) / 2
                    
                    restoreButton.frame = CGRect(x: xPosition, y: yPosition, width: buttonWidth, height: buttonHeight)
                    restoreButton.addTarget(self, action: #selector(restorePurchaseButtonAction), for: .touchUpInside)
                    footerView.addSubview(restoreButton)
                    
                    return footerView
                }
            }
        }
        return nil
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if section == 0 {
            if productArray.count > 0 {
                if selectedPurchaseType == .consumable {
                    return 0
                } else {
                    return 100
                }
            }
        }
        return 0
    }
}
