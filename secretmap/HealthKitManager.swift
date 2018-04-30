//
//  HealthKitManager.swift
//  secretmap
//
//  Created by Anton McConville on 2018-01-22.
//  Copyright © 2018 Anton McConville. All rights reserved.
//

import Foundation
import UIKit
import HealthKit

class HealthKitManager{
    
    let healthStore = HKHealthStore()
    
    func authorizeHealthKit() -> Bool{
     
        var isEnabled = true
        
        if HKHealthStore.isHealthDataAvailable(){
            
            let stepCount = NSSet(object:HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount))
            
            let dataTypesToWrite = NSSet(object: stepCount)
            
            let datatypesToRead = NSSet(object: stepCount)
            
            healthStore.requestAuthorization(toShare:nil, read: stepCount as! Set<HKObjectType>) {
                (success, error) -> Void in
                isEnabled = success
            }
        }
        else
        {
            isEnabled = false
        }
        
        return isEnabled
    }
    
    func getHealthStore() -> HKHealthStore{
        return healthStore
    }
}
