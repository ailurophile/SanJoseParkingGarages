//
//  GarageModel.swift
//  SanJoseParkingGarages
//
//  Created by Lisa Litchfield on 7/19/17.
//  Copyright © 2017 Lisa Litchfield. All rights reserved.
//

import Foundation
import UIKit
import CoreData
import MapKit

protocol NewPins {
//    var pins: [Pin] {get set}
}

protocol NewPinsDelegate {
    func addNewPins( shouldAddPins pins: [Pin])
    func clearPins()
}


class GarageModel:NSObject, UITableViewDataSource, NewPins{
    var garageObjects :[Garage]!
    var storedPins:[Pin]!
    var pinDelegate: NewPinsDelegate?
    var time:NSDate!
    //Coordinates of entrances to known garages
    static let KnownGarages = [
        "Convention Center Garage": [[Keys.Latitude: 37.3296, Keys.Longitude: -121.8870],
                                     [Keys.Latitude: 37.328196, Keys.Longitude: -121.890135]],
        "Fourth Street Garage": [[Keys.Latitude: 37.33667, Keys.Longitude: -121.886645],
                                 [Keys.Latitude: 37.3361, Keys.Longitude: -121.8856]],
        "Second San Carlos Garage": [[Keys.Latitude: 37.3325, Keys.Longitude: -121.8862],
                                     [Keys.Latitude: 37.3329, Keys.Longitude: -121.8854]],
        "Third Street Garage": [[Keys.Latitude: 37.338072, Keys.Longitude: -121.889262],
                                [Keys.Latitude: 37.3374, Keys.Longitude: -121.890]],
        "City Hall Garage": [[Keys.Latitude: 37.3379, Keys.Longitude: -121.8848]],
        "Market San Pedro Square Garage": [[Keys.Latitude: 37.33595, Keys.Longitude: -121.8928 ],
                                           [Keys.Latitude: 37.3359, Keys.Longitude: -121.8934]]
        
        ] as [String : [[String:Double]]]
    
    //MARK: Core Data methods
    
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
            else{
                newPin.latitude2 = PinProperties.NoCoordinate
                newPin.longitude2 = PinProperties.NoCoordinate
            }
            self.storedPins.append(newPin)
            self.pinDelegate?.addNewPins(shouldAddPins: [newPin])
            //            print("garage at longitude: \(newPin.longitude) latitude \(newPin.latitude)")

            delegate.saveContext()
        }
    }
    
    func getGarage(for name: String)-> Garage?{
        for garage in garageObjects{
            if (name.contains(garage.name!)) {  //handle case of shortened name for small screens
                return garage
            }
        }
        return nil  //no garage by that name in Core Data
    }
    
    func getPin(for coordinate: CLLocationCoordinate2D) -> Pin? {
        for pin in storedPins {
            if pin.latitude == coordinate.latitude && pin.longitude == coordinate.longitude{
                return pin
            }
        }
        return nil //no Pin exist for garage
        
    }
    //Must be call from main
    func loadGarages(){
        //Get the persistent container
        let delegate = UIApplication.shared.delegate as! AppDelegate
        //Create fetch request
        let fetchRequest = NSFetchRequest<Garage>(entityName: "Garage")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: GarageProperties.Name, ascending: true)]
        do {
            let results = try delegate.persistentContainer.viewContext.fetch(fetchRequest)
            garageObjects = results
        } catch let error as NSError {
            print("Could not fetch Garages. \(error), \(error.userInfo)")
        }
    }
    // Load Pins from Core Data and display on map (must be called from main)
    func loadPins(){
        //Get the persistent container
        let delegate = UIApplication.shared.delegate as! AppDelegate
        //Create fetch request
        let fetchRequest = NSFetchRequest<Pin>(entityName: "Pin")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: PinProperties.Lat, ascending: true),NSSortDescriptor(key: PinProperties.Lon, ascending: true)]
        do {
            let results = try delegate.persistentContainer.viewContext.fetch(fetchRequest)
            var pins:[Pin]=[]
            for pin in results{
                //             print("pin at coordinates: \(pin.latitude),\(pin.longitude)")
                //Create map annotation for display
                pins.append(pin)
            }
            storedPins = results
            pinDelegate?.addNewPins(shouldAddPins: pins)
        } catch let error as NSError {
            print("Could not fetch Pins. \(error), \(error.userInfo)")
        }
        
    }
