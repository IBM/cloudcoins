//
//  OrdersViewController.swift
//  secretmap
//
//  Created by Joe Anthony Peter Amanse on 2/21/18.
//  Copyright © 2018 Anton McConville. All rights reserved.
//

import UIKit

class OrdersViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet var tableView: UITableView!
    @IBAction func back(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    
    let cellReuseIdentifier = "contractCell"
    
    var userContracts: [Contract]?
    var event: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let themeColor = UIColor(red:0.76, green:0.86, blue:0.83, alpha:1.0)
        let statusBar = UIView(frame: CGRect(x:0, y:0, width:view.frame.width, height:UIApplication.shared.statusBarFrame.height))
        statusBar.backgroundColor = themeColor
        statusBar.tintColor = themeColor
        view.addSubview(statusBar)
        
        UIApplication.shared.statusBarStyle = .lightContent

        
//        bottomLabel.text? = ""
//
//        if userContracts == nil || userContracts?.count == 0 {
//            bottomLabel.text? = "You have not claimed any items yet."
//        } else {
//            bottomLabel.text? = "Swipe left to cancel a contract.\nClick on one to view its details."
//        }
        
        // This view controller itself will provide the delegate methods and row data for the table view.
        self.tableView.tableFooterView = UIView()
        self.tableView.delegate = self
        self.tableView.dataSource = self
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // number of rows in table view
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.userContracts!.count
    }
    
    // set row height
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
    
    // create a cell for each table view row
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // create a new cell if needed or reuse an old one
        let cell:OrderTableViewCell = self.tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier) as! OrderTableViewCell
        
        // set the text from the data model
        cell.contractId.text? = self.userContracts!.reversed()[indexPath.row].id
        cell.quickDetails.text? = "\(userContracts!.reversed()[indexPath.row].quantity) x \(userContracts!.reversed()[indexPath.row].productName)"
        cell.state.text? = self.userContracts!.reversed()[indexPath.row].state
        
        return cell
    }
    
    // method to run when table view cell is tapped
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.cellForRow(at: indexPath)?.setSelected(false, animated: false)
        self.transitionToContractView(payload: self.userContracts![self.userContracts!.count - 1 - indexPath.row])
    }
    
    // Cancel button
    func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        return "Decline"
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        if userContracts!.reversed()[indexPath.row].state == "pending" {
            return UITableViewCellEditingStyle.delete
        } else {
            return UITableViewCellEditingStyle.none
        }
    }
    
    // this method handles row deletion
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        
        if editingStyle == .delete {
            
            let alert = UIAlertController(title: "Decline this Contract?", message: "You have requested to decline contract\n\n \(userContracts!.reversed()[indexPath.row].id)\n\(userContracts!.reversed()[indexPath.row].quantity) of \(userContracts!.reversed()[indexPath.row].productName)\n\nThis can't be undone.", preferredStyle: UIAlertControllerStyle.actionSheet)
            alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "Yes, remove this contract", style: UIAlertActionStyle.destructive, handler: {
                (action: UIAlertAction) in
                if let eventId = self.event {
                    let currentContract = self.userContracts!.reversed()[indexPath.row]
                    ShopClient(userId: currentContract.userId, event: eventId).cancelContract(contractId: currentContract.id) { done in
                        if done {
                            self.alertDeclineSuccess()
                        }
                    }
                }
            }))
            
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    private func transitionToContractView(payload: Contract) {
        let contractViewController = self.storyboard?.instantiateViewController(withIdentifier: "contractReceived") as? ContractViewController
        contractViewController?.payload = payload
        print(payload)
        contractViewController?.receivedFromQuantityView = false
        self.present(contractViewController!, animated: true, completion: nil)
    }
    
    private func alertDeclineSuccess() {
        let alert = UIAlertController(title: "Request Sent!", message: "Your request to decline the contract has been sent to the blockchain network. The contract's state should update at a later time.", preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Okay", style: UIAlertActionStyle.default, handler: {
            (action: UIAlertAction) in self.dismiss(animated: true, completion: nil)
        }))
        self.present(alert, animated: true, completion: nil)
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
