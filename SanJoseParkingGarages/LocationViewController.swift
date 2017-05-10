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
    @IBAction func saveButtonPressed(_ sender: Any) {
        print("save button pressed")
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        locationTextView.delegate = self
        print("Value of switch is \(textViewSwitch.isOn)")
    }
    
//MARK: TextView delegate methods
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
 
        return true
    }
    func textViewDidBeginEditing(_ textView: UITextView) {
        print("entering text in textView")
    }
    
    func textViewDidChange(_ textView: UITextView) {
        print("textView field: \(locationTextView.text)")
    }
 
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        resignFirstResponder()
        view.endEditing(true)
    }
 

}
