//
//  NotifyUser.swift
//  SanJoseParkingGarages
//
//  Created by Lisa Litchfield on 5/4/17.
//  Copyright © 2017 Lisa Litchfield. All rights reserved.
//

import Foundation
import UIKit

// Method to show user alert from on background queue
func notifyUser(_ viewController: UIViewController, message:String){
    DispatchQueue.main.sync {
        sendAlert(viewController, message: message)
    }
}

// Method to show user alert from on main queue
func sendAlert(_ viewController: UIViewController, message:String){
    
    let controller = UIAlertController()
    controller.message = message
    let dismissAction = UIAlertAction(title: "Dismiss", style: .default){ action in
        controller.dismiss(animated: true, completion: nil)
    }
    controller.addAction(dismissAction)
    viewController.present(controller, animated: true, completion: nil)
}
