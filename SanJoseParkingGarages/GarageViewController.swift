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
    var destinationName = Constants.DefaultGarageName
    var altCoordinates:CLLocationCoordinate2D? = nil

    let KnownGarages = [
        "Convention Center Garage": [[Keys.Latitude: 37.3296, Keys.Longitude: -121.8870],
                                     [Keys.Latitude: 37.3278, Keys.Longitude: -121.8908]],
        "Fourth Street Garage": [[Keys.Latitude: 37.33667, Keys.Longitude: -121.886645],
                                 [Keys.Latitude: 37.3361, Keys.Longitude: -121.8856]],
        "Second San Carlos Garage": [[Keys.Latitude: 37.3330, Keys.Longitude: -121.8865],
                                     [Keys.Latitude: 37.3332, Keys.Longitude: -121.885]],
        "Third Street Garage": [[Keys.Latitude: 37.33780, Keys.Longitude: -121.8950256],
                                [Keys.Latitude: 37.337666, Keys.Longitude: -121.890141]],
        "City Hall Garage": [[Keys.Latitude: 37.3379, Keys.Longitude: -121.8846]],
        "Market San Pedro Square Garage": [[Keys.Latitude: 37.3360, Keys.Longitude: -121.8923 ],
                                           [Keys.Latitude: 37.3359, Keys.Longitude: -121.8934]]

    ] as [String : [[String:Double]]]
    //
    //        "Fourth Street Garage": [Keys.Latitude: 37.3363783, Keys.Longitude: -121.8881668],
    //"Second San Carlos Garage": [Keys.Latitude: 37.3325201, Keys.Longitude: -121.8879675] on San Carlos street

    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var refreshButton: UIBarButtonItem!
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
        //Register for notifications
        NotificationCenter.default.addObserver(self, selector: #selector(getParkingData), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)


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
        refreshButton.isEnabled = false
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
//                garageArrays.removeFirst()  //remove garage so it will look like a garage has been sold
//                garageArrays.removeFirst()  //remove garage so it will look like a garage has been sold
//                garageArrays[3][Index.Open] = Constants.ClosedIndicator // test a garage being closed
                DispatchQueue.main.async {
                //check if more garages in Core Data than returned from API
                if self.garageObjects.count > garageArrays.count {
                    print("old garages hanging around!  clearing out database")
                    
                    //Clear all objects from Core Data
                    for object in self.garageObjects{
                        context.delete(object as NSManagedObject)
                    }
                    delegate.saveContext()

                    //clear all objects from local memory
                    self.garageObjects.removeAll()
                    self.storedPins.removeAll()
                    self.mapView.removeAnnotations(self.annotations) //remove old pins from map
                    self.annotations.removeAll()
                    self.numberOfPinsOnMap = 0
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
                        
                        let newGarage = Garage(entity: Garage.entity(), insertInto: context)

                        newGarage.name = garage[Index.Name]
                        newGarage.open = open
                        newGarage.spaces = garage[Index.Spaces]
                        newGarage.capacity = garage[Index.Capacity]
                        newGarage.timestamp = self.time
                        self.garageObjects.append(newGarage)
                        self.findLocation(garage: newGarage)

                            
                     }
                }

                self.tableView.reloadData() // show latest data on table
                delegate.saveContext()
                self.refreshButton.isEnabled = true

                }
                
            }
                
            else {
                notifyUser(self, message: "No results key found in garage data!")
                self.refreshButton.isEnabled = true
 
            }

        })
        
    }
    
    func findLocation(garage: Garage){
        
        if KnownGarages.keys.contains(garage.name!){
            print("found garage named: \(garage.name)")
            let garageEntrances = KnownGarages[garage.name!] //array of entrance coordinates
            print("Garage entrances: \(garageEntrances)")
            let coordinates = garageEntrances![0]  //Use first entrance for Pin location
            let coordinate = CLLocationCoordinate2D(latitude: (coordinates[Keys.Latitude])!, longitude: (coordinates[Keys.Longitude])!)
            if (garageEntrances?.count)! > 1{
                let altCoordinates = garageEntrances?[1]
                let altCoordinate = CLLocationCoordinate2D(latitude: (altCoordinates?[Keys.Latitude])!, longitude: (altCoordinates?[Keys.Longitude])!)
                createPin(relatedTo: garage, at: coordinate, alternate: altCoordinate)
            }
            else{
                createPin(relatedTo: garage, at: coordinate, alternate: nil)
            }
        }
        else{
        //Forward Geocode garage location
            print("searching for garage location of : \(garage.name)")
            let request = MKLocalSearchRequest()
            request.naturalLanguageQuery = garage.name! + Constants.City
            let search = MKLocalSearch(request: request)
            search.start(completionHandler: {(response, error) in
                //Use first location returned, if any
                guard let mapItem = response?.mapItems[0] else{
                    
                    sendAlert(self, message: "Location not found!")
                    return
                }
                let coordinate = mapItem.placemark.coordinate
                self.createPin(relatedTo: garage, at: coordinate, alternate: nil)
            })
 
        }
        
    }
    func createPin(relatedTo garage:Garage, at coordinate:CLLocationCoordinate2D, alternate: CLLocationCoordinate2D?){
        DispatchQueue.main.async {
            //Get the persistent container
            let delegate = UIApplication.shared.delegate as! AppDelegate
            let context = delegate.persistentContainer.viewContext
            //Create Pin for garage location
            let newPin = Pin(entity: Pin.entity(), insertInto: context)
            newPin.garage = garage
            newPin.latitude = coordinate.latitude
            newPin.longitude = coordinate.longitude
            if let alternate = alternate{  //store coordinates of 2nd entrance if it exists
                newPin.latitude2 = alternate.latitude
                newPin.longitude2 = alternate.longitude
            }
            self.storedPins.append(newPin)
            print("garage at longitude: \(newPin.longitude) latitude \(newPin.latitude)")
            //Create map annotation for display
            let annotation = MKPointAnnotation()
            annotation.coordinate.latitude = newPin.latitude
            annotation.coordinate.longitude = newPin.longitude
            annotation.title = garage.name
            self.annotations.append(annotation)
            self.mapView.addAnnotation(annotation)
            self.mapView.reloadInputViews()
            self.numberOfPinsOnMap += 1
            print("number of pins on map: \(self.numberOfPinsOnMap)")
            delegate.saveContext()
        }
    }
    

    
