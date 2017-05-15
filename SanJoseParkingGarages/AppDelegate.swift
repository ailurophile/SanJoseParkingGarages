//
//  AppDelegate.swift
//  SanJoseParkingGarages
//
//  Created by Lisa Litchfield on 4/27/17.
//  Copyright © 2017 Lisa Litchfield. All rights reserved.
//

import UIKit
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        performOnFirstLaunch()
        return true
    }


    // MARK: - Core Data stack

    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
        */
        let container = NSPersistentContainer(name: "SanJoseParkingGarages")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                print("Unresolved error \(error), \(error.userInfo)")            }
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
                
                let nserror = error as NSError
                print("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    func performOnFirstLaunch() {
        if !UserDefaults.standard.bool(forKey: Keys.Not1stLaunch) {
            let prefersTextClears = true
            let initialText = "Enter reminder to help you locate your car when you return to the garage then select Save."
            UserDefaults.standard.setValue(prefersTextClears, forKey: Keys.TextViewClears)
            UserDefaults.standard.setValue(true, forKey: Keys.Not1stLaunch)
            UserDefaults.standard.setValue(initialText, forKey: Keys.LocationReminder)
            UserDefaults.standard.synchronize()
        }
    }


}

