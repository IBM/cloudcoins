//
//  SelectedEvent.swift
//  kubecoin
//
//  Created by Joe Anthony Peter Amanse on 9/3/18.
//  Copyright © 2018 Anton McConville. All rights reserved.
//

import Foundation
import CoreData

class EventCoreData {
    
    var context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    func getPerson(event: String) -> Person? {
        var people: [Person]
        
        do {
            people = try context.fetch(Person.fetchRequest())
            if people.count > 0 {
                for person in people {
                    if person.event == event {
                        return person
                    }
                }
            }
        } catch {
            print("Error getting person from core data")
            return nil
        }
        
        return nil
    }
    
    func savePerson(userId: String, participantname: String, avatar: String, event: String) {
        let person = Person(context: self.context)
        
        person.startdate = Date()
        person.blockchain = userId
        person.avatar = avatar
        person.participantname = participantname
        person.event = event
        
        do {
            try self.context.save()
        } catch {
            print("error saving person to core data")
        }
    }
}
