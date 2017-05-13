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


class DirectionsViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate{
    var targetGarage: CLLocationCoordinate2D!
    var garageName = Constants.DefaultGarageName
    let locationManager = CLLocationManager()
    let launchOptions = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
    var firstLocation = true
    @IBOutlet weak var mapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        if CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
            mapView.showsUserLocation = true
        } else {
            locationManager.requestWhenInUseAuthorization()
        }
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        mapView.centerCoordinate = targetGarage

        //show garage and user if location services enabled
        let annotation = MKPointAnnotation()
        annotation.coordinate = targetGarage
        annotation.title = garageName
        setDefaultSpan()
        mapView.addAnnotation(annotation)
    }

    //MARK: Map methods
/*    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = true
            pinView!.pinTintColor = .purple
            pinView!.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        }
        else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }
 */

    func mapView(_ mapView: MKMapView, didFailToLocateUserWithError error: Error) {
        sendAlert(self, message: "Unable to find current location!")
    }
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        let myLocation = MKPointAnnotation()
        myLocation.coordinate = userLocation.coordinate
        mapView.addAnnotation(myLocation)
        //modify span to encompass user location the first time it is found
        if firstLocation{
            let latitudeDelta = abs(userLocation.coordinate.latitude - targetGarage.latitude)*2.0
            let longitudeDelta = abs(userLocation.coordinate.longitude - targetGarage.longitude)*2.0
            let midpointLatitude = (userLocation.coordinate.latitude + targetGarage.latitude)/2.0
            let midpointLongitude = (userLocation.coordinate.longitude + targetGarage.longitude)/2.0
            let center = CLLocationCoordinate2D(latitude: midpointLatitude, longitude: midpointLongitude)
            let span = MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
            let region = MKCoordinateRegionMake(center, span)
            mapView.setRegion(region, animated: true)
            firstLocation = false

        }
    }
    //MARK: Location Manager delegate methods
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        sendAlert(self, message: "Location Manager unsuccessful")
    }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let myLocation = locations[0]
        let myCoordinates = CLLocationCoordinate2D(latitude: myLocation.coordinate.latitude, longitude: myLocation.coordinate.longitude)
        let myAnnotation = MKPointAnnotation()
        myAnnotation.coordinate = myCoordinates
        mapView.addAnnotation(myAnnotation)
    }
    func setDefaultSpan(){
        let span = MKCoordinateSpan(latitudeDelta: Constants.LatDelta, longitudeDelta: Constants.LonDelta)
        let region = MKCoordinateRegionMake(targetGarage, span)
        mapView.setRegion(region, animated: true)
    }
    @IBAction func updateLocationButtonSelected(_ sender: Any) {
        if CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
            locationManager.requestLocation()
        }
    }
    @IBAction func getDirections(_ sender: Any) {

        let placemark = MKPlacemark(coordinate: targetGarage)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = garageName
        mapItem.openInMaps(launchOptions: launchOptions)
    }
}
