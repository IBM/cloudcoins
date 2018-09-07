//
//  StandingsTableViewController.swift
//  fitcoin
//
//  Created by Anton McConville on 2018-04-22.
//  Copyright © 2018 Anton McConville. All rights reserved.
//

import Foundation

struct Participant: Codable {
    let steps: Int
    let name: String
    let png:String?
}

import UIKit

class StandingsTableViewController: UITableViewController {
    
    //MARK: Properties
    
    var standings = [Participant]()
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var selectedEventCoreData: SelectedEventCoreData?
    var currentEvent: String?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        selectedEventCoreData = SelectedEventCoreData(context: appDelegate.persistentContainer.viewContext)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if let selectedEvent = selectedEventCoreData?.selectedEvent() {
            currentEvent = selectedEvent.event
            
            let refreshControl = UIRefreshControl()
            refreshControl.addTarget(self, action:  #selector(getStandingsData), for: UIControlEvents.valueChanged)
            self.refreshControl = refreshControl
            
            // Load the sample data.
            getStandingsData()
        }
    }
    
    @objc private func refreshStandingsData(_ sender: Any) {
        // Fetch Weather Data
        getStandingsData()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return standings.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // Table view cells are reused and should be dequeued using a cell identifier.
        let cellIdentifier = "StandingViewCell"
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? StandingViewCell  else {
            fatalError("The dequeued cell is not an instance of MealTableViewCell.")
        }
        
        // Fetches the appropriate meal for the data source layout.
        let standing = standings[indexPath.row]
        
        cell.nameLabel.text = standing.name
        if let png = standing.png {
            cell.photoImageView.image = self.base64ToImage(base64: png)
        }
        cell.positionLabel.text = String(indexPath.row + 1)
        cell.nameLabel.text = String(standing.name)
        cell.stepsLabel.text = String(standing.steps) + " steps"
        
        self.tableView.allowsSelection = false;
        
        return cell
    }
    
    
    /*
     // Override to support conditional editing of the table view.
     override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
     // Return false if you do not want the specified item to be editable.
     return true
     }
     */
    
    /*
     // Override to support editing the table view.
     override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
     if editingStyle == .delete {
     // Delete the row from the data source
     tableView.deleteRows(at: [indexPath], with: .fade)
     } else if editingStyle == .insert {
     // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
     }
     }
     */
    
    /*
     // Override to support rearranging the table view.
     override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
     
     }
     */
    
    /*
     // Override to support conditional rearranging of the table view.
     override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
     // Return false if you do not want the item to be re-orderable.
     return true
     }
     */
    
    /*
     //MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
    //MARK: Private Methods
    
    
    @objc private func getStandingsData(){
        
        guard currentEvent != nil else {
            return
        }
        
        let urlString = BlockchainGlobals.URL + "leaderboard/" + currentEvent! + "/top/50"
        guard let url = URL(string: urlString) else {
            print("url error")
            return
        }
        
                URLSession.shared.dataTask(with: url) { (data, response, error) in
                    if error != nil {
                        print(error!.localizedDescription)
                        print("No internet")
        
                        // use booklet.json if no internet
                    }
        
                    guard let data = data else { return }
        
                    do {
                        //Decode retrived data with JSONDecoder and assing type of Article object
                        self.standings = try JSONDecoder().decode([Participant].self, from: data)
        
                        DispatchQueue.main.async {
                            self.tableView.reloadData()
                            self.refreshControl?.endRefreshing()
//                            self.refreshControl?.endRefreshing()
//                            self.activityIndicatorView.stopAnimating()
                        }
                        
                    } catch let jsonError {
                        print(jsonError)
                    }
                }.resume()

        
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
