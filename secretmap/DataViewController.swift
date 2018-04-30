
//  SecondViewController.swift
//  secretmap
//
//  Created by Anton McConville on 2017-12-14.
//  Copyright © 2017 Anton McConville. All rights reserved.
//

import UIKit
import HealthKit
import CoreMotion

struct Place:Codable{
    var userPosition: Int
    var count: Int
    var steps: Int
}

class DataViewController: UIViewController {
    
    let appDelegate = UIApplication.shared.delegate
    
    var pedometer = CMPedometer()
    
    public var startDate: Date = Date()
    
    @IBOutlet weak var refreshButton: UIButton!
    @IBOutlet weak var stepsCountLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var userIdLabel: UILabel!
    @IBOutlet weak var fitcoinsLabel: UILabel!
    
    @IBOutlet weak var particpantLabel:UILabel!
    @IBOutlet weak var positionLabel:UILabel!
    @IBOutlet weak var avatarImage:UIImageView!
    
    var currentUser: BlockchainUser?
    
    let FITCOIN_STEPS_CONVERSION: Int = 100
    
    var totalStepsConvertedToFitcoin: Int?
    var fitcoinsBalanceFromBlockchain: Int?
    
    var sendingInProgress: Bool = false
    
    var enableRefreshWork: DispatchWorkItem?

    @IBAction func refreshFitcoins(_ sender: UIButton) {
        enableRefreshWork?.cancel()
        self.viewDidLoad()
        self.viewDidAppear(true)
    }
    
