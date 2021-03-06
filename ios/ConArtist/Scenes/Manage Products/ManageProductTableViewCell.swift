//
//  ManageProductTableViewCell.swift
//  ConArtist
//
//  Created by Cameron Eldridge on 2018-10-30.
//  Copyright © 2018 Cameron Eldridge. All rights reserved.
//

import UIKit

class ManageProductTableViewCell: ConArtistTableViewCell {
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var quantityLabel: UILabel!
}

extension ManageProductTableViewCell {
    static let ID = "ManageProductCell"

    func setup(with product: Product) {
        nameLabel.text = product.name
        quantityLabel.text = "\(product.quantity)"
        quantityLabel.isHidden = product.discontinued
        DispatchQueue.main.async {
            self.nameLabel.textColor = product.discontinued ? .textPlaceholder : .text
        }
    }
}
