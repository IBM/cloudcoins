//
//  EventModel.swift
//  kubecoin
//
//  Created by Joe Anthony Peter Amanse on 9/3/18.
//  Copyright © 2018 Anton McConville. All rights reserved.
//

import Foundation

struct EventModel: Codable {
    let eventId: String?
    let name: String?
    let description: String?
    let eventStatus: String?
    let approvalStatus: String?
    let owner: String?
    let link: String?
}
