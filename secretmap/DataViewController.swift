
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
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
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
    
    let FITCOIN_STEPS_CONVERSION: Int = 100
    
    var totalStepsConvertedToFitcoin: Int?
    var fitcoinsBalanceFromBlockchain: Int?
    
    var sendingInProgress: Bool = false
    
    var enableRefreshWork: DispatchWorkItem?
    
    var selectedEventCoreData: SelectedEventCoreData?
    var eventCoreData: EventCoreData?

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
        
        self.fitcoinsLabel.text = "-"
        self.positionLabel.text = "-"
        
        self.getStateOfUser()
        self.getStepData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        let themeColor = UIColor(red:0.76, green:0.86, blue:0.83, alpha:1.0)
        let statusBar = UIView(frame: CGRect(x:0, y:0, width:view.frame.width, height:UIApplication.shared.statusBarFrame.height))
        statusBar.backgroundColor = themeColor
        statusBar.tintColor = themeColor
        view.addSubview(statusBar)
        
        // initialize core data helpers
        selectedEventCoreData = SelectedEventCoreData(context: appDelegate.persistentContainer.viewContext)
        eventCoreData = EventCoreData(context: appDelegate.persistentContainer.viewContext)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    let healthStore = HKHealthStore()
    
    func getStepData() {
        if let selectedEvent = selectedEventCoreData?.selectedEvent(), let person = eventCoreData?.getPerson(event: selectedEvent.event!) {
            pedometer.queryPedometerData(from: person.startdate!, to: Date()) { (pedometerData, error) in
                if let error = error {
                    print(error)
                } else if let pedometerData = pedometerData {
                    DispatchQueue.main.async {
                        self.stepsCountLabel.text = String(describing: pedometerData.numberOfSteps)
                        self.distanceLabel.text = String(format: "%.2f", (pedometerData.distance?.doubleValue)! / 1000)
                    }
                    self.liveUpdateStepData(userId: person.blockchain!, date: person.startdate!, event: selectedEvent.event!)
                }
            }
        }
    }
    
    func liveUpdateStepData(userId: String, date: Date, event: String){
        pedometer.startUpdates(from: date, withHandler: { (pedometerData, error) in
            if let pedometerData = pedometerData{
                DispatchQueue.main.async {
                    self.stepsCountLabel.text = String(describing: pedometerData.numberOfSteps)
                    self.distanceLabel.text = String(format: "%.2f", (pedometerData.distance?.doubleValue)! / 1000.00)
                }
                
                // If nothing is sending yet
                if self.totalStepsConvertedToFitcoin != nil && self.sendingInProgress == false {
                    let difference: Int = pedometerData.numberOfSteps.intValue - self.totalStepsConvertedToFitcoin!
                    print(difference)
                    
                    // Only send when there is enough fitcoins to convert
                    if difference > self.FITCOIN_STEPS_CONVERSION {
                        
                        // Sending fitcoins sequence here
                        self.sendingInProgress = true
                        
                        // send steps
                        UserClient(event: event).sendSteps(userId: userId, steps: pedometerData.numberOfSteps.intValue) { stepsUsedForConversion in
                            self.sendingInProgress = false
                            if let stepsUsedForConversion = stepsUsedForConversion {
                                self.totalStepsConvertedToFitcoin = stepsUsedForConversion
                            }
                            DispatchQueue.main.async {
                                self.refreshButton.isEnabled = true
                            }
                            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 3) {
                                self.getStateOfUser()
                            }
                        }
                        
//                        let userId: String? = self.currentUser!.userId
                        
                        // Send to fitchain network
//                        self.sendStepsToFitchain(userId: userId, numberOfStepsToSend: pedometerData.numberOfSteps.intValue)
                        // Send to Mongo for the dashboard
//                        self.sendStepsToMongo(userId: userId, numberOfStepsToSend: pedometerData.numberOfSteps.intValue)
                    }
                }
            } else {
                print("steps are not available")
            }
        })
    }
    
    private func getStateOfUser() {
        if let selectedEvent = selectedEventCoreData?.selectedEvent(), let person = eventCoreData?.getPerson(event: selectedEvent.event!)  {
            let userId: String? = person.blockchain
            userIdLabel.text = userId
            particpantLabel.text = person.participantname
            if let avatar = person.avatar {
                avatarImage.image = self.base64ToImage(base64: avatar)
            }
            if let userId = userId {
                let eventName = selectedEvent.event!
                self.showPosition(userId: userId, event: eventName)
                UserClient(event: eventName).getUserState(userId: userId) { (state) in
                    self.fitcoinsBalanceFromBlockchain = state.fitcoinsBalance
                    self.totalStepsConvertedToFitcoin = state.stepsUsedForConversion
                    DispatchQueue.main.async {
                        self.fitcoinsLabel.text = String(describing: self.fitcoinsBalanceFromBlockchain!)
                    }
                }
            }
        } else {
            userIdLabel?.text = "You are not enrolled in the Blockchain network."
        }
    }
    
    func showPosition(userId: String, event: String) {
        
        var myPlace = Place(userPosition:0, count:0, steps:0)
        
        let urlString =  BlockchainGlobals.URL + "leaderboard/" + event + "/position/user/" + userId
        
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
}

