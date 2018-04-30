//
//  BlockchainUser.swift
//  secretmap
//
//  Created by Joe Anthony Peter Amanse on 2/8/18.
//  Copyright © 2018 Anton McConville. All rights reserved.
//

import UIKit

class BlockchainUser: NSObject, NSCoding {

    // Properties
    var userId: String
    
    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let ArchiveURL = DocumentsDirectory.appendingPathComponent("user")
    
    struct PropertyKey {
        static let userId = "userId"
    }
    
    // Initializer
    init?(userId: String) {
        
        if userId.isEmpty {
            return nil
        }
        
        self.userId = userId
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(userId, forKey: PropertyKey.userId)
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        
        guard let userId = aDecoder.decodeObject(forKey: PropertyKey.userId) as? String else {
            print("Unable to decode userId.")
            return nil
        }
        
        // Must call designated initializer.
        self.init(userId: userId)
    }
}