//MARK: Model functions
    func getParkingData(_ viewController: UIViewController){
        //Animate Activity Indicator and disable refresh button
                JunarClient.sharedInstance().queryJunar(completionHandlerForQuery: {(results, error) in
            //Update UI
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.networkRequestCompletedNotificationKey), object: self)

                
            }
            guard error == nil else{
                print(error?.localizedDescription ?? "?? no localized description to print")
                notifyUser(viewController, message: "Error: \(error!.localizedDescription)")
                
                
                return
            }
            //Load garage dictionary
            guard let data = results as! [String: Any]? else{
                notifyUser(viewController, message: "No garage data!")
                return
            }
            //["Garage_Name","Garage_Status","Available_Visitor_Spaces","Total_Visitor_Spaces"]
            if var garageArrays = data[JunarClient.ParameterKeys.GarageKey] as! [[String]]?{
                //Get the persistent container
                let delegate = UIApplication.shared.delegate as! AppDelegate
                let context = delegate.persistentContainer.viewContext
                garageArrays.removeFirst()  //remove column headings for web page
                //                garageArrays.removeFirst()  //remove garage so it will look like a garage has been sold
                //                garageArrays[3][Index.Open] = Constants.ClosedIndicator // test a garage being closed
                DispatchQueue.main.async {
                    //check if more garages in Core Data than returned from API
                    if GarageModel.sharedInstance().garageObjects.count > garageArrays.count {
                        //                    print("old garages hanging around!  clearing out database")
                        
                        //Clear all objects from Core Data
                        for object in self.garageObjects{
                            context.delete(object as NSManagedObject)
                        }
                        delegate.saveContext()
                        
                        //clear all objects from local memory
                        self.garageObjects.removeAll()
                        self.storedPins.removeAll()

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
                    NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.newGarageDataNotificationKey), object: self)
                    delegate.saveContext()
                    
                }
                
            }
                
            else {
                notifyUser(viewController, message: "No results key found in garage data!")
                
            }
            
        })
        
    }
    
    func findLocation(garage: Garage){
        
        if GarageModel.KnownGarages.keys.contains(garage.name!){
            let garageEntrances = GarageModel.KnownGarages[garage.name!] //array of entrance coordinates
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
            //            print("searching for garage location of : \(garage.name)")
            let request = MKLocalSearchRequest()
            request.naturalLanguageQuery = garage.name! + Constants.City
            let search = MKLocalSearch(request: request)
            search.start(completionHandler: {(response, error) in
                //Use first location returned, if any
                guard let mapItem = response?.mapItems[0] else{
                    
                    print("Location not found!")
                    return
                }
                let coordinate = mapItem.placemark.coordinate
                self.createPin(relatedTo: garage, at: coordinate, alternate: nil)
            })
            
        }
        
    }
    
    //MARK: TableView DataSource
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell{
        let cell = tableView.dequeueReusableCell(withIdentifier: "GarageTableCell", for: indexPath) as! GarageTableCell
        //Leave the word "Garage" off of name if device has small screen and the name is long
        let nameLength = garageObjects[indexPath.row].name?.characters.count
        if UIScreen.main.bounds.size.width < CGFloat(Constants.SmallScreenWidth) && nameLength ?? 0 > Constants.LongestName{
            cell.nameLabel?.text = garageObjects[indexPath.row].name?.replacingOccurrences(of: "Garage", with: "")
        }
            
        else {
            cell.nameLabel?.text = garageObjects[indexPath.row].name
        }
        cell.spacesLabel?.text = garageObjects[indexPath.row].open ? garageObjects[indexPath.row].spaces:"closed"
        if isStale(timestamp: garageObjects[indexPath.row].timestamp!){
            cell.spacesLabel?.text = Constants.StaleData
        }
        //        cell.capacityLabel?.text = garageObjects[indexPath.row].capacity
        
        return cell
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return garageObjects.count
    }
    
    //Check if data too old to be useful to display in table
    func isStale(timestamp: NSDate)->Bool{
        if timestamp.timeIntervalSinceNow < Constants.ParkingDataExpiration { //negative values hence the less than sign
            return true
        }
        return false
    }
    // MARK: Shared Instance
    
    class func sharedInstance() -> GarageModel {
        struct Singleton {
            static var sharedInstance = GarageModel()
        }
        return Singleton.sharedInstance
    }

}
