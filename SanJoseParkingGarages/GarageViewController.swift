//
//  GarageViewController.swift
//  SanJoseParkingGarages
//
//  Created by Lisa Litchfield on 4/27/17.
//  Copyright © 2017 Lisa Litchfield. All rights reserved.
//

import UIKit
import MapKit
import CoreData



class GarageViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, MKMapViewDelegate {
    var garageObjects :[Garage]!
    var storedPins:[Pin]!
    var annotations = [MKAnnotation]()
    var numberOfPinsOnMap = 0
    var time:NSDate!
    var desiredLocation: CLLocationCoordinate2D!
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var mapView: MKMapView!
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        mapView.centerCoordinate = CLLocationCoordinate2DMake(Constants.MapCenterLatitude, Constants.MapCenterLongitude)
        let center = CLLocationCoordinate2DMake(Constants.MapCenterLatitude, Constants.MapCenterLongitude)
        let span = MKCoordinateSpan(latitudeDelta: Constants.LatDelta, longitudeDelta: Constants.LonDelta)
        let region = MKCoordinateRegionMake(center, span)
        mapView.setRegion(region, animated: true)
        //Load garage data from Core Data
        loadGarages()
        //Load Pins and add to map
        loadPins()
        //Get latest available data
        getParkingData()
        //update map if new pins exist
        if annotations.count > numberOfPinsOnMap{
            addAnnotationsToMap()
        }
        

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
            DispatchQueue.main.async {
                self.activityIndicator.stopAnimating()
            }
            guard error == nil else{
                print(error?.localizedDescription ?? "?? no localized description to print")
                notifyUser(self, message: "Error: \(error!.localizedDescription)")
                

                return
            }
            //Load garage dictionary
            guard let data = results as! [String: Any]? else{
                notifyUser(self, message: "No garage data!")
                
                return
            }
            //["Garage_Name","Garage_Status","Available_Visitor_Spaces","Total_Visitor_Spaces"]
            if var garageArrays = data[JunarClient.ParameterKeys.GarageKey] as! [[String]]?{
                //Get the persistent container
                let delegate = UIApplication.shared.delegate as! AppDelegate
                let context = delegate.persistentContainer.viewContext
                garageArrays.removeFirst()  //remove column headings for web page
//                garageArrays.removeLast()  //remove garage so it will look like a garage has been sold
                //check if more garages in Core Data than returned from API
                if self.garageObjects.count > garageArrays.count {
                    print("old garages hanging around!  clearing out database")
                    
                    //Clear all objects from Core Data
                    DispatchQueue.main.async {
                        for object in self.garageObjects{
                            context.delete(object as NSManagedObject)
                        }
                        do {
                            print("saving context")
                            try context.save()
                        } catch {
                            let nserror = error as NSError
                            print("Unresolved error \(nserror), \(nserror.userInfo)")
                        }

                        
                    }
                    //clear all objects from local memory
                    self.garageObjects.removeAll()
                    self.storedPins.removeAll()
//                    self.annotations.removeAll()
                }
                self.time = NSDate() //for use as timestamp for invalidating data
                
                for garage in garageArrays{
                    let open = ((garage[Index.Open]==Status.Open) ? true: false)
                    //update existing Garage object
                    if let garageObject = self.getGarage(for: garage[Index.Name]){
                        garageObject.capacity = garage[Index.Capacity]
                        garageObject.spaces = garage[Index.Spaces]
                        garageObject.open = open
                        garageObject.timestamp = self.time
                        if garageObject.pin == nil{
                            self.findLocation(garage: garageObject)
                        }
                    }
                    //Create new Garage object
                        
                    else{
                        

                        DispatchQueue.main.async {
                            let newGarage = Garage(entity: Garage.entity(), insertInto: context)
                            //Leave the word "Garage" off of name if device has small screen
                            if UIScreen.main.bounds.size.height < CGFloat(Constants.SmallScreenHeight){
                                newGarage.name = garage[Index.Name].replacingOccurrences(of: "Garage", with: "")
                            }
                            else {
                                newGarage.name = garage[Index.Name]
                            }
                            newGarage.open = open
                            newGarage.spaces = garage[Index.Spaces]
                            newGarage.capacity = garage[Index.Capacity]
                            newGarage.timestamp = self.time
                            self.garageObjects.append(newGarage)
                            
//                            self.findLocation(garage: newGarage)
                            
                            //Forward Geocode garage location
                            let request = MKLocalSearchRequest()
                            request.naturalLanguageQuery = garage[Index.Name] + Constants.City
                            let search = MKLocalSearch(request: request)
                            search.start(completionHandler: {(response, error) in
                                //Use first location returned, if any
                                guard let mapItem = response?.mapItems[0] else{
                                    
                                    sendAlert(self, message: "Location not found!")
                                    return
                                }
                                //Create Pin for garage location
                                let newPin = Pin(entity: Pin.entity(), insertInto: context)
                                newPin.garage = newGarage
                                newPin.latitude = mapItem.placemark.coordinate.latitude
                                newPin.longitude = mapItem.placemark.coordinate.longitude
                                self.storedPins.append(newPin)
                                print("garage at longitude: \(newPin.longitude) latitude \(newPin.latitude)")
                                //Create map annotation for display
                                let annotation = MKPointAnnotation()
                                annotation.coordinate.latitude = newPin.latitude
                                annotation.coordinate.longitude = newPin.longitude
                                annotation.title = newGarage.name
                                self.annotations.append(annotation)
                                self.addAnnotationsToMap()
                                do {
                                    print("saving context")
                                    try context.save()
                                } catch {
                                    let nserror = error as NSError
                                    print("Unresolved error \(nserror), \(nserror.userInfo)")
                                }

                                
                            })
                            
 
                          /*
                            if context.hasChanges{
                                do {
                                    print("saving context")
                                    try context.save()
                                } catch {
                                    let nserror = error as NSError
                                    print("Unresolved error \(nserror), \(nserror.userInfo)")
                                }
                            }

                         */
                            
                        }
                    }
                }
                DispatchQueue.main.async {
                    self.tableView.reloadData() // show latest data on table

                    if context.hasChanges{
                        do {
                            print("saving context")
                            try context.save()
                        } catch {
                            let nserror = error as NSError
                            print("Unresolved error \(nserror), \(nserror.userInfo)")
                        }
                    }
                    
                }
                
            }
                