    func enableRefreshButton() {
        self.refreshButton.isEnabled = true
        self.refreshButton.isHidden = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        enableRefreshWork?.cancel()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        refreshButton.isEnabled = false
        refreshButton.isHidden = true
        
        enableRefreshWork = DispatchWorkItem {
            self.enableRefreshButton()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0, execute: enableRefreshWork!)
        
        fitcoinsLabel.text = "-"
        currentUser = BookletController().loadUser()
        if currentUser != nil {
            let userId: String = currentUser!.userId
            userIdLabel?.text = userId
            let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
            
            var currentPerson:Person
            
            var people: [Person] = []
            
            do {
                people = try context.fetch(Person.fetchRequest())
                
                if( people.count > 0 ){
                    currentPerson = people[0]
                    particpantLabel?.text = currentPerson.participantname
                    avatarImage?.image = self.base64ToImage(base64: currentPerson.avatar! )
                }
                
                self.showPosition()
                
            }catch{
                
            }
            
            self.getStateOfUser(userId)
        }
        else {
            userIdLabel?.text = "You are not enrolled in the Blockchain network."
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        let themeColor = UIColor(red:0.76, green:0.86, blue:0.83, alpha:1.0)
        let statusBar = UIView(frame: CGRect(x:0, y:0, width:view.frame.width, height:UIApplication.shared.statusBarFrame.height))
        statusBar.backgroundColor = themeColor
        statusBar.tintColor = themeColor
        view.addSubview(statusBar)
        
        self.getStepData()
        self.liveUpdateStepData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    let healthStore = HKHealthStore()
    
    func getStepData(){
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        
        var currentPerson:Person
        
        var people: [Person] = []
        
        do {
            people = try context.fetch(Person.fetchRequest())
            
            if( people.count > 0 ){
                currentPerson = people[0]
                
                self.startDate = currentPerson.startdate!
                
                pedometer.queryPedometerData(from: self.startDate, to: Date()) {
                    [weak self] pedometerData, error in
                    if let error = error {
                        //                        self?.on(error: error)
                    } else if let pedometerData = pedometerData {
                        DispatchQueue.main.async {
                            self?.stepsCountLabel.text = String(describing: pedometerData.numberOfSteps)
                            let distanceInKilometers: Double = (pedometerData.distance?.doubleValue)! / 1000.00
                            self?.distanceLabel.text = String(format: "%.2f", distanceInKilometers)
                        }
                    }
                }
            }
        }catch{}
    }
    
    func liveUpdateStepData(){
        pedometer.startUpdates(from: self.startDate, withHandler: { (pedometerData, error) in
            if let pedometerData = pedometerData{
                DispatchQueue.main.async {
                    self.stepsCountLabel.text = String(describing: pedometerData.numberOfSteps)
                    let distanceInKilometers: Double = (pedometerData.distance?.doubleValue)! / 1000.00
                    self.distanceLabel.text = String(format: "%.2f", distanceInKilometers)
                }
                
                // If nothing is sending yet
                if self.totalStepsConvertedToFitcoin != nil && self.sendingInProgress == false {
                    let difference: Int = pedometerData.numberOfSteps.intValue - self.totalStepsConvertedToFitcoin!
                    print(difference)
                    
                    // Only send when there is enough fitcoins to convert
                    if difference > self.FITCOIN_STEPS_CONVERSION {
                        
                        // Sending fitcoins sequence here
                        self.sendingInProgress = true
                        
                        let userId: String? = self.currentUser!.userId
                        
                        // Send to fitchain network
                        self.sendStepsToFitchain(userId: userId, numberOfStepsToSend: pedometerData.numberOfSteps.intValue)
                        // Send to Mongo for the dashboard
                        self.sendStepsToMongo(userId: userId, numberOfStepsToSend: pedometerData.numberOfSteps.intValue)
                    }
                }
            } else {
                print("steps are not available")
            }
        })
    }
    
    private func sendStepsToFitchain(userId: String?, numberOfStepsToSend: Int) {
        guard let url = URL(string: BlockchainGlobals.URL + "api/execute") else { return }
        let parameters: [String:Any]
        let request = NSMutableURLRequest(url: url)
        
        let session = URLSession.shared
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let args: [String] = [userId!, String(describing: numberOfStepsToSend)]
        parameters = ["type":"invoke", "queue":"user_queue","params":["userId": userId!,"fcn": "generateFitcoins", "args":args]]
        request.httpBody = try! JSONSerialization.data(withJSONObject: parameters, options: [])
        
        let sendStepsToBlockchain = session.dataTask(with: request as URLRequest) { (data, response, error) in
            
            if let data = data {
                do {
                    // Convert the data to JSON
                    let jsonSerialized = try JSONSerialization.jsonObject(with: data, options: []) as? [String : Any]
                    
                    if let json = jsonSerialized, let status = json["status"], let resultId = json["resultId"] {
                        NSLog(status as! String)
                        NSLog(resultId as! String) // Use this one to get blockchain payload
                        if status as! String == "success" {
                            
                            // Steps sent
                            self.sendingInProgress = false
                            
                            // Update steps that were used for conversion
                            let stepsUsedForConversion = numberOfStepsToSend - (numberOfStepsToSend % 100)
                            self.totalStepsConvertedToFitcoin = stepsUsedForConversion
                            
                            DispatchQueue.main.async {
                                self.refreshButton.isEnabled = true
                            }
                            
                            // Get state of user - should update fitcoins balance
                            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 3) {
                                self.getStateOfUser(userId!)
                            }
                        }
                    }
                }  catch let error as NSError {
                    self.sendingInProgress = false
                    print(error.localizedDescription)
                }
            } else if let error = error {
                self.sendingInProgress = false
                print(error.localizedDescription)
            }
        }
        sendStepsToBlockchain.resume()
    }
    
    private func sendStepsToMongo(userId: String?, numberOfStepsToSend: Int) {
        guard let url = URL(string: BlockchainGlobals.URL + "registerees/update/" + userId! + "/steps/" + String(describing: numberOfStepsToSend)) else { return }
        let request = NSMutableURLRequest(url: url)
        
        let session = URLSession.shared
        request.httpMethod = "POST"
        
        let sendToMongo = session.dataTask(with: request as URLRequest) { (data, response, error) in
            
            if let data = data {
                do {
                    
                }  catch let error as NSError {
                    print(error.localizedDescription)
                }
            } else if let error = error {
                print(error.localizedDescription)
            }
        }
        sendToMongo.resume()
    }
    
    // This should get user profile from userId
    // The request is queued
    private func getStateOfUser(_ userId: String, failedAttempts: Int? = 0) {
        guard let url = URL(string: BlockchainGlobals.URL + "api/execute") else { return }
        let parameters: [String:Any]
        let request = NSMutableURLRequest(url: url)
        
        let session = URLSession.shared
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let args: [String] = [userId]
        parameters = ["type":"query", "queue":"user_queue", "params":["userId": userId,"fcn": "getState", "args":args]]
        request.httpBody = try! JSONSerialization.data(withJSONObject: parameters, options: [])
        
        let getStateOfUser = session.dataTask(with: request as URLRequest) { (data, response, error) in
            
            if let data = data {
                do {
                    // Convert the data to JSON
                    let jsonSerialized = try JSONSerialization.jsonObject(with: data, options: []) as? [String : Any]
                    
                    if let json = jsonSerialized, let status = json["status"], let resultId = json["resultId"] {
                        NSLog(status as! String)
                        NSLog(resultId as! String) // Use this one to get blockchain payload
                        
                        // Start checking if our queued request is finished.
                        self.requestUserResults(resultId: resultId as! String, attemptNumber: 0, failedAttempts: failedAttempts!)
                    }
                }  catch let error as NSError {
                    print(error.localizedDescription)
                }
            } else if let error = error {
                print(error.localizedDescription)
            }
        }
        getStateOfUser.resume()
    }
    
    func showPosition() {
        
        var myPlace = Place(userPosition:0, count:0, steps:0)
        
        let urlString =  BlockchainGlobals.URL + "leaderboard/position/user/" + currentUser!.userId
        
        if let url = URL(string: urlString){
            
            URLSession.shared.dataTask(with: url) { (data, response, error) in
                if error != nil {
                    print(error!.localizedDescription)
                    print("No internet")
                }
                
                guard let data = data else { return }
                
                do {
                    //Decode retrived data with JSONDecoder and assing type of Article object
                    myPlace = try JSONDecoder().decode(Place.self, from: data)
                    
                    print(myPlace)
                    
                    DispatchQueue.main.async {
                        self.positionLabel.text = String(myPlace.userPosition) + " of " + String(myPlace.count)
                    }
                    
                } catch let jsonError {
                    print(jsonError)
                }
                }.resume()
            
        } else {
            print("registrant url error")
        }
    }
    
    func base64ToImage(base64: String) -> UIImage {
        var img: UIImage = UIImage()
        if (!base64.isEmpty) {
            let decodedData = NSData(base64Encoded: base64 , options: NSData.Base64DecodingOptions.ignoreUnknownCharacters)
            let decodedimage = UIImage(data: decodedData! as Data)
            img = (decodedimage as UIImage?)!
        }
        return img
    }
    
    private func requestUserResults(resultId: String, attemptNumber: Int, failedAttempts: Int? = 0) {
        // recursive function limited to 180 attempts - total of 90 seconds
        if attemptNumber < 180 {
            guard let url = URL(string: BlockchainGlobals.URL + "api/results/" + resultId) else { return }
            
            let session = URLSession.shared
            let resultsFromBlockchain = session.dataTask(with: url) { (data, response, error) in
                if let data = data {
                    do {
                        // data is
                        // {"status":"done","result":"{\"message\":\"success\",\"result\":\"{\\\"user\\\":\\\"4226e3af-5ae3-49bc-870c-886af9ec53a3\\\"}\"}"}
                        // Convert the data to JSON
                        let backendResult = try JSONDecoder().decode(BackendResult.self, from: data)
                        if backendResult.status == "done" {
                            print(backendResult.result!)
                            
                            let resultOfBlockchain = try JSONDecoder().decode(ResultOfBlockchain.self, from: backendResult.result!.data(using: .utf8)!)
                            
                            if resultOfBlockchain.message == "failed" || resultOfBlockchain.error != nil {
                                if failedAttempts! < 10 {
                                    print("getting user state failed, trying again")
                                    self.getStateOfUser(self.currentUser!.userId, failedAttempts: failedAttempts!+1)
                                } else {
                                    print("10 failed attempts reached -- getStateOfUser")
                                }
                            } else {
                                let finalResultOfGetState = try JSONDecoder().decode(GetStateFinalResult.self, from: resultOfBlockchain.result!.data(using: .utf8)!)
                                print(finalResultOfGetState)
                                self.fitcoinsBalanceFromBlockchain = finalResultOfGetState.fitcoinsBalance
                                self.totalStepsConvertedToFitcoin = finalResultOfGetState.stepsUsedForConversion
                                DispatchQueue.main.async {
                                    self.fitcoinsLabel.text = String(describing: self.fitcoinsBalanceFromBlockchain!)
                                }
                            }
                        }
                        else {
                            let when = DispatchTime.now() + 0.5 // 0.5 seconds from now
                            DispatchQueue.main.asyncAfter(deadline: when) {
                                self.requestUserResults(resultId: resultId, attemptNumber: attemptNumber+1)
                            }
                        }
                    }  catch let error as NSError {
                        print(error.localizedDescription)
                    }
                } else if let error = error {
                    print(error.localizedDescription)
                }
            }
            resultsFromBlockchain.resume()
        }
        else {
            NSLog("Attempted 60 times to enroll... No results")
        }
    }
}

