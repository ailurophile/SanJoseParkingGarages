//
//  GarageViewController.swift
//  SanJoseParkingGarages
//
//  Created by Lisa Litchfield on 4/27/17.
//  Copyright © 2017 Lisa Litchfield. All rights reserved.
//

import UIKit
import MapKit
//import CoreData



class GarageViewController: UIViewController, UITableViewDelegate, MKMapViewDelegate, NewPinsDelegate {

    var annotations = [MKAnnotation]()
//    var numberOfPinsOnMap = 0

    var desiredLocation: CLLocationCoordinate2D!
    var destinationName = Constants.DefaultGarageName
    var secondEntranceCoordinates:CLLocationCoordinate2D? = nil

    

    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var refreshButton: UIBarButtonItem!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var mapView: MKMapView!
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        tableView.delegate = GarageModel.sharedInstance() as? UITableViewDelegate
        GarageModel.sharedInstance().pinDelegate = self
        mapView.centerCoordinate = CLLocationCoordinate2DMake(Constants.MapCenterLatitude, Constants.MapCenterLongitude)
        let center = CLLocationCoordinate2DMake(Constants.MapCenterLatitude, Constants.MapCenterLongitude)
        let span = MKCoordinateSpan(latitudeDelta: Constants.LatDelta, longitudeDelta: Constants.LonDelta)
        let region = MKCoordinateRegionMake(center, span)
        mapView.setRegion(region, animated: true)
        //Load garage data from Core Data
        GarageModel.sharedInstance().loadGarages()
        //Load Pins and add to map
        GarageModel.sharedInstance().loadPins()
        //Get latest available data
        refreshParkingData()
        //Register for notifications
        NotificationCenter.default.addObserver(self, selector: #selector(refreshParkingData), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reloadTable), name: NSNotification.Name(rawValue:Constants.newGarageDataNotificationKey), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(enableUI), name: NSNotification.Name(rawValue:Constants.networkRequestCompletedNotificationKey), object: nil)

    }
    //MARK: NewPinsDelegate
    func addNewPins( shouldAddPins pins: [Pin]){
        for pin in pins{
            print("pin at coordinates: \(pin.latitude),\(pin.longitude)")
            //Create map annotation for display
            let annotation = MKPointAnnotation()
            annotation.coordinate.latitude = pin.latitude
            annotation.coordinate.longitude = pin.longitude
            annotation.title = pin.garage?.name
            self.annotations.append(annotation)
        }
        addAnnotationsToMap()
    }
    func clearPins() {
        self.mapView.removeAnnotations(self.annotations) //remove old pins from map
        self.annotations.removeAll()
    }

    @IBAction func RefreshButtonSelected(_ sender: Any) {
        refreshParkingData()
    }
    func refreshParkingData(){
        activityIndicator.startAnimating()
        refreshButton.isEnabled = false
        GarageModel.sharedInstance().getParkingData(self)
        
    }
    func enableUI(){
        activityIndicator.stopAnimating()
        refreshButton.isEnabled = true
    }
    func reloadTable(){
        tableView.reloadData()
    }

    

    
// MARK: TableView Delegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
                guard let pin = GarageModel.sharedInstance().garageObjects[indexPath.row].pin else{
            sendAlert(self, message: "No location data for this garage")
            return
        }
        let coordinates = CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
        let name = GarageModel.sharedInstance().garageObjects[indexPath.row].name
        if pin.latitude2 != PinProperties.NoCoordinate {
            
            let altCoordinates = CLLocationCoordinate2D(latitude: pin.latitude2, longitude: pin.longitude2)
            showSelectedGarage(coordinates: coordinates, title: name, secondEntrance: altCoordinates)
        }
        else{
            showSelectedGarage(coordinates: coordinates, title: name, secondEntrance: nil)
        }
        
        return
    }
 //MARK: Map methods
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
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
    

    
    // Show garage name if pin is tapped
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if control == view.rightCalloutAccessoryView {
            
            //TBD present view controller with button to go to maps for directions
            let coordinates = view.annotation?.coordinate
            let pin = GarageModel.sharedInstance().getPin(for: coordinates!)!
            let name = pin.garage?.name
            if pin.latitude2 != PinProperties.NoCoordinate {
                
                let altCoordinates = CLLocationCoordinate2D(latitude: pin.latitude2, longitude: pin.longitude2)
                showSelectedGarage(coordinates: coordinates!, title: name, secondEntrance: altCoordinates)
            }
            else{
                showSelectedGarage(coordinates: coordinates!, title: name, secondEntrance: nil)
            }

        }
    }
    



    private func addAnnotationsToMap(){
        

        mapView.removeAnnotations(mapView.annotations)
//        numberOfPinsOnMap = annotations.count
        mapView.addAnnotations(annotations)
    }
    


//MARK: navigation methods
    func showSelectedGarage(coordinates: CLLocationCoordinate2D, title: String?, secondEntrance: CLLocationCoordinate2D?){
        desiredLocation = coordinates
        if let name = title {
            destinationName = name
        }
        else {
            destinationName = Constants.DefaultGarageName
        }
        secondEntranceCoordinates = secondEntrance
        performSegue(withIdentifier: "directions", sender: self)
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "directions" {
            let nextController = segue.destination as! DirectionsViewController
            nextController.targetGarage = desiredLocation
            nextController.garageName = destinationName
            nextController.secondEntrance = secondEntranceCoordinates
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}



