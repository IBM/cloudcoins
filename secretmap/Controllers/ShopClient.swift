//
//  ShopClient.swift
//  kubecoin
//
//  Created by Joe Anthony Peter Amanse on 9/6/18.
//  Copyright © 2018 Anton McConville. All rights reserved.
//

import Foundation

class ShopClient {
    
    var userId: String
    var event: String
    
    init(userId: String, event: String) {
        self.userId = userId
        self.event = event
    }
    
    // get products from blockchain
    func getProducts(failedAttempts: Int? = 0, _ onCompletion: @escaping ([Product]?) -> Void) {
        guard let url = URL(string: BlockchainGlobals.URL + "api/execute") else { return }
        let parameters: [String:Any]
        let request = NSMutableURLRequest(url: url)
        let session = URLSession.shared
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        //{"userId":"766f2d71-a286-441b-afdd-11824c2ee226","fcn":"getProductsForSale","args":[]}
        let args: [String] = []
        parameters = ["type":"query", "queue":"user_queue-" + self.event,"params":["userId":self.userId, "fcn":"getProductsForSale","args":args]]
        request.httpBody = try! JSONSerialization.data(withJSONObject: parameters, options: [])
        
        let showProducts = session.dataTask(with: request as URLRequest) { (data, response, error) in
            
            if let data = data {
                do {
                    // Convert the data to JSON
                    let jsonSerialized = try JSONSerialization.jsonObject(with: data, options: []) as? [String : Any]
                    
                    if let json = jsonSerialized, let status = json["status"], let resultId = json["resultId"] {
                        NSLog(status as! String)
                        NSLog(resultId as! String) // Use this one to get blockchain payload - should contain userId
                        
                        self.getProductsResult(resultId: resultId as! String, attemptNumber: 0, failedAttempts:  failedAttempts, onCompletion)
                    }
                }  catch let error as NSError {
                    print(error.localizedDescription)
                    onCompletion(nil)
                }
            } else if let error = error {
                print(error.localizedDescription)
                onCompletion(nil)
            }
        }
        showProducts.resume()

    }
    
    // get contracts of user
    func getContracts(failedAttempts: Int? = 0, _ onCompletion: @escaping ([Contract]?) -> Void) {
        guard let url = URL(string: BlockchainGlobals.URL + "api/execute") else { return }
        let parameters: [String:Any]
        let request = NSMutableURLRequest(url: url)
        
        let session = URLSession.shared
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let args: [String] = [self.userId]
        parameters = ["type":"query", "queue":"user_queue-" + self.event, "params":["userId": self.userId,"fcn": "getAllUserContracts", "args":args]]
        request.httpBody = try! JSONSerialization.data(withJSONObject: parameters, options: [])
        
        let getContracts = session.dataTask(with: request as URLRequest) { (data, response, error) in
            
            if let data = data {
                do {
                    // Convert the data to JSON
                    let jsonSerialized = try JSONSerialization.jsonObject(with: data, options: []) as? [String : Any]
                    
                    if let json = jsonSerialized, let status = json["status"], let resultId = json["resultId"] {
                        NSLog(status as! String)
                        NSLog(resultId as! String) // Use this one to get blockchain payload
                        
                        // Start checking if our queued request is finished.
                        self.getContractsResult(resultId: resultId as! String, attemptNumber: 0, failedAttempts: failedAttempts, onCompletion)
                    }
                }  catch let error as NSError {
                    print(error.localizedDescription)
                    onCompletion(nil)
                }
            } else if let error = error {
                print(error.localizedDescription)
                onCompletion(nil)
            }
        }
        getContracts.resume()
    }
    
