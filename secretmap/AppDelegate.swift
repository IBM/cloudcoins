//
//  AppDelegate.swift
//  secretmap
//
//  Created by Anton McConville on 2017-12-14.
//  Copyright © 2017 Anton McConville. All rights reserved.
//

import UIKit
import CoreData
import HealthKit
import CoreMotion
import UserNotifications
import UserNotificationsUI

import BMSCore
import BMSPush

struct PushClientResponse: Codable {
    var deviceId: String
}

extension Notification.Name {
    static let zoneEntered = Notification.Name(
        rawValue: "zoneEntered")
}

//struct iBeacon: Codable {
//    let zone: Int
//    let key: String
//    let value: String
//    let x: Int
//    let y: Int
//    let width: Int
//}
//
//struct iBeacons: Codable {
//    let beacons:[iBeacon]
//}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate,BMSPushObserver {


    var window: UIWindow?
    
    public var startDate: Date = Date()
    
    var healthKitEnabled = true
    
    var numberOfSteps:Int! = nil
    var distance:Double! = nil
    var averagePace:Double! = nil
    var pace:Double! = nil
    
    var pedometer = CMPedometer()
    
    var selectedEventCoreData: SelectedEventCoreData?
    var eventCoreData: EventCoreData?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        UITabBar.appearance().isTranslucent = false
        UITabBar.appearance().barTintColor = UIColor(red:0.96, green:0.96, blue:0.94, alpha:1.0)
        UITabBar.appearance().tintColor = UIColor(red:0.71, green:0.11, blue:0.31, alpha:1.0)
        
        UINavigationBar.appearance().barTintColor = UIColor(red:0.76, green:0.86, blue:0.83, alpha:1.0)
        UINavigationBar.appearance().tintColor = UIColor.white
        UINavigationBar.appearance().titleTextAttributes = [NSAttributedStringKey.foregroundColor:UIColor.black]
        
        // initialize core data helpers
        selectedEventCoreData = SelectedEventCoreData(context: self.persistentContainer.viewContext)
        eventCoreData = EventCoreData(context: self.persistentContainer.viewContext)
        
        
        // MARK: - Register/initialize after event selection with proper tags
        BMSClient.sharedInstance.initialize(bluemixRegion: BMSClient.Region.usSouth)
        // MARK: remove the hardcoding in future
        BMSPushClient.sharedInstance.initializeWithAppGUID(appGUID: "", clientSecret: "")
        BMSPushClient.sharedInstance.delegate = self as BMSPushObserver
        
        return true
    }
    
    func onEventSelection(_ eventName: String) {
        selectedEventCoreData?.chooseEvent(event: eventName)
        if eventCoreData?.getPerson(event: eventName) == nil {
            registerAtSelectedEvent(eventName)
        } else {
            print("Already registered on blockchain")
            // TODO: - register notification at a TAG for multi-event
        }
    }
    
    func registerAtSelectedEvent(_ eventName: String) {
        UserClient(event: eventName).registerUser { (userId, name, avatar) in
            self.eventCoreData?.savePerson(userId: userId, participantname: name, avatar: avatar, event: eventName)
            
            let alert = UIAlertController(title: "Enrollment successful!", message: "You have been enrolled to the blockchain network. Your User ID is:\n\n\(userId)", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "Confirm", style: UIAlertActionStyle.default, handler: nil))
            self.window?.rootViewController?.present(alert, animated: true, completion: nil)
        }
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        self.saveContext()
    }
    
    // MARK: - Core Data stack
    
    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
         */
        let container = NSPersistentContainer(name: "secretmap")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    // MARK: - Core Data Saving support
    
    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    func registerForPushNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) {
            (granted, error) in
            print("Permission granted: \(granted)")
            
            guard granted else { return }
            self.getNotificationSettings()
        }
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .badge, .sound])
    }
    
    func getNotificationSettings() {
        UNUserNotificationCenter.current().getNotificationSettings { (settings) in
            print("Notification settings: \(settings)")
            guard settings.authorizationStatus == .authorized else { return }
            UIApplication.shared.registerForRemoteNotifications()
        }
    }
    
    func onChangePermission(status: Bool) {
        print("Push Notification is enabled:  \(status)" as NSString)
    }
    
    func application (_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenParts = deviceToken.map { data -> String in
            return String(format: "%02.2hhx", data)
        }
        let token = tokenParts.joined()
        // 2. Print device token to use for PNs payloads
        print("Device Token: \(token)")
        
        let push =  BMSPushClient.sharedInstance
        push.registerWithDeviceToken(deviceToken: deviceToken) { (response, statusCode, error) -> Void in
            if error.isEmpty {
                print( "Response during device registration : \(String(describing: response))")
                print( "status code during device registration : \(String(describing: statusCode))")
                guard let response = response else {
                    return
                }
                do {
                    guard let data = response.data(using: .utf8) else {
                        return
                    }
                    let decodedResponse = try JSONDecoder().decode(PushClientResponse.self, from: data)
                } catch let error {
                    print("Error during parsing response: \(error.localizedDescription)")
                }
            } else {
                print( "Error during device registration \(error) ")
            }
        }
    }
}
