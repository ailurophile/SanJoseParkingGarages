//
//  LocationViewController.swift
//  SanJoseParkingGarages
//
//  Created by Lisa Litchfield on 5/8/17.
//  Copyright © 2017 Lisa Litchfield. All rights reserved.
//

import Foundation
import UIKit

class LocationViewController: UIViewController, UITextViewDelegate{
    
    @IBOutlet weak var textViewSwitch: UISwitch!
    @IBOutlet weak var locationTextView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        locationTextView.delegate = self
        //Load user preferences & Location reminder
        locationTextView.text = UserDefaults.standard.value(forKey: Keys.LocationReminder) as! String
//        locationTextView.text = "Does the box show up now?"

        let prefersTextClears = UserDefaults.standard.value(forKey: Keys.TextViewClears) as! Bool
        textViewSwitch.setOn(prefersTextClears, animated: true)
        
    }
    
    //MARK: TextView delegate methods
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        
        return true
    }
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textViewSwitch.isOn{
            locationTextView.text = ""
        }
    }
    
    func textViewDidChange(_ textView: UITextView) {
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        resignFirstResponder()
        view.endEditing(true)
    }
    
//MARK: UI interaction & User defaults 
    @IBAction func saveButtonPressed(_ sender: Any) {
        UserDefaults.standard.setValue(locationTextView.text, forKey: Keys.LocationReminder)
        UserDefaults.standard.synchronize()
    }
    
    @IBAction func locationTextSwitchSet(_ sender: Any) {
        UserDefaults.standard.setValue(textViewSwitch.isOn, forKey: Keys.TextViewClears)
        UserDefaults.standard.synchronize()
    }

}
