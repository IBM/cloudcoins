//
//  ContractViewController.swift
//  secretmap
//
//  Created by Joe Anthony Peter Amanse on 2/20/18.
//  Copyright © 2018 Anton McConville. All rights reserved.
//

import UIKit

class ContractViewController: UIViewController {
    
    @IBOutlet var quantity: UILabel!
    @IBOutlet var totalPrice: UILabel!
    @IBOutlet var productName: UILabel!
    @IBOutlet var contractId: UILabel!
    @IBOutlet var contractState: UILabel!
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var messageForState: UILabel!
    var payload: Contract?
    var receivedFromQuantityView: Bool?

    @IBAction func back(_ sender: UIBarButtonItem) {
        if receivedFromQuantityView! {
            self.performSegue(withIdentifier: "unwindToShop", sender: self)
        }
        else {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let themeColor = UIColor(red:0.76, green:0.86, blue:0.83, alpha:1.0)
        let statusBar = UIView(frame: CGRect(x:0, y:0, width:view.frame.width, height:UIApplication.shared.statusBarFrame.height))
        statusBar.backgroundColor = themeColor
        statusBar.tintColor = themeColor
        view.addSubview(statusBar)
        
        UIApplication.shared.statusBarStyle = .lightContent

        
        
        print(payload!)
        
        imageView.image = UIImage(named: payload!.productId)
        quantity.text = String(describing: payload!.quantity)
        totalPrice.text = String(describing: payload!.cost)
        productName.text = payload!.productName
        contractId.text = payload!.id
        contractState.text = payload!.state
        if payload!.state == "pending" {
            messageForState.text = "your swags are waiting in our booth!"
        } else if payload!.state == "complete" {
            messageForState.text = "enjoy the swag!"
        } else {
            messageForState.text = ""
        }
        // Do any additional setup after loading the view.
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
