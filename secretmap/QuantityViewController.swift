//
//  QuantityViewController.swift
//  secretmap
//
//  Created by Joe Anthony Peter Amanse on 2/19/18.
//  Copyright © 2018 Anton McConville. All rights reserved.
//

import UIKit

class QuantityViewController: UIViewController {
    
    var payload: Product?
    var fitcoins: Int?
    var pendingCharges: Int?
    
    @IBOutlet weak var productName: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var quantity: UILabel!
    @IBOutlet weak var stepper: UIStepper!
    @IBOutlet weak var claimButton: UIButton!
    @IBOutlet weak var totalPrice: UILabel!
    
    @IBOutlet var navigationBar: UINavigationBar!
    
    var currentUser: BlockchainUser?
    
    // Cancel button on top left
    @IBAction func cancel(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    // Increment or decrement number of quantity label
    @IBAction func addQuantity(_ sender: UIStepper) {
        quantity.text = Int(sender.value).description
        totalPrice.text = String(describing: Int(sender.value)*payload!.price)
    }
    
    // Change color when held
    @IBAction func claimButtonHeld(_ sender: UIButton) {
        claimButton.backgroundColor = UIColor.init(red: 232.00/255.00, green: 139.00/255.00, blue: 123.00/255.00, alpha: 1)
    }
    
    // Change it back when released
    @IBAction func claimButtonCancel(_ sender: UIButton) {
        claimButton.backgroundColor = UIColor.init(red: 215.00/255.00, green: 44.00/255.00, blue: 101.00/255.00, alpha: 1)
    }
    
    // Create the contract and disable button
    @IBAction func createContract(_ sender: UIButton) {
        
        stepper.tintColor = UIColor.lightGray
        claimButton.isEnabled = false
        stepper.isEnabled = false
        claimButton.alpha = 0.5
        stepper.alpha = 0.5
        if fitcoins! - pendingCharges! >= Int(totalPrice.text!)! {
            self.purchaseItem()
        }
        else {
            let alert = UIAlertController(title: "Purchase failed", message: "You don't have enough available fitcoins. You can cancel your pending orders if you want to change them.", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "Okay", style: UIAlertActionStyle.default, handler: {
                (action: UIAlertAction) in self.dismiss(animated: true, completion: nil)
            }))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let themeColor = UIColor(red:0.76, green:0.86, blue:0.83, alpha:1.0)
        let statusBar = UIView(frame: CGRect(x:0, y:0, width:view.frame.width, height:UIApplication.shared.statusBarFrame.height))
        statusBar.backgroundColor = themeColor
        statusBar.tintColor = themeColor
        view.addSubview(statusBar)
        
        if payload?.productid == "think-shirt" || payload?.productid == "think-bandana" {
            stepper.maximumValue = 2
        }
        else if payload?.productid == "eye-sticker" || payload?.productid == "em-sticker" || payload?.productid == "bee-sticker" {
            stepper.maximumValue = 3
        }
        
        imageView.image = UIImage(named: payload!.productid)
        productName.text = payload!.name
        totalPrice.text = String(describing: payload!.price)
        claimButton.layer.cornerRadius = 15
        currentUser = BookletController().loadUser()
        
        UIApplication.shared.statusBarStyle = .lightContent
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // This moves the user to the details of the contract
    private func transitionToContractView(payload: Contract) {
        let contractViewController = self.storyboard?.instantiateViewController(withIdentifier: "contractReceived") as? ContractViewController
        contractViewController?.payload = payload
        contractViewController?.receivedFromQuantityView = true
        self.present(contractViewController!, animated: true, completion: nil)
    }
    
    // This starts to make a contract of the purchase
    // This is queued
    private func purchaseItem() {
        guard let url = URL(string: BlockchainGlobals.URL + "api/execute") else { return }
        let parameters: [String:Any]
        let request = NSMutableURLRequest(url: url)
        
        let session = URLSession.shared
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        //{"userId":"USER_ID_HERE","fcn":"makePurchase","args":["USER_ID_HERE","SELER_ID_HERE","PRODUCT_ID_HERE","QUANTITY"]}
        let args: [String] = [currentUser!.userId,payload!.sellerid,payload!.productid,quantity.text!]
        parameters = ["type":"invoke", "queue":"user_queue","params":["userId":currentUser!.userId, "fcn":"makePurchase","args":args]]
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
                        self.requestTransactionResult(resultId: resultId as! String, attemptNumber: 0)
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
    
    // This pings the backend for the actual result of the blockchain network
    // After getting the user,
    private func requestTransactionResult(resultId: String, attemptNumber: Int) {
        if attemptNumber < 60 {
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
                            DispatchQueue.main.async {
                                self.transitionToContractView(payload: makePurchaseFinalResult)
                            }
                        }
                        else {
                            let when = DispatchTime.now() + 3
                            DispatchQueue.main.asyncAfter(deadline: when) {
                                self.requestTransactionResult(resultId: resultId, attemptNumber: attemptNumber+1)
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
            NSLog("Attempted 60 times to request transaction result... No results")
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