            else {
                notifyUser(self, message: "No results key found in garage data!")
 
            }
            

        })
        
    }
    
    func findLocation(garage: Garage){
        //Get the persistent container
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let context = delegate.persistentContainer.viewContext
        //Forward Geocode garage location
        let request = MKLocalSearchRequest()
        request.naturalLanguageQuery = garage.name! + Constants.City
        let search = MKLocalSearch(request: request)
        search.start(completionHandler: {(response, error) in
            //Use first location returned, if any
            guard let mapItem = response?.mapItems[0] else{
                
                sendAlert(self, message: "Location not found!")
                return
            }
            DispatchQueue.main.async {
                //Create Pin for garage location
                let newPin = Pin(entity: Pin.entity(), insertInto: context)
                newPin.garage = garage
                newPin.latitude = mapItem.placemark.coordinate.latitude
                newPin.longitude = mapItem.placemark.coordinate.longitude
                self.storedPins.append(newPin)
                print("garage at longitude: \(newPin.longitude) latitude \(newPin.latitude)")
                //Create map annotation for display
                let annotation = MKPointAnnotation()
                annotation.coordinate.latitude = newPin.latitude
                annotation.coordinate.longitude = newPin.longitude
                annotation.title = garage.name
                self.annotations.append(annotation)
                self.addAnnotationsToMap()
                do {
                    print("saving context")
                    try context.save()
                } catch {
                    let nserror = error as NSError
                    print("Unresolved error \(nserror), \(nserror.userInfo)")
                }

            }
            
            
        })
 
    }

    
