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
    
    var receivedProductList: [Product]?
    var productsInStock: [Product]?
    var userState: GetStateFinalResult?
    var receivedContracts: [Contract]?
    
    var pendingCharges: Int?
    var fitcoins: Int?
    var itemizedInventory: [String: Int] = [:]
    
    // Don't forget to enter this in IB also
    let cellReuseIdentifier = "cell"
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var selectedEventCoreData: SelectedEventCoreData?
    var eventCoreData: EventCoreData?
    
    
    @IBAction func unwindToShop(segue: UIStoryboardSegue) {
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let data = receivedContracts
        if let destinationViewController = segue.destination as? OrdersViewController {
            destinationViewController.userContracts = data
            if let selectedEvent = selectedEventCoreData?.selectedEvent() {
                destinationViewController.event = selectedEvent.event
            }
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
        
        if let selectedEvent = selectedEventCoreData?.selectedEvent() {
            if let person = eventCoreData?.getPerson(event: selectedEvent.event!) {
                // get state of user
                let userId = person.blockchain!
                let event = selectedEvent.event!
                let shopClient = ShopClient(userId: userId, event: event)
                UserClient(event: event).getUserState(userId: userId) { (state) in
                    DispatchQueue.main.async {
                        self.fitcoins = state.fitcoinsBalance
                        self.fitcoinsBalance.text = String(describing: state.fitcoinsBalance)
                    }
                }
                
                // get user contracts
                shopClient.getContracts { (contracts) in
                    if let contracts = contracts {
                        self.receivedContracts = contracts
                        var aggregatedCharges = 0
                        self.itemizedInventory = [:]
                        for contract in contracts {
                            if contract.state == "pending" {
                                aggregatedCharges += contract.cost
                            }
                            
                            // get total swags of users (ignore declined contracts)
                            if contract.state != "declined" {
                                if let currentItem = self.itemizedInventory[contract.productId] {
                                    self.itemizedInventory[contract.productId] = currentItem + contract.quantity
                                } else {
                                    self.itemizedInventory[contract.productId] = contract.quantity
                                }
                            }
                        }
                        print("INVENTORY OF USER")
                        print(self.itemizedInventory)
                        self.pendingCharges = aggregatedCharges
                        DispatchQueue.main.async {
                            self.ordersButton.isEnabled = true
                            self.pendingChargesBalance.text = String(describing: aggregatedCharges)
                        }
                    } else {
                        DispatchQueue.main.async {
                            self.ordersButton.isEnabled = true
                            self.receivedContracts = []
                            self.pendingCharges = 0
                            self.pendingChargesBalance.text = "0"
                        }
                    }
                }
                
                // get products
                shopClient.getProducts { (products) in
                    if let products = products {
                        DispatchQueue.main.async {
                            for product in products {
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
            }
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
        
        // initialize core data helpers
        selectedEventCoreData = SelectedEventCoreData(context: appDelegate.persistentContainer.viewContext)
        eventCoreData = EventCoreData(context: appDelegate.persistentContainer.viewContext)

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
        imageView.contentMode = .scaleAspectFit
        
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
            quantityViewController.currentQuantityOfUser = itemizedInventory[self.productsInStock![indexPath.row].productid]
            EventClient().getProductLimits(productId: (quantityViewController.payload?.productid)!) { (limit) in
                quantityViewController.productLimit = limit
                DispatchQueue.main.async {
                    self.present(quantityViewController, animated: true, completion: nil)
                }
            }
        }
        else {
            print("please wait")
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
