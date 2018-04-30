//
//  BookletController.swift
//  secretmap
//
//  Created by Anton McConville on 2017-12-18.
//  Copyright © 2017 Anton McConville. All rights reserved.
//

import Foundation

import UIKit

struct Article: Codable {
    let page: Int
    let title: String
    let subtitle: String
    let imageEncoded:String
    let subtext:String
    let description: String
    let link: String
}

struct Avatar:Codable{
    let name: String
    let png: String
}

class BookletController: UIViewController, UIPageViewControllerDataSource {
    
    private var pageViewController: UIPageViewController?
    
    private var pages:[Article]?
    // testedit
    private var pageCount = 0
    
    var blockchainUser: BlockchainUser?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let existingUserId = loadUser() {
            blockchainUser = existingUserId
        }
        else {
            self.getNumberOfRegisteredUsers(limit: 1000)
        }
                
        let urlString = "https://anthony-blockchain.us-south.containers.mybluemix.net/pages"
        guard let url = URL(string: urlString) else {
            print("url error")
            return
        }

        URLSession.shared.dataTask(with: url) { (data, response, error) in
            if error != nil {
                print(error!.localizedDescription)
                print("No internet")

                // use booklet.json if no internet
                self.useDefaultPages()
            }

            guard let data = data else { return }

            do {
                //Decode retrived data with JSONDecoder and assing type of Article object
                let pages = try JSONDecoder().decode([Article].self, from: data)

                //Get back to the main queue
                DispatchQueue.main.async {
                    self.pages = pages
                    self.pageCount = pages.count
                    self.createPageViewController()
                    self.setupPageControl()
                }
            } catch let jsonError {
                print(jsonError)

                // use booklet.json if jsonError
                self.useDefaultPages()
            }
        }.resume()
    }
    
    private func useDefaultPages() {
        if let path = Bundle.main.url(forResource: "booklet", withExtension: "json") {
            do {
                let jsonData = try Data(contentsOf: path, options: .mappedIfSafe)
                let pages = try JSONDecoder().decode([Article].self, from: jsonData)
                print(pages)
                DispatchQueue.main.async {
                    self.pages = pages
                    self.pageCount = pages.count
                    self.createPageViewController()
                    self.setupPageControl()
                }
            } catch {
                print("couldn't parse JSON Data")
            }
        }
    }
    
    private func getNumberOfRegisteredUsers(limit: Int) {
        
        let urlString = BlockchainGlobals.URL + "registerees/totalUsers"
        guard let url = URL(string: urlString) else {
            print("url error")
            return
        }
        
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            if error != nil {
                print(error!.localizedDescription)
                print("No internet")
            }
            
            guard let data = data else { return }
            
            do {
                let numberOfUsers = try JSONDecoder().decode(NumberOfUsers.self, from: data)
                
                print(numberOfUsers)
                
                if numberOfUsers.count! < limit {
                    print("number of users not yet reached")
                    self.enrollUser()
                }
                else {
                    print("number of users reached")
                }
                
            } catch let jsonError {
                print(jsonError)
            }
        }.resume()
    }
    
    private func createPageViewController() {
        
        let pageController = self.storyboard!.instantiateViewController(withIdentifier: "booklet") as! UIPageViewController
        pageController.dataSource = self
        if self.pageCount > 0 {
            let firstController = getItemController(itemIndex: 0)!
            let startingViewControllers = [firstController]
            pageController.setViewControllers(startingViewControllers, direction: UIPageViewControllerNavigationDirection.forward, animated: false, completion: nil)
        }
        
        pageViewController = pageController
        pageViewController?.view.frame = CGRect(x: 0,y: 0,width: self.view.frame.width,height: self.view.frame.size.height)
        addChildViewController(pageViewController!)
        self.view.addSubview(pageViewController!.view)
        pageViewController!.didMove(toParentViewController: self)
    }
    
    private func setupPageControl() {
        let pageControl = pageViewController?.view.subviews.filter{ $0 is UIPageControl }.first! as! UIPageControl
        pageControl.backgroundColor = UIColor.white
        pageControl.pageIndicatorTintColor = UIColor(red:0.97, green:0.84, blue:0.88, alpha:1.0)
        pageControl.currentPageIndicatorTintColor = UIColor(red:0.87, green:0.21, blue:0.44, alpha:1.0)
        self.view.addSubview(pageControl)
    }
    
    // MARK: - UIPageViewControllerDataSource
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        
        let itemController = viewController as! BookletItemController
        
        if itemController.itemIndex > 0 {
            return getItemController(itemIndex: itemController.itemIndex-1)
        }
        
        return nil
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        
        let itemController = viewController as! BookletItemController
        
        if itemController.itemIndex+1 < self.pageCount {
            return getItemController(itemIndex: itemController.itemIndex+1)
        }
        
        return nil
    }
    
    private func getItemController(itemIndex: Int) -> BookletItemController? {
        
        if itemIndex < self.pages!.count {
            let pageItemController = self.storyboard!.instantiateViewController(withIdentifier: "ItemController") as! BookletItemController
            pageItemController.itemIndex = itemIndex
            pageItemController.titleString = self.pages![itemIndex].title
            pageItemController.subTitleString = self.pages![itemIndex].subtitle
            pageItemController.image = self.base64ToImage(base64: self.pages![itemIndex].imageEncoded)
            pageItemController.statementString = self.pages![itemIndex].description
            pageItemController.linkString = self.pages![itemIndex].link
            
            return pageItemController
        }
        
        return nil
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
    
    // MARK: - Page Indicator
    
    func presentationCount(for pageViewController: UIPageViewController) -> Int {
        return self.pages!.count
    }
    
    func presentationIndex(for pageViewController: UIPageViewController) -> Int {
        return 0
    }
    
    // MARK: - Additions
    
    func currentControllerIndex() -> Int {
        
        let pageItemController = self.currentController()
        
        if let controller = pageItemController as? BookletItemController {
            return controller.itemIndex
        }
        
        return -1
    }
    
    // request results of enrollment to blockchain
    
    private func enrollUser() {
        guard let url = URL(string: BlockchainGlobals.URL + "api/execute") else { return }
        let parameters: [String:Any]
        let request = NSMutableURLRequest(url: url)
        
        let session = URLSession.shared
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        parameters = ["type":"enroll", "queue":"user_queue", "params":[]]
        request.httpBody = try! JSONSerialization.data(withJSONObject: parameters, options: [])
        
        let enrollUser = session.dataTask(with: request as URLRequest) { (data, response, error) in
            
            if let data = data {
                do {
                    // Convert the data to JSON
                    let jsonSerialized = try JSONSerialization.jsonObject(with: data, options: []) as? [String : Any]
                    
                    if let json = jsonSerialized, let status = json["status"], let resultId = json["resultId"] {
                        NSLog(status as! String)
                        NSLog(resultId as! String) // Use this one to get blockchain payload - should contain userId
                        
                        // Start pinging backend with resultId
                        self.requestResults(resultId: resultId as! String, attemptNumber: 0)
                    }
                }  catch let error as NSError {
                    print(error.localizedDescription)
                }
            } else if let error = error {
                print(error.localizedDescription)
            }
        }
        enrollUser.resume()
    }
    
    private func requestResults(resultId: String, attemptNumber: Int) {
        if attemptNumber < 60 {
            guard let url = URL(string: BlockchainGlobals.URL + "api/results/" + resultId) else { return }
            
            let session = URLSession.shared
            let enrollUser = session.dataTask(with: url) { (data, response, error) in
                if let data = data {
                    do {
                        // data is
                        // {"status":"done","result":"{\"message\":\"success\",\"result\":{\"user\":\"ffc22a44-a34a-453b-997a-117f00ec651e\",\"txId\":\"67a76bf0063ed13a41448d9428f21ee3cf345e4ed90ba2edf0e2ddea569c3a16\"}}"}
                        
                        // Convert the data to JSON
                        let backendResult = try JSONDecoder().decode(BackendResult.self, from: data)
                        // if the status from queue is done
                        if backendResult.status == "done" {
                            
                            let resultOfEnroll = try JSONDecoder().decode(ResultOfEnroll.self, from: backendResult.result!.data(using: .utf8)!)
                            print(resultOfEnroll.result!.user)
                            
                            self.blockchainUser = BlockchainUser(userId: resultOfEnroll.result!.user)
                            self.saveUser()
                            
                            let alert = UIAlertController(title: "Enrollment successful!", message: "You have been enrolled to the blockchain network. Your User ID is:\n\n\(resultOfEnroll.result!.user)", preferredStyle: UIAlertControllerStyle.alert)
                            alert.addAction(UIAlertAction(title: "Confirm", style: UIAlertActionStyle.default, handler: nil))
                            self.present(alert, animated: true, completion: nil)
                            self.sendToMongo(resultOfEnroll.result!.user)
                        }
                        else {
                            let when = DispatchTime.now() + 3 // 3 seconds from now
                            DispatchQueue.main.asyncAfter(deadline: when) {
                                self.requestResults(resultId: resultId, attemptNumber: attemptNumber+1)
                            }
                        }
                        
                    }  catch let error as NSError {
                        print(error.localizedDescription)
                    }
                } else if let error = error {
                    print(error.localizedDescription)
                }
            }
            enrollUser.resume()
        }
        else {
            NSLog("Attempted 60 times to enroll... No results")
        }
    }
    
    
    // Save User generated from Blockchain Network
    
    private func saveUser() {
        let isSuccessfulSave = NSKeyedArchiver.archiveRootObject(blockchainUser!, toFile: BlockchainUser.ArchiveURL.path)
        if isSuccessfulSave {
            print("User has been enrolled and persisted.")
        } else {
            print("Failed to save user...")
        }
    }
    
    // Save User to cloud
    
    private func sendToMongo(_ userId: String) {
        guard let url = URL(string: BlockchainGlobals.URL + "registerees/add") else { return }
        let parameters: [String:Any]
        let request = NSMutableURLRequest(url: url)
        
        let session = URLSession.shared
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        parameters = ["registereeId": userId, "steps":0, "calories":0, "device":"ios"]
        request.httpBody = try! JSONSerialization.data(withJSONObject: parameters, options: [])
        
        let saveAsRegisteree = session.dataTask(with: request as URLRequest) { (data, response, error) in
            
            if let data = data {
                do {
                    // Convert the data to JSON
                    let jsonSerialized = try JSONSerialization.jsonObject(with: data, options: []) as? [String : Any]
                    
                    if let json = jsonSerialized, let name = json["name"], let png = json["png"] {
                        
                        DispatchQueue.main.async {
                        
                            let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
                            
                            var currentPerson:Person
                            
                            var people: [Person] = []
                            
                            do {
                                people = try context.fetch(Person.fetchRequest())
                                
                                if( people.count > 0 ){
                                    currentPerson = people[0]
                                    
                                    let particpant = name as! String
                                    let avatar = png as! String
                                    
                                    currentPerson.setValue(particpant, forKey: "participantname")
                                    currentPerson.setValue(avatar, forKey: "avatar")
                                    
                                    try context.save()
                                }
                            }catch{
                                print("problem saving generated avatar")
                            }
                        }
                    }
                }  catch let error as NSError {
                    print(error.localizedDescription)
                }
            } else if let error = error {
                print(error.localizedDescription)
            }
            
        }
        saveAsRegisteree.resume()
    }
    
    // Load User
    
    func loadUser() -> BlockchainUser?  {
        return NSKeyedUnarchiver.unarchiveObject(withFile: BlockchainUser.ArchiveURL.path) as? BlockchainUser
    }
    
    func currentController() -> UIViewController? {
        
        let count:Int = (self.pageViewController?.viewControllers?.count)!;
        
        if count > 0 {
            return self.pageViewController?.viewControllers![0]
        }
        
        return nil
    }
}
