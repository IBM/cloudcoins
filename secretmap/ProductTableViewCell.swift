//
//  ProductTableViewCell.swift
//  secretmap
//
//  Created by Joe Anthony Peter Amanse on 2/22/18.
//  Copyright © 2018 Anton McConville. All rights reserved.
//

import UIKit

class ProductTableViewCell: UITableViewCell {
    @IBOutlet weak var myView: UIView!
    @IBOutlet weak var myCellLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var quantityLeftLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
