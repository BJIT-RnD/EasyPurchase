//
//  HomeViewController.swift
//  EasyPurchaseDemo
//
//  Created by rex on 29/9/23.
//

import UIKit
import EasyPurchase

class HomeViewController: UIViewController {
    @IBOutlet weak var homeTableView: UITableView!
    var selectedPurchaseType: PurchaseType?
    let data = ["Auto Renewable Subscription",
                "Non-Renewable Subscription",
                "Consumable",
                "Non-Consumable"]
    
    private func registerTableViewCell() {
        homeTableView.register(UINib(nibName: KHomeTableViewCell, bundle: nil), forCellReuseIdentifier: KHomeTableViewCell)
    }
    
    private func setTableViewIntheMiddle() {
        let viewHeight = view.frame.size.height - UIApplication.shared.statusBarFrame.size.height
        let numberOfRowsInSection = CGFloat(homeTableView.numberOfRows(inSection: 0))
        let headerHeight = (viewHeight - (KHomeTableViewCellHeight * numberOfRowsInSection)) / 2.0
        homeTableView.contentInset = UIEdgeInsets(top: headerHeight, left: 0, bottom: -headerHeight, right: 0)
    }
    
    //Life Cycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        registerTableViewCell()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        setTableViewIntheMiddle()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
}

extension HomeViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return KHomeTableViewCellHeight
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: KHomeTableViewCell) as! HomeVCTableViewCell
        cell.selectionStyle = .none
        cell.configureCell(title: data[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.row {
        case 0:
            selectedPurchaseType = .autoRenewable
        case 1:
            selectedPurchaseType = .nonRenewable
        case 2:
            selectedPurchaseType = .consumable
        case 3:
            selectedPurchaseType = .nonConsumable
        default:
            selectedPurchaseType = nil
        }
        
        let purchaseViewController = UIStoryboard(name: "Main", bundle: .main).instantiateViewController(withIdentifier: "PurchaseViewController") as! PurchaseViewController
        purchaseViewController.selectedPurchaseType = selectedPurchaseType
        self.navigationController?.pushViewController(purchaseViewController, animated: true)
    }
}
