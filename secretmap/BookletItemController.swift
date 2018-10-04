//
//  BookletItemController.swift
//  secretmap
//
//  Created by Anton McConville on 2017-12-27.
//  Copyright © 2017 Anton McConville. All rights reserved.
//

import UIKit

class BookletItemController: UIViewController {
    
    @IBOutlet var contentImageView: UIImageView?
    @IBOutlet var pageTitleView: UILabel?
    @IBOutlet var subtitleView: UILabel?
    @IBOutlet var statement: UITextView?
    @IBOutlet var subtextView: UILabel?
    @IBOutlet var button:UIButton?
    var picker: UIPickerView?
    
    var events: [EventModel]?
    var rowPicker: Int?
    @IBOutlet weak var eventChoice: UITextField!
    
    @IBAction func openLink(_ sender: UIButton) {
         performSegue(withIdentifier: "webkitSegue", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "webkitSegue"
        {
            if let navController = segue.destination as? UINavigationController {
                let webview = navController.topViewController as! AssetViewController
                webview.link = self.link
            }
        }
    }
    
    // MARK: - Variables
    var itemIndex: Int = 0
    
    var link:String = ""
    
    var image: UIImage = UIImage() {
        didSet {
            if let imageView = contentImageView {
                imageView.image = image
            }
        }
    }
    
    var titleString: String = "" {
        didSet {
            if let titleView = pageTitleView {
                titleView.text = titleString
            }
        }
    }
    
    var subTitleString: String = "" {
        didSet {
            if let subtitleView = subtitleView {
                subtitleView.text = titleString
            }
        }
    }
    
    var statementString: String = "" {
        didSet {
            if let statement = statement {
                statement.text = statementString
            }
        }
    }
    
    var linkString: String = "" {
        didSet {
            link = linkString
        }
    }
    
    var gesture: UITapGestureRecognizer?
    
    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        contentImageView!.image = image
        pageTitleView!.text = titleString
        subtitleView!.text = subTitleString
        if itemIndex == 0 {
            subtitleView!.text = "other events >"
            EventClient().getEvents { (events) in
                DispatchQueue.main.async {
                    self.events = events
                    self.picker = UIPickerView()
                    self.picker?.backgroundColor = .white
                    self.picker?.dataSource = self
                    self.picker?.delegate = self
                    self.rowPicker = 0
                    self.eventChoice.delegate = self
                    let tap = UITapGestureRecognizer(target: self, action: #selector(BookletItemController.tapFunction))
                    self.subtitleView?.addGestureRecognizer(tap)
                    if SelectedEventCoreData(context: (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext).selectedEvent() == nil {
                        self.tapFunction(sender: tap)
                    }
                }
            }
        }
        
        statement?.text = statementString
        link = linkString
        
        button?.layer.cornerRadius = 20
        button?.clipsToBounds = true
    }
    
    @objc func donePicker() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.onEventSelection(self.events![self.rowPicker!].eventId!)
        
        self.enablePageViewController(true)
    }
    
    @objc func tapFunction(sender: UITapGestureRecognizer) {
        print("tap working")
        self.enablePageViewController(false)
        self.eventChoice.becomeFirstResponder()
    }
    
    @IBAction func eventEdit(_ sender: UITextField) {
        let toolBar = UIToolbar()
        toolBar.barStyle = UIBarStyle.default
        toolBar.backgroundColor = UIColor(red: 250/255, green: 250/255, blue: 248/255, alpha: 1)
        toolBar.sizeToFit()
        
        let doneButton = UIBarButtonItem(title: "Confirm", style: UIBarButtonItemStyle.plain, target: self, action: #selector(donePicker))
        let spaceButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil)
        
        toolBar.setItems([spaceButton, doneButton], animated: false)
        toolBar.isUserInteractionEnabled = true
        
        sender.inputView = self.picker
        sender.inputAccessoryView = toolBar
    }
    
    func enablePageViewController(_ enable: Bool) {
        if self.parent is UIPageViewController {
            if let bookletController = self.parent?.parent as? BookletController {
                if enable {
                    bookletController.pageViewController?.dataSource = bookletController
                    bookletController.createPageViewController()
                    bookletController.setupPageControl()
                    bookletController.getPages()
                } else {
                    bookletController.pageViewController?.dataSource = nil
                }
            }
        }
    }
}

extension BookletItemController: UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return self.events!.count
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        self.rowPicker = row
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return self.events![row].name
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
    }
}