// MARK: TableView Delegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
                guard let pin = garageObjects[indexPath.row].pin else{
            sendAlert(self, message: "No location data for this garage")
            return
        }
        let coordinates = CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
        if pin.latitude2 != nil && pin.longitude2 != nil {
            altCoordinates = CLLocationCoordinate2D(latitude: pin.latitude2, longitude: pin.longitude2)
        }
        let name = garageObjects[indexPath.row].name
        showSelectedGarage(coordinates: coordinates, title: name, secondEntrance: altCoordinates)
        return
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell{
        let cell = tableView.dequeueReusableCell(withIdentifier: "GarageTableCell", for: indexPath) as! GarageTableCell
        //Leave the word "Garage" off of name if device has small screen
        if UIScreen.main.bounds.size.width < CGFloat(Constants.SmallScreenWidth){
            cell.nameLabel?.text = garageObjects[indexPath.row].name?.replacingOccurrences(of: "Garage", with: "")
        }
        else {
            cell.nameLabel?.text = garageObjects[indexPath.row].name
        }
//        cell.nameLabel?.text = garageObjects[indexPath.row].name
        cell.spacesLabel?.text = garageObjects[indexPath.row].open ? garageObjects[indexPath.row].spaces:"closed"
        if isStale(timestamp: garageObjects[indexPath.row].timestamp!){
            cell.spacesLabel?.text = Constants.StaleData
        }
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
            let name = getPin(for: coordinates!)?.garage?.name
            showSelectedGarage(coordinates: coordinates!, title: name, secondEntrance: nil)
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
/*    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        let center = mapView.centerCoordinate
        let span = mapView.region.span
        let region = mapView.region
        print("map center: \(center) span: \(span) region: \(region)")
    }*/
//MARK: navigation methods
    func showSelectedGarage(coordinates: CLLocationCoordinate2D, title: String?, secondEntrance: CLLocationCoordinate2D?){
        desiredLocation = coordinates
        if let name = title {
            destinationName = name
        }
        else {
            destinationName = Constants.DefaultGarageName
        }
        performSegue(withIdentifier: "directions", sender: self)
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "directions" {
            let nextController = segue.destination as! DirectionsViewController
            nextController.targetGarage = desiredLocation
            nextController.garageName = destinationName
            nextController.secondEntrance = altCoordinates
        }
    }
//MARK: Core Data methods
    func getPin(for coordinate: CLLocationCoordinate2D) -> Pin? {
        for pin in storedPins {
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
    //Must be call from main
    private func loadGarages(){
        //Get the persistent container
        let delegate = UIApplication.shared.delegate as! AppDelegate
        //Create fetch request
        let fetchRequest = NSFetchRequest<Garage>(entityName: "Garage")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: GarageProperties.Name, ascending: true)]
        do {
            let results = try delegate.persistentContainer.viewContext.fetch(fetchRequest)
            garageObjects = results
            print("Number of garages loaded = \(results.count)")
        } catch let error as NSError {
            print("Could not fetch Garages. \(error), \(error.userInfo)")
        }
    }
    // Load Pins from Core Data and display on map (must be called from main)
    private func loadPins(){
        //Get the persistent container
        let delegate = UIApplication.shared.delegate as! AppDelegate
        //Create fetch request
        let fetchRequest = NSFetchRequest<Pin>(entityName: "Pin")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: PinProperties.Lat, ascending: true),NSSortDescriptor(key: PinProperties.Lon, ascending: true)]
        do {
            let results = try delegate.persistentContainer.viewContext.fetch(fetchRequest) 
            for pin in results{
//             print("pin at coordinates: \(pin.latitude),\(pin.longitude)")
                //Create map annotation for display
                let annotation = MKPointAnnotation()
                annotation.coordinate.latitude = pin.latitude
                annotation.coordinate.longitude = pin.longitude
                annotation.title = pin.garage?.name
                self.annotations.append(annotation)
             }
            storedPins = results
            print("Number of pins loaded = \(results.count)")
        } catch let error as NSError {
            print("Could not fetch Pins. \(error), \(error.userInfo)")
        }
        addAnnotationsToMap()
        
        
    }
    //Check if data too old to be useful to display in table
    func isStale(timestamp: NSDate)->Bool{
//        print("timeIntervalSinceNow = \(timestamp.timeIntervalSinceNow)")
        if timestamp.timeIntervalSinceNow < Constants.ParkingDataExpiration { //negative values hence the less than sign
            return true
        }
        return false
    }
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}



