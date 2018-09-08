//
//  EventClient.swift
//  kubecoin
//
//  Created by Joe Anthony Peter Amanse on 9/3/18.
//  Copyright © 2018 Anton McConville. All rights reserved.
//

import Foundation

class EventClient {
    func getEvents(_ onCompletion: @escaping ([EventModel]?) -> Void) {
        guard let url = URL(string: BlockchainGlobals.EVENT_URL) else { onCompletion(nil); return }
        let request = NSMutableURLRequest(url: url)
        let session = URLSession.shared
        
        let getEvents = session.dataTask(with: request as URLRequest) { (data, response, error) in
            if let data = data {
                do {
                    let events = try JSONDecoder().decode([EventModel].self, from: data)
                    onCompletion(events)
                }  catch let error as NSError {
                    print(error.localizedDescription)
                    onCompletion(nil)
                }
            } else if let error = error {
                print(error.localizedDescription)
                onCompletion(nil)
            }
            
        }
        getEvents.resume()
    }
}