// MARK: TableView Delegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let pin = garageObjects[indexPath.row].pin else{
            sendAlert(self, message: "No location data for this garage")
            return
        }
        let coordinates = CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
        showSelectedGarage(coordinates: coordinates)
        return
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell{
        let cell = tableView.dequeueReusableCell(withIdentifier: "GarageTableCell", for: indexPath) as! GarageTableCell
        cell.nameLabel?.text = garageObjects[indexPath.row].name
        cell.spacesLabel?.text = garageObjects[indexPath.row].open ? garageObjects[indexPath.row].spaces:"closed"
        //TBD Replace with -- if stale
        cell.capacityLabel?.text = garageObjects[indexPath.row].capacity
        
        return cell
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return garageObjects.count
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
    

    
    // This delegate method is implemented to respond to taps. I
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if control == view.rightCalloutAccessoryView {
            
            //TBD present view controller with button to go to maps for directions
            let coordinates = view.annotation?.coordinate
            showSelectedGarage(coordinates: coordinates!)
        }
    }

    private func addAnnotationsToMap(){
        

        mapView.removeAnnotations(mapView.annotations)
/*        for pin in storedPins{
            let annotation = GarageViewController.getAnnotation(pin: pin)
            annotations.append(annotation)
            
        }*/
        numberOfPinsOnMap = annotations.count
        mapView.addAnnotations(annotations)
    }
    
    class func getAnnotation(pin: Pin)-> MKPointAnnotation{
        let lat = CLLocationDegrees(pin.latitude  )
        let long = CLLocationDegrees(pin.longitude )
        let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)
        //create annotation
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        return annotation
        
        
    }
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        let center = mapView.centerCoordinate
        let span = mapView.region.span
        let region = mapView.region
        print("map center: \(center) span: \(span) region: \(region)")
    }
//MARK: navigation methods
    func showSelectedGarage(coordinates: CLLocationCoordinate2D){
        desiredLocation = coordinates
        performSegue(withIdentifier: "directions", sender: self)
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "directions" {
            let nextController = segue.destination as! DirectionsViewController
            nextController.targetGarage = desiredLocation
        }
    }
//MARK: Core Data methods
    func getPin(for coordinate: CLLocationCoordinate2D) -> Pin? {
        for pin in storedPins{
            if pin.latitude == coordinate.latitude && pin.longitude == coordinate.longitude{
                return pin
            }
        }
        return nil //no Pin exist for garage
        
    }
    func getGarage(for name: String)-> Garage?{
        for garage in garageObjects{
            if (name.contains(garage.name!)) {  //handle case of shortened name for small screens
                return garage
            }
        }
        return nil  //no garage by that name in Core Data
    }
    @objc private func loadGarages(){
        //Get the persistent container
        let delegate = UIApplication.shared.delegate as! AppDelegate
        //Create fetch request
        let fetchRequest = NSFetchRequest<Garage>(entityName: "Garage")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: GarageProperties.Spaces, ascending: true)]
        do {
            let results = try delegate.persistentContainer.viewContext.fetch(fetchRequest)
            garageObjects = results
            print("Number of garages loaded = \(results.count)")
        } catch let error as NSError {
            print("Could not fetch Garages. \(error), \(error.userInfo)")
        }
    }
    // Load Pins from Core Data and display on map
    @objc private func loadPins(){
        //Get the persistent container
        let delegate = UIApplication.shared.delegate as! AppDelegate
        //Create fetch request
        let fetchRequest = NSFetchRequest<Pin>(entityName: "Pin")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: PinProperties.Lat, ascending: true),NSSortDescriptor(key: PinProperties.Lon, ascending: true)]
        do {
            let results = try delegate.persistentContainer.viewContext.fetch(fetchRequest) 
            for pin in results{
             print("pin at coordinates: \(pin.latitude),\(pin.longitude)")
                //Create map annotation for display
                let annotation = MKPointAnnotation()
                annotation.coordinate.latitude = pin.latitude
                annotation.coordinate.longitude = pin.longitude
                self.annotations.append(annotation)
             }
            storedPins = results
            print("Number of pins loaded = \(results.count)")
        } catch let error as NSError {
            print("Could not fetch Pins. \(error), \(error.userInfo)")
        }
        addAnnotationsToMap()
        
        
    }
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}



