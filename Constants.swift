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
    static let NoCoordinate = 0.0
}
struct Constants {
    static let SmallScreenWidth = 330.0
    static let ParkingDataExpiration = -1800.0 //30 minutes to stale
    static let City = "San Jose, CA"
    static let MapCenterLatitude = 37.335522964085534
    static let MapCenterLongitude = -121.88737956485454
    static let LatDelta = 0.011057281247424555
    static let LonDelta = 0.034094146355570842
    static let StaleData = "?"  //To be displayed if stored parking data too old
    static let ClosedIndicator = "Closed"
    static let DefaultGarageName = "Garage"
    static let LongestName = 25
    static let newGarageDataNotificationKey = "LisaLitchfield.newGarageDataNotificationKey"
    static let networkRequestCompletedNotificationKey = "LisaLitchfield.networkRequestCompletedNotificationKey"

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
//User Defaults keys and dictionary keys
struct Keys {

    static let Not1stLaunch = "hasLaunchedBefore"
    static let TextViewClears = "preferredTextViewBehavior"
    static let LocationReminder = "locationReminder"
    static let Latitude = "lat"
    static let Longitude = "lon"
}
 
