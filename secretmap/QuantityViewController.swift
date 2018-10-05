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
    var productLimit: Int?
    var currentQuantityOfUser: Int?
    
    @IBOutlet weak var productName: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var quantity: UILabel!
    @IBOutlet weak var stepper: UIStepper!
    @IBOutlet weak var claimButton: UIButton!
    @IBOutlet weak var totalPrice: UILabel!
    
    @IBOutlet var navigationBar: UINavigationBar!
    
//    var currentUser: BlockchainUser?
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var selectedEventCoreData: SelectedEventCoreData?
    var eventCoreData: EventCoreData?
    
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
//            self.purchaseItem()
            if let selectedEvent = selectedEventCoreData?.selectedEvent(), let person = eventCoreData?.getPerson(event: selectedEvent.event!) {
                if let productLimit = productLimit, let currentUserHas = currentQuantityOfUser {
                    
                    if currentUserHas + Int(quantity.text!)! <= productLimit {
                        ShopClient(userId: person.blockchain!, event: selectedEvent.event!).purchaseItem(sellerId: payload!.sellerid, productId: payload!.productid, quantity: quantity.text!) { (contract) in
                            if let contract = contract {
                                DispatchQueue.main.async {
                                    self.transitionToContractView(payload: contract)
                                }
                            }
                        }
                    } else {
                        let alert = UIAlertController(title: "Purchase failed", message: "A limit of \(productLimit) has been set right now for \(payload!.name).\nYou already have \(currentUserHas) of \(payload!.name)", preferredStyle: UIAlertControllerStyle.alert)
                        alert.addAction(UIAlertAction(title: "Okay", style: UIAlertActionStyle.default, handler: {
                            (action: UIAlertAction) in self.dismiss(animated: true, completion: nil)
                        }))
                        self.present(alert, animated: true, completion: nil)
                    }
                } else {
                    ShopClient(userId: person.blockchain!, event: selectedEvent.event!).purchaseItem(sellerId: payload!.sellerid, productId: payload!.productid, quantity: quantity.text!) { (contract) in
                        if let contract = contract {
                            DispatchQueue.main.async {
                                self.transitionToContractView(payload: contract)
                            }
                        }
                    }
                }
                
            }
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
        
        // initialize core data helpers
        selectedEventCoreData = SelectedEventCoreData(context: appDelegate.persistentContainer.viewContext)
        eventCoreData = EventCoreData(context: appDelegate.persistentContainer.viewContext)
        
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

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
