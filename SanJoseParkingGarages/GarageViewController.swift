//
//  GarageViewController.swift
//  SanJoseParkingGarages
//
//  Created by Lisa Litchfield on 4/27/17.
//  Copyright © 2017 Lisa Litchfield. All rights reserved.
//

import UIKit
import MapKit



class GarageViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, MKMapViewDelegate {
    let garages = ["garage 1", "garage 2", "garage 3"]
    let spaces = [25,35,45]
    let capacities = [30,100,150]
    

    @IBOutlet weak var mapView: MKMapView!
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
// MARK: TableView Delegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        return
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell{
        let cell = tableView.dequeueReusableCell(withIdentifier: "GarageTableCell", for: indexPath) as! GarageTableCell
        cell.nameLabel?.text = garages[indexPath.row]
        cell.spacesLabel?.text = "\(spaces[indexPath.row])"
        cell.capacityLabel?.text = "\(capacities[indexPath.row])"
        
        return cell
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return garages.count
    }
    


}



