//
//  ShopViewController.swift
//  secretmap
//
//  Created by Joe Anthony Peter Amanse on 2/15/18.
//  Copyright © 2018 Anton McConville. All rights reserved.
//

import UIKit

class ShopViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
//    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet var tableView: UITableView!
    @IBOutlet var ordersButton: UIBarButtonItem!
    @IBOutlet weak var fitcoinsBalance: UILabel!
    @IBOutlet weak var pendingChargesBalance: UILabel!
    
    var currentUser: BlockchainUser?
    var receivedProductList: [Product]?
    var productsInStock: [Product]?
    var userState: GetStateFinalResult?
    var receivedContracts: [Contract]?
    
    var pendingCharges: Int?
    var fitcoins: Int?
    
    // Don't forget to enter this in IB also
    let cellReuseIdentifier = "cell"
    
    
    @IBAction func unwindToShop(segue: UIStoryboardSegue) {
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let data = receivedContracts
        if let destinationViewController = segue.destination as? OrdersViewController {
            destinationViewController.userContracts = data
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        // this functions in viewDidAppear will allow users to always see the updated state
        // of their fitcoins, pending charges, and products available
        
        // set initial state
        self.fitcoins = nil
        self.pendingCharges = nil
        self.fitcoinsBalance.text = "-"
        self.pendingChargesBalance.text = "-"
        ordersButton.isEnabled = false
        self.receivedProductList = []
        self.productsInStock = []
        
        self.tableView.reloadData()
        self.tableView.tableFooterView = UIView()
        
        currentUser = BookletController().loadUser()
        // Get the state of user, user contracts, and products for sale
        if currentUser != nil {
            self.getStateOfUser(currentUser!.userId)
            self.getAllUserContracts(currentUser!.userId)
            self.getProductsForSale(currentUser!.userId)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let themeColor = UIColor(red:0.76, green:0.86, blue:0.83, alpha:1.0)

        let statusBar = UIView(frame: CGRect(x:0, y:0, width:view.frame.width, height:UIApplication.shared.statusBarFrame.height))
        statusBar.backgroundColor = themeColor
        statusBar.tintColor = themeColor
        view.addSubview(statusBar)
        
        UIApplication.shared.statusBarStyle = .lightContent

        // Do any additional setup after loading the view.
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
    
    // number of rows in table view
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.productsInStock!.count
    }
    
    // create a cell for each table view row
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell:ProductTableViewCell = self.tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier) as! ProductTableViewCell
        
        let productId = self.productsInStock![indexPath.row].productid
        
        let imageView = UIImageView(image: UIImage(named: productId))
        imageView.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
        imageView.contentMode = .scaleToFill
        
        for subview in cell.myView.subviews {
            subview.removeFromSuperview()
        }
        cell.myView.addSubview(imageView)
        cell.myCellLabel.text = self.productsInStock![indexPath.row].name
        cell.priceLabel.text = "\(self.productsInStock![indexPath.row].price) fitcoins each"
        cell.quantityLeftLabel.text = "\(self.productsInStock![indexPath.row].count) left"
        
        return cell
    }
    
    // method to run when table view cell is tapped
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let quantityViewController = self.storyboard?.instantiateViewController(withIdentifier: "quantity") as! QuantityViewController
        quantityViewController.payload = self.productsInStock![indexPath.row]
        if fitcoins != nil && pendingCharges != nil {
            quantityViewController.pendingCharges = pendingCharges
            quantityViewController.fitcoins = fitcoins
            self.present(quantityViewController, animated: true, completion: nil)
        }
        else {
            print("please wait")
            // in cases where getting pending charges fails
            // do we allow them to order and assume PENDING CHARGES is 0???
            
            // in cases where getting fitcoins balance fails
            // user trying to create a contract will fail if their fitcoins balance in blockchain is less (not accounting pending charges from pending contracts)
            // message from blockchain would be not enough balance
            // {"status":"done","result":"{\"message\":\"failed\",\"error\":\"Proposal rejected by some (all) of the peers: Error: 2 UNKNOWN: chaincode error (status: 500, message: Insufficient funds)\"}"}
            // status: String
            // result: String
            
            // message: String
            // error: String
            
            // in cases where both balance and charges fails
            // same case as above
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // Get producs for sale
    // This will queue the result
    // requestProductsForSaleResults will then be called
    private func getProductsForSale(_ userId: String, failedAttempts: Int? = 0) {
        guard let url = URL(string: BlockchainGlobals.URL + "api/execute") else { return }
        let parameters: [String:Any]
        let request = NSMutableURLRequest(url: url)
        let session = URLSession.shared
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        //{"userId":"766f2d71-a286-441b-afdd-11824c2ee226","fcn":"getProductsForSale","args":[]}
        let args: [String] = []
        parameters = ["type":"query", "queue":"user_queue","params":["userId":userId, "fcn":"getProductsForSale","args":args]]
        request.httpBody = try! JSONSerialization.data(withJSONObject: parameters, options: [])
        
        let showProducts = session.dataTask(with: request as URLRequest) { (data, response, error) in
            
            if let data = data {
                do {
                    // Convert the data to JSON
                    let jsonSerialized = try JSONSerialization.jsonObject(with: data, options: []) as? [String : Any]
                    
                    if let json = jsonSerialized, let status = json["status"], let resultId = json["resultId"] {
                        NSLog(status as! String)
                        NSLog(resultId as! String) // Use this one to get blockchain payload - should contain userId
                        
                        // Start pinging backend with resultId
                        self.requestProductsForSaleResults(resultId: resultId as! String, attemptNumber: 0, failedAttempts: failedAttempts!)
                    }
                }  catch let error as NSError {
                    print(error.localizedDescription)
                }
            } else if let error = error {
                print(error.localizedDescription)
            }
        }
        showProducts.resume()
    }
    
    // This pings the backend for the actual result from the blockchain network
    // It should update the view with the products
    // NOTE: will update to use a table view instead
    private func requestProductsForSaleResults(resultId: String, attemptNumber: Int, failedAttempts: Int? = 0) {
        // recursive function limited to 90 attempts - total of 90 seconds
        if attemptNumber < 90 {
            guard let url = URL(string: BlockchainGlobals.URL + "api/results/" + resultId) else { return }
            
            let session = URLSession.shared
            let resultsFromBlockchain = session.dataTask(with: url) { (data, response, error) in
                if let data = data {
                    do {
                        // data is
                        // {"status":"done","result":"{\"message\":\"success\",\"result\":\"[{\\\"sellerid\\\":\\\"f7fe46c2-589e-4b7d-99f8-39be0d97557f\\\",\\\"productid\\\":\\\"stickers-1234\\\",\\\"name\\\":\\\"Stickers\\\",\\\"count\\\":1000,\\\"price\\\":5},{\\\"sellerid\\\":\\\"f7fe46c2-589e-4b7d-99f8-39be0d97557f\\\",\\\"productid\\\":\\\"shirt-1234\\\",\\\"name\\\":\\\"Shirt\\\",\\\"count\\\":1000,\\\"price\\\":50}]\"}"}
                        
                        let backendResult = try JSONDecoder().decode(BackendResult.self, from: data)
                        
                        if backendResult.status == "done" {
                            
                            let resultOfBlockchain = try JSONDecoder().decode(ResultOfBlockchain.self, from: backendResult.result!.data(using: .utf8)!)
                            
                            if resultOfBlockchain.message == "failed" || resultOfBlockchain.error != nil {
                                if failedAttempts! < 10 {
                                    print("getting products failed, trying agian")
                                    self.getProductsForSale(self.currentUser!.userId)
                                } else {
                                     print("10 failed attempts reached -- getProductsForSale")
                                }
                            } else {
                                let productList = try JSONDecoder().decode([Product].self, from: resultOfBlockchain.result!.data(using: .utf8)!)
                                self.receivedProductList = productList
                                DispatchQueue.main.async {
                                    for product in productList {
                                        // check if in stock
                                        if product.count != 0 {
                                            self.productsInStock?.append(product)
                                        }
                                    }
                                    self.tableView.delegate = self
                                    self.tableView.dataSource = self
                                    self.tableView.alpha = 0
                                    self.tableView.reloadData()
                                    UIView.animate(withDuration: 0.5, animations: {self.tableView.alpha = 1.0})
                                }
                            }
                        }
                        else {
                            let when = DispatchTime.now() + 1 // 2 seconds from now
                            DispatchQueue.main.asyncAfter(deadline: when) {
                                self.requestProductsForSaleResults(resultId: resultId, attemptNumber: attemptNumber+1)
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
    
    // This should get user profile from userId
    // The request is queued
    // requestUserState will be called
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
                        self.requestUserState(resultId: resultId as! String, attemptNumber: 0, failedAttempts: failedAttempts!)
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
    
    // This should start pinging the backend for the actual result from the blockchain
    // It should update the current number of fitcoins of the user
    private func requestUserState(resultId: String, attemptNumber: Int, failedAttempts: Int? = 0) {
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
                                self.userState = finalResultOfGetState
                                
                                DispatchQueue.main.async {
                                    self.fitcoins = finalResultOfGetState.fitcoinsBalance
                                    self.fitcoinsBalance.text = String(describing: finalResultOfGetState.fitcoinsBalance)
                                }
                            }
                        }
                        else {
                            let when = DispatchTime.now() + 0.5 // 0.5 seconds from now
                            DispatchQueue.main.asyncAfter(deadline: when) {
                                self.requestUserState(resultId: resultId, attemptNumber: attemptNumber+1)
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
            NSLog("Attempted 60 times to get user state... No results")
        }
    }
    
    // This should start getting the user contracts
    // This is queued
    // requestUserContracts is then called
    private func getAllUserContracts(_ userId: String, failedAttempts: Int? = 0) {
        guard let url = URL(string: BlockchainGlobals.URL + "api/execute") else { return }
        let parameters: [String:Any]
        let request = NSMutableURLRequest(url: url)
        
        let session = URLSession.shared
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let args: [String] = [userId]
        parameters = ["type":"query", "queue":"user_queue", "params":["userId": userId,"fcn": "getAllUserContracts", "args":args]]
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
                        self.requestUserContracts(resultId: resultId as! String, attemptNumber: 0, failedAttempts: failedAttempts!)
                    }
                }  catch let error as NSError {
                    print(error.localizedDescription)
                }
            } else if let error = error {
                print(error.localizedDescription)
            }
        }
        getContracts.resume()
    }
    
    // This pings the backend for the actual result of the blockchain network
    // It should get the contracts list and compute for the pending charges
    // pending charges is just a sum of the total price of each pending contract
    private func requestUserContracts(resultId: String, attemptNumber: Int, failedAttempts: Int? = 0) {
        // recursive function limited to 60 attempts
        if attemptNumber < 180 {
            guard let url = URL(string: BlockchainGlobals.URL + "api/results/" + resultId) else { return }
            
            let session = URLSession.shared
            let resultsFromBlockchain = session.dataTask(with: url) { (data, response, error) in
                if let data = data {
                    do {
                        // data is
                        // {"status":"done","result":"{\"message\":\"success\",\"result\":\"[{\\\"id\\\":\\\"c883258\\\",\\\"sellerId\\\":\\\"06f2a544-bcdd-4b7d-8484-88f693e10aae\\\",\\\"userId\\\":\\\"fba55e2c-aab5-4b29-b5a9-a5d150883ace\\\",\\\"productId\\\":\\\"stickers-1234\\\",\\\"productName\\\":\\\"Sticker\\\",\\\"quantity\\\":3,\\\"cost\\\":15,\\\"state\\\":\\\"pending\\\"},{\\\"id\\\":\\\"c758758\\\",\\\"sellerId\\\":\\\"06f2a544-bcdd-4b7d-8484-88f693e10aae\\\",\\\"userId\\\":\\\"fba55e2c-aab5-4b29-b5a9-a5d150883ace\\\",\\\"productId\\\":\\\"stickers-1234\\\",\\\"productName\\\":\\\"Sticker\\\",\\\"quantity\\\":3,\\\"cost\\\":15,\\\"state\\\":\\\"pending\\\"},{\\\"id\\\":\\\"c523347\\\",\\\"sellerId\\\":\\\"06f2a544-bcdd-4b7d-8484-88f693e10aae\\\",\\\"userId\\\":\\\"fba55e2c-aab5-4b29-b5a9-a5d150883ace\\\",\\\"productId\\\":\\\"stickers-1234\\\",\\\"productName\\\":\\\"Sticker\\\",\\\"quantity\\\":3,\\\"cost\\\":15,\\\"state\\\":\\\"pending\\\"},{\\\"id\\\":\\\"c828661\\\",\\\"sellerId\\\":\\\"06f2a544-bcdd-4b7d-8484-88f693e10aae\\\",\\\"userId\\\":\\\"fba55e2c-aab5-4b29-b5a9-a5d150883ace\\\",\\\"productId\\\":\\\"stickers-1234\\\",\\\"productName\\\":\\\"Sticker\\\",\\\"quantity\\\":3,\\\"cost\\\":15,\\\"state\\\":\\\"pending\\\"},{\\\"id\\\":\\\"c396740\\\",\\\"sellerId\\\":\\\"06f2a544-bcdd-4b7d-8484-88f693e10aae\\\",\\\"userId\\\":\\\"fba55e2c-aab5-4b29-b5a9-a5d150883ace\\\",\\\"productId\\\":\\\"stickers-1234\\\",\\\"productName\\\":\\\"Sticker\\\",\\\"quantity\\\":3,\\\"cost\\\":15,\\\"state\\\":\\\"pending\\\"}]\"}"}
                        // Convert the data to JSON
                        let backendResult = try JSONDecoder().decode(BackendResult.self, from: data)
                        if backendResult.status == "done" {
                            print(backendResult.result!)
                            var pendingCharges: Int
                            pendingCharges = 0
                            
                            var pendingContracts: [Contract]
                            pendingContracts = []
                            
                            let resultOfBlockchain = try JSONDecoder().decode(ResultOfBlockchain.self, from: backendResult.result!.data(using: .utf8)!)
                            
                            if resultOfBlockchain.message == "failed" || resultOfBlockchain.error != nil {
                                if failedAttempts! < 10 {
                                    print("getting user contracts failed, trying agian")
                                    self.getAllUserContracts(self.currentUser!.userId)
                                }
                                else {
                                    print("10 failed attempts reached -- getAllUserContracts")
                                }
                            } else {
                                if resultOfBlockchain.result == "null" {
                                    DispatchQueue.main.async {
                                        self.ordersButton.isEnabled = true
                                        self.receivedContracts = []
                                        self.pendingCharges = 0
                                        self.pendingChargesBalance.text = "0"
                                    }
                                }
                                else {
                                    let finalResultOfUserContracts = try JSONDecoder().decode([Contract].self, from: resultOfBlockchain.result!.data(using: .utf8)!)
                                    
                                    
                                    
                                    // Get pending contracts
                                    for contract in finalResultOfUserContracts {
                                        if contract.state == "pending" {
                                            pendingContracts.append(contract)
                                        }
                                    }
                                    print(pendingContracts.count)
                                    
                                    // Sum of pending charges
                                    for newContract in pendingContracts {
                                        pendingCharges = pendingCharges + newContract.cost
                                    }
                                    
                                    DispatchQueue.main.async {
                                        self.ordersButton.isEnabled = true
                                        self.receivedContracts = finalResultOfUserContracts
                                        self.pendingCharges = pendingCharges
                                        self.pendingChargesBalance.text = String(describing: pendingCharges)
                                    }
                                }
                            }
                        }
                        else {
                            let when = DispatchTime.now() + 0.5 // 0.5 seconds from now
                            DispatchQueue.main.asyncAfter(deadline: when) {
                                self.requestUserContracts(resultId: resultId, attemptNumber: attemptNumber+1)
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
            NSLog("Attempted 60 times to get user state... No results")
        }
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
