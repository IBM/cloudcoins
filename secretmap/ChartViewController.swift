//
//  ViewController.swift
//  SwiftyStats
//
//  Created by Brian Advent on 19.03.18.
//  Copyright © 2018 Brian Advent. All rights reserved.
//

import UIKit
import Charts

struct Attendees: Codable {
    let prediction: Int
    let currentParticipants: Int
}

class ChartViewController: UIViewController {
    
    var projections: [String]!
    var participants = [Double]()
    weak var axisFormatDelegate: IAxisValueFormatter?
    
    var link:String = "https://ibm.biz/cloudcoinsml"
    
    @IBOutlet var button:UIButton?
    @IBOutlet var viewForChart: BarChartView!
    var labels: [String]! = ["Projected", "Actual"]
    
    var selectedEventCoreData: SelectedEventCoreData?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.getPrediction()
        
        button?.layer.cornerRadius = 20
        button?.clipsToBounds = true
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    

    
    func updateChart(dataEntryX forX:[String],dataEntryY forY: [Double]) {
        viewForChart.noDataText = "You need to provide data for the chart."
        var dataEntries:[BarChartDataEntry] = []
        for i in 0..<forX.count{
            let dataEntry = BarChartDataEntry(x: Double(i), y: Double(forY[i]) , data: projections as AnyObject)
            print(dataEntry)
            dataEntries.append(dataEntry)
        }
        let chartDataSet = BarChartDataSet(values: dataEntries, label: "Projected versus actual participants")
        let chartData = BarChartData(dataSet: chartDataSet)
        
        let initialcolor = UIColor(red:1.00, green:0.52, blue:0.05, alpha:1.0)
        let actualcolor = UIColor(red:0.42, green:0.31, blue:0.47, alpha:1.0)
        let adjustedcolor = UIColor(red:0.97, green:0.81, blue:0.94, alpha:1.0)
        
        chartDataSet.colors = [actualcolor, adjustedcolor, initialcolor]
        
        viewForChart.chartDescription?.enabled = false
        viewForChart.xAxis.drawLabelsEnabled = false
        viewForChart.data = chartData
        viewForChart.rightAxis.drawGridLinesEnabled = false
//        viewForChart.leftAxis.drawGridLinesEnabled = false
        viewForChart.xAxis.drawGridLinesEnabled = false
        let xAxisValue = viewForChart.xAxis
        xAxisValue.valueFormatter = axisFormatDelegate
        
        viewForChart.xAxis.valueFormatter = DefaultAxisValueFormatter(block: {(index, _) in
            return self.labels[Int(index)]
        })
    }
    
    func getPrediction() {
        var urlString = "https://watsonml.opencloud-cluster.us-south.containers.appdomain.cloud/prediction/"
        selectedEventCoreData = SelectedEventCoreData(context: (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext)
        if let selectedEvent = selectedEventCoreData?.selectedEvent() {
            urlString += selectedEvent.event!
        } else {

        }
        
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
                //Decode retrived data with JSONDecoder and assing type of Article object
                let attendees = try JSONDecoder().decode(Attendees.self, from: data)
                
                print(attendees)
                
                //Get back to the main queue
                DispatchQueue.main.async {
                    self.projections = ["Initial Projection", "Actual"]
                    self.participants = [Double(attendees.prediction), Double(attendees.currentParticipants)]
                    self.updateChart(dataEntryX: self.projections, dataEntryY: self.participants)
                }
            } catch let jsonError {
                print(jsonError)

            }
        }.resume()
    }
    
    @IBAction func openLink(_ sender: UIButton) {
        performSegue(withIdentifier: "aboutMLSegue", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "aboutMLSegue"
        {
            if let navController = segue.destination as? UINavigationController {
                let webview = navController.topViewController as! AssetViewController
                webview.link = self.link
            }
        }
    }
}


