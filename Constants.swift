//
//  Constants.swift
//  SanJoseParkingGarages
//
//  Created by Lisa Litchfield on 5/6/17.
//  Copyright © 2017 Lisa Litchfield. All rights reserved.
//

import Foundation

struct PinProperties {
    static let Lat = "latitude"
    static let Lon = "longitude"

}
struct Constants {
    static let SmallScreenHeight = 500.0
    static let ParkingDataExpiration = 1800.0 //30 minutes to stale
    static let MapDataExpiration = 86400.0 //24 hours to stale
    static let City = "San Jose, CA"
    static let MapCenterLatitude = 37.326758739542825
    static let MapCenterLongitude = -121.84566744830443
    static let LatDelta = 0.07098181195248543
    static let LonDelta = 0.25749208904997545
}

struct GarageProperties {
    static let Name = "name"
    static let Open = "open"
    static let Spaces = "spaces"
    static let Capacity = "capacity"
    static let Timestamp = "timestamp"
    static let Pin = "pin"
}
//["Garage_Name","Garage_Status","Available_Visitor_Spaces","Total_Visitor_Spaces"]
struct Index {
    static let Name = 0
    static let Open = 1
    static let Spaces = 2
    static let Capacity = 3
}

struct Status {
    static let Open = "Open"
}