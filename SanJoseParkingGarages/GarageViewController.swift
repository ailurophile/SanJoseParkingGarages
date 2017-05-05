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
    var garages = ["garage 1", "garage 2", "garage 3"]
    var spaces = ["25","35","45"]
    var capacities = ["30","100","150"]
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var mapView: MKMapView!
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        getParkingData()

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func RefreshButtonSelected(_ sender: Any) {
        getParkingData()
    }
    func getParkingData(){
        //Animate Activity Indicator
        activityIndicator.startAnimating()
        JunarClient.sharedInstance().queryJunar(completionHandlerForQuery: {(results, error) in
            self.activityIndicator.stopAnimating()
            guard error == nil else{
                print(error?.localizedDescription ?? "?? no localized description to print")
                notifyUser(self, message: "Error retrieving garage data!")
               

                return
            }
            //Load garage dictionary
            guard let data = results as! [String: Any]? else{
                notifyUser(self, message: "No garage data!")
                return
            }
            if var garageArrays = data[JunarClient.ParameterKeys.GarageKey] as! [[String]]?{
                garageArrays.removeFirst()  //remove column headings for web page
                for garage in garageArrays{
                    self.garages.append(garage[0].replacingOccurrences(of: "Garage", with: ""))
                    self.spaces.append(garage[2])
                    self.capacities.append(garage[3])
                }
                print(garageArrays)
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                    
                }
            }
            else {
                notifyUser(self, message: "No results key found in garage data!")
 
            }

        })
        
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