    // purchase an item
    func purchaseItem(sellerId: String, productId: String, quantity: String, _ onCompletion: @escaping (Contract?) -> Void) {
        guard let url = URL(string: BlockchainGlobals.URL + "api/execute") else { return }
        let parameters: [String:Any]
        let request = NSMutableURLRequest(url: url)
        
        let session = URLSession.shared
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        //{"userId":"USER_ID_HERE","fcn":"makePurchase","args":["USER_ID_HERE","SELER_ID_HERE","PRODUCT_ID_HERE","QUANTITY"]}
        let randomNumber = Int(arc4random_uniform(1000000))
        let args: [String] = [self.userId,sellerId,productId,quantity,String(format: "c%06d", randomNumber)]
        parameters = ["type":"invoke", "queue":"user_queue-" + self.event,"params":["userId":self.userId, "fcn":"makePurchase","args":args]]
        request.httpBody = try! JSONSerialization.data(withJSONObject: parameters, options: [])
        
        let makePurchase = session.dataTask(with: request as URLRequest) { (data, response, error) in
            
            if let data = data {
                do {
                    // Convert the data to JSON
                    let jsonSerialized = try JSONSerialization.jsonObject(with: data, options: []) as? [String : Any]
                    
                    if let json = jsonSerialized, let status = json["status"], let resultId = json["resultId"] {
                        NSLog(status as! String)
                        NSLog(resultId as! String) // Use this one to get blockchain payload
                        
                        // Start pinging backend with resultId
                        self.purchaseItemResults(resultId: resultId as! String, attemptNumber: 0, onCompletion)
                    }
                }  catch let error as NSError {
                    print(error.localizedDescription)
                }
            } else if let error = error {
                print(error.localizedDescription)
            }
        }
        makePurchase.resume()
    }
    
    // cancel a contract
    func cancelContract(contractId: String, _ onCompletion: @escaping (Bool) -> Void) {
        guard let url = URL(string: BlockchainGlobals.URL + "api/execute") else { return }
        let parameters: [String:Any]
        let request = NSMutableURLRequest(url: url)
        
        let session = URLSession.shared
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let args: [String] = [self.userId, contractId, "declined"]
        parameters = ["type":"invoke", "queue":"user_queue-" + self.event, "params":["userId": self.userId,"fcn": "transactPurchase", "args":args]]
        request.httpBody = try! JSONSerialization.data(withJSONObject: parameters, options: [])
        
        let declineContract = session.dataTask(with: request as URLRequest) { (data, response, error) in
            
            if let data = data {
                do {
                    // Convert the data to JSON
                    let jsonSerialized = try JSONSerialization.jsonObject(with: data, options: []) as? [String : Any]
                    
                    if let json = jsonSerialized, let status = json["status"], let resultId = json["resultId"] {
                        NSLog(status as! String)
                        NSLog(resultId as! String)
                        onCompletion(true)
                    } else {
                        onCompletion(false)
                    }
                }  catch let error as NSError {
                    print(error.localizedDescription)
                    onCompletion(false)
                }
            } else if let error = error {
                print(error.localizedDescription)
                onCompletion(false)
            }
        }
        declineContract.resume()
    }
    
    func getProductsResult(resultId: String, attemptNumber: Int, failedAttempts: Int? = 0, _ onCompletion: @escaping ([Product]?) -> Void) {
        if attemptNumber < 90 {
            guard let url = URL(string: BlockchainGlobals.URL + "api/results/" + resultId) else { return }
            let session = URLSession.shared
            let resultsFromBlockchain = session.dataTask(with: url) { (data, response, error) in
                if let data = data {
                    do {
                        
                        let backendResult = try JSONDecoder().decode(BackendResult.self, from: data)
                        if backendResult.status == "done" {
                            
                            let resultOfBlockchain = try JSONDecoder().decode(ResultOfBlockchain.self, from: backendResult.result!.data(using: .utf8)!)
                            
                            if resultOfBlockchain.message == "failed" || resultOfBlockchain.error != nil {
                                if failedAttempts! < 10 {
                                    print("getting products failed, trying agian")
                                    self.getProducts(onCompletion)
                                } else {
                                    print("10 failed attempts reached -- getProductsForSale")
                                }
                            } else {
                                let productList = try JSONDecoder().decode([Product].self, from: resultOfBlockchain.result!.data(using: .utf8)!)
                                
                                onCompletion(productList)
                            }
                        }
                        else {
                            let when = DispatchTime.now() + 1
                            DispatchQueue.main.asyncAfter(deadline: when) {
                                self.getProductsResult(resultId: resultId, attemptNumber: attemptNumber + 1, onCompletion)
                            }
                        }
                    }  catch let error as NSError {
                        print(error.localizedDescription)
                        onCompletion(nil)
                    }
                } else if let error = error {
                    print(error.localizedDescription)
                    onCompletion(nil)
                }
            }
            resultsFromBlockchain.resume()
        }
        else {
            NSLog("Attempted 60 times to enroll... No results")
            onCompletion(nil)
        }
    }
    
