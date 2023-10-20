//
//  UIView+Extension.swift
//  EasyPurchaseDemo
//
//  Created by rex on 29/9/23.
//

import UIKit

extension UIView {
    func addShadow() {
        self.layer.shadowColor = UIColor.gray.cgColor
        self.layer.cornerRadius = 10
        self.layer.shadowOffset = CGSize(width: 1, height: 1)
        self.layer.shadowOpacity = 0.5
    }
}
