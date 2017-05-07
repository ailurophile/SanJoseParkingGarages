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
    var garages = ["garage 1", "garage 2", "garage 3"]
    var spaces = ["25","35","45"]
    var capacities = ["30","100","150"]
    var time:NSDate!
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var mapView: MKMapView!
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
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
            
            guard error == nil else{
                print(error?.localizedDescription ?? "?? no localized description to print")
                notifyUser(self, message: "Error retrieving garage data!")
                DispatchQueue.main.async {
                    self.activityIndicator.stopAnimating()
                }

                return
            }
            //Load garage dictionary
            guard let data = results as! [String: Any]? else{
                notifyUser(self, message: "No garage data!")
                DispatchQueue.main.async {
                    self.activityIndicator.stopAnimating()
                    
                }
                return
            }
            //["Garage_Name","Garage_Status","Available_Visitor_Spaces","Total_Visitor_Spaces"]
            if var garageArrays = data[JunarClient.ParameterKeys.GarageKey] as! [[String]]?{
                //TBD check if more garages in Core Data than returned from API**************
                self.time = NSDate() //for use as timestamp for invalidating data
                for garage in garageArrays{
                    let open = ((garage[Index.Open]==Status.Open) ? true: false)
                    //update existing Garage object
                    if let garageObject = self.getGarage(for: garage[Index.Name]){
                        garageObject.capacity = garage[Index.Capacity]
                        garageObject.spaces = garage[Index.Spaces]
                        garageObject.open = open
                        garageObject.timestamp = self.time
                    }
                    //Create new Garage object
                        
                    else{
                        //Get the persistent container
                        let delegate = UIApplication.shared.delegate as! AppDelegate
                        let context = delegate.persistentContainer.viewContext

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
                            //Forward Geocode garage location
                            let request = MKLocalSearchRequest()
                            request.naturalLanguageQuery = garage[Index.Name] + Constants.City
                            let search = MKLocalSearch(request: request)
                            search.start(completionHandler: {(response, error) in
                                //Use first location returned, if any
                                guard let mapItem = response?.mapItems[0] else{
                                    self.activityIndicator.stopAnimating()
                                    sendAlert(self, message: "Location not found!")
                                    return
                                }
                                //Create Pin for garage location
                                let newPin = Pin(entity: Pin.entity(), insertInto: context)
                                newPin.garage = newGarage
                                newPin.latitude = mapItem.placemark.coordinate.latitude
                                newPin.longitude = mapItem.placemark.coordinate.longitude
                                print("garage at longitude: \(newPin.longitude) latitude \(newPin.latitude)")
                                //Create map annotation for display
                                let annotation = MKPointAnnotation()
                                annotation.coordinate.latitude = newPin.latitude
                                annotation.coordinate.longitude = newPin.longitude
                                self.annotations.append(annotation)
                                
                            })

                            
                            
                        }
                    }
                }
                
                
/*                self.garages.removeAll()
                self.spaces.removeAll()
                self.capacities.removeAll()
                garageArrays.removeFirst()  //remove column headings for web page
                for garage in garageArrays{
                    if UIScreen.main.bounds.size.height < CGFloat(Constants.SmallScreenHeight){
                        self.garages.append(garage[Index.Name].replacingOccurrences(of: "Garage", with: ""))
                    }
                    else {
                        self.garages.append(garage[Index.Name])
                    }
                    self.spaces.append(garage[Index.Spaces])
                    self.capacities.append(garage[Index.Capacity])
                }
                print(garageArrays)
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                    let currentTime = Date()
                    let elapsedTime = self.time.timeIntervalSinceNow
                    print("creation time: \(self.time) current time: \(currentTime) interval: \(elapsedTime)")
 
                } */
            }
            else {
                notifyUser(self, message: "No results key found in garage data!")
 
            }
            self.activityIndicator.stopAnimating()

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
 //MARK: Map methods
    private func addAnnotationsToMap(){
        
        annotations.removeAll()
        mapView.removeAnnotations(mapView.annotations)
        for pin in storedPins{
            let annotation = GarageViewController.getAnnotation(pin: pin)
            annotations.append(annotation)
            
        }
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
    

}



