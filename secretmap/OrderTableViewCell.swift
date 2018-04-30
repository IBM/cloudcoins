//
//  OrderTableViewCell.swift
//  secretmap
//
//  Created by Joe Anthony Peter Amanse on 2/27/18.
//  Copyright © 2018 Anton McConville. All rights reserved.
//

import UIKit

class OrderTableViewCell: UITableViewCell {

    @IBOutlet weak var contractId: UILabel!
    @IBOutlet weak var quickDetails: UILabel!
    @IBOutlet weak var state: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