    func getContractsResult(resultId: String, attemptNumber: Int, failedAttempts: Int? = 0, _ onCompletion: @escaping ([Contract]?) -> Void) {
        if attemptNumber < 180 {
            guard let url = URL(string: BlockchainGlobals.URL + "api/results/" + resultId) else { return }
            
            let session = URLSession.shared
            let resultsFromBlockchain = session.dataTask(with: url) { (data, response, error) in
                if let data = data {
                    do {
                        let backendResult = try JSONDecoder().decode(BackendResult.self, from: data)
                        if backendResult.status == "done" {
                            
                            let resultOfBlockchain = try JSONDecoder().decode(ResultOfBlockchain.self, from: backendResult.result!.data(using: .utf8)!)
                            
                            if resultOfBlockchain.message == "failed" || resultOfBlockchain.error != nil {
                                if failedAttempts! < 10 {
                                    print("getting user contracts failed, trying agian")
                                    self.getContracts(failedAttempts: failedAttempts! + 1, onCompletion)
                                }
                                else {
                                    print("10 failed attempts reached -- getAllUserContracts")
                                }
                            } else {
                                if resultOfBlockchain.result == "null" {
                                    onCompletion(nil)
                                }
                                else {
                                    let finalResultOfUserContracts = try JSONDecoder().decode([Contract].self, from: resultOfBlockchain.result!.data(using: .utf8)!)
                                    onCompletion(finalResultOfUserContracts)
                                }
                            }
                        }
                        else {
                            let when = DispatchTime.now() + 0.5 // 0.5 seconds from now
                            DispatchQueue.main.asyncAfter(deadline: when) {
                                self.getContractsResult(resultId: resultId, attemptNumber: attemptNumber+1, failedAttempts: failedAttempts, onCompletion)
                            }
                        }
                    }  catch let error as NSError {
                        print(error.localizedDescription)
                        onCompletion(nil)
                    }
                } else if let error = error {
                    print(error.localizedDescription)
                    onCompletion(nil)
                }
            }
            resultsFromBlockchain.resume()
        }
        else {
            NSLog("Attempted 60 times to get user state... No results")
            onCompletion(nil)
        }
    }
    
    func purchaseItemResults(resultId: String, attemptNumber: Int, _ onCompletion: @escaping (Contract?) -> Void) {
        if attemptNumber < 120 {
            guard let url = URL(string: BlockchainGlobals.URL + "api/results/" + resultId) else { return }
            
            let session = URLSession.shared
            let resultsFromBlockchain = session.dataTask(with: url) { (data, response, error) in
                if let data = data {
                    do {
                        // data is
                        // {"status":"done","result":"{\"message\":\"success\",\"result\":{\"txId\":\"14f41b12504e895923768b239bd3df5717ddb03dfce67a69cf9c599f94ca485f\",\"results\":{\"status\":200,\"message\":\"\",\"payload\":\"{\\\"id\\\":\\\"c193741\\\",\\\"sellerId\\\":\\\"06f2a544-bcdd-4b7d-8484-88f693e10aae\\\",\\\"userId\\\":\\\"e226df59-e489-46a2-aafd-7d839535b5c2\\\",\\\"productId\\\":\\\"stickers-1234\\\",\\\"productName\\\":\\\"Sticker\\\",\\\"quantity\\\":2,\\\"cost\\\":10,\\\"state\\\":\\\"pending\\\"}\"}}}"}
                        let backendResult = try JSONDecoder().decode(BackendResult.self, from: data)
                        
                        if backendResult.status == "done" {
                            let resultOfMakePurchase = try JSONDecoder().decode(ResultOfMakePurchase.self, from: backendResult.result!.data(using: .utf8)!)
                            let makePurchaseFinalResult = try JSONDecoder().decode(Contract.self, from: resultOfMakePurchase.result!.results.payload.data(using: .utf8)!)
                            onCompletion(makePurchaseFinalResult)
                        }
                        else {
                            let when = DispatchTime.now() + 1.5
                            DispatchQueue.main.asyncAfter(deadline: when) {
                                self.purchaseItemResults(resultId: resultId, attemptNumber: attemptNumber+1, onCompletion)
                            }
                        }
                    }  catch let error as NSError {
                        print(error.localizedDescription)
                        onCompletion(nil)
                    }
                } else if let error = error {
                    print(error.localizedDescription)
                    onCompletion(nil)
                }
            }
            resultsFromBlockchain.resume()
        }
        else {
            NSLog("Attempted 120 times to request transaction result... No results")
            onCompletion(nil)
        }
    }
}
