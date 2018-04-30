//
//  Globals.swift
//  secretmap
//
//  Created by Joe Anthony Peter Amanse on 2/28/18.
//  Copyright © 2018 Anton McConville. All rights reserved.
//

import Foundation
import UIKit

struct BlockchainGlobals {
    static var URL:String = "https://anthony-blockchain.us-south.containers.mybluemix.net/"
}

struct GetStateFinalResult: Codable {
    let contractIds: [String]?
    let fitcoinsBalance: Int
    let id: String
    let memberType: String
    let stepsUsedForConversion: Int
    let totalSteps: Int
}

struct NumberOfUsers: Codable {
    let count: Int?
}

struct ResultOfMakePurchase: Codable {
    let message: String
    let result: TransactionResult?
    let error: String?
}

struct TransactionResult: Codable {
    let txId: String
    let results: ResultOfTransactionResult
}

struct ResultOfTransactionResult: Codable {
    let status: Int
    let message: String
    let payload: String
}

struct Product: Codable {
    let sellerid: String
    let productid: String
    let name: String
    let count: Int
    let price: Int
}

struct ResultOfBlockchain: Codable {
    let message: String
    let result: String?
    let error: String?
}

struct Contract: Codable {
    let id: String
    let sellerId: String
    let userId: String
    let productId: String
    let productName: String
    let quantity: Int
    let cost: Int
    let state: String
}

struct BackendResult: Codable {
    let status: String
    let result: String?
}

struct ResultOfEnroll: Codable {
    let message: String
    let result: EnrollFinalResult?
    let error: String?
}

struct EnrollFinalResult: Codable {
    let user: String
    let txId: String
}

struct Beacon: Codable {
    let beaconId: String
    let key: String
    let value: String
    let zone: Int
    let beaconid: String
    let color: String
    let x: Int
    let y: Int
    let width: Int
    let height: Int
}

struct Booth: Codable {
    let boothId: String
    let unit: String
    let description: String
    let measurementUnit: String
    let shape: Shape
    let contact: String
}

struct Shape: Codable {
    let type: String
    let x: Int
    let y: Int
    let width: Int
    let height: Int
}

struct Event: Codable {
    let eventId: String
    let eventName: String
    let location: String
    let x: Int
    let y: Int
    let startDate: String
    let endDate: String
    let beacons: [Beacon]
    let map: [Booth]
}
