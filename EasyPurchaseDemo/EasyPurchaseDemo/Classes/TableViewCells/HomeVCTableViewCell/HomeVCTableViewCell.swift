//
//  HomeVCTableViewCell.swift
//  EasyPurchaseDemo
//
//  Created by rex on 29/9/23.
//

import UIKit

class HomeVCTableViewCell: UITableViewCell {
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.containerView.addShadow()
    }

    func configureCell(title : String) {
        self.titleLabel.text = title
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}
