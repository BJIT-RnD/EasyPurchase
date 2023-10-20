//
//  PurchaseVCTableViewCell.swift
//  EasyPurchaseDemo
//
//  Created by rex on 29/9/23.
//

import UIKit
import StoreKit

class PurchaseVCTableViewCell: UITableViewCell {
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subTitleLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.containerView.addShadow()
    }

    func configureCell(product: SKProduct) {
        let priceFormatter = NumberFormatter()
        priceFormatter.numberStyle = .currency
        priceFormatter.locale = product.priceLocale
        if let formattedPrice = priceFormatter.string(from: product.price) {
            self.titleLabel.text = product.localizedTitle
            self.subTitleLabel.text = formattedPrice
        }
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}
