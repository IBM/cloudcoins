//
//  SelectedEventCoreData.swift
//  kubecoin
//
//  Created by Joe Anthony Peter Amanse on 9/3/18.
//  Copyright © 2018 Anton McConville. All rights reserved.
//

import Foundation
import CoreData

class SelectedEventCoreData {
    
    var context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    func selectedEvent() -> SelectedEvent? {
        var events: [SelectedEvent]
        
        do {
            events = try context.fetch(SelectedEvent.fetchRequest())
            if events.count > 0 {
                return events[0]
            }
        } catch {
            print("Error getting selected event")
            return nil
        }
        return nil
    }
    
    func chooseEvent(event: String) {
        var events: [SelectedEvent]
        
        do {
            events = try context.fetch(SelectedEvent.fetchRequest())
            if events.count > 0 {
                events[0].event = event
            } else {
                let selectedEvent = SelectedEvent(context: context)
                selectedEvent.event = event
            }
            try context.save()
        } catch {
            print("Error getting selected event")
        }
    }
}
