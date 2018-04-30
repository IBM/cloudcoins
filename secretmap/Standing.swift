//
//  Standing.swift
//  fitcoin
//
//  Created by Anton McConville on 2018-04-22.
//  Copyright © 2018 Anton McConville. All rights reserved.
//

import Foundation
//
//  Meal.swift
//  FoodTracker
//
//  Created by Jane Appleseed on 11/10/16.
//  Copyright © 2016 Apple Inc. All rights reserved.
//

import UIKit

class Standing {
    
    //MARK: Properties
    
    var name: String
    var photo: UIImage?
    var steps: Int
    var km: Int
    var position: Int
    
    //MARK: Initialization
    
    init?(name: String, photo: UIImage?, steps: Int, km: Int, position: Int) {
        
        // The name must not be empty
        guard !name.isEmpty else {
            return nil
        }
        
        // Initialize stored properties.
        self.name = name
        self.photo = photo
        self.steps = steps
        self.km = km
        self.position = position
    }
}
