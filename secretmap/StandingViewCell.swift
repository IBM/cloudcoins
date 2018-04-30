//
//  StandingViewCell.swift
//  fitcoin
//
//  Created by Anton McConville on 2018-04-22.
//  Copyright © 2018 Anton McConville. All rights reserved.
//

import Foundation

import UIKit

class StandingViewCell: UITableViewCell {
    
    //MARK: Properties
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var stepsLabel: UILabel!
    @IBOutlet weak var kmLabel:UILabel!
    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var positionLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
}
