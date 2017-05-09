//
//  DirectionsViewController.swift
//  SanJoseParkingGarages
//
//  Created by Lisa Litchfield on 5/9/17.
//  Copyright © 2017 Lisa Litchfield. All rights reserved.
//

import Foundation
import UIKit
import  MapKit

class DirectionsViewController: UIViewController, MKMapViewDelegate{
    var targetGarage: CLLocationCoordinate2D!
    let locationManager = CLLocationManager()
    @IBOutlet weak var mapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        if CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
            mapView.showsUserLocation = true
        } else {
            locationManager.requestWhenInUseAuthorization()
        }
//        mapView.centerCoordinate = CLLocationCoordinate2DMake(targetGarage.coordinate.latitude, targetGarage.coordinate.longitude)
        let center = targetGarage 
        let span = MKCoordinateSpan(latitudeDelta: Constants.LatDelta, longitudeDelta: Constants.LonDelta)
        let region = MKCoordinateRegionMake(center!, span)
        mapView.setRegion(region, animated: true)
    }
    
    @IBAction func getDirections(_ sender: Any) {
    }
}
