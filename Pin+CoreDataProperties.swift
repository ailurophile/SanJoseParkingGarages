//
//  Pin+CoreDataProperties.swift
//  SanJoseParkingGarages
//
//  Created by Lisa Litchfield on 5/17/17.
//  Copyright © 2017 Lisa Litchfield. All rights reserved.
//

import Foundation
import CoreData


extension Pin {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Pin> {
        return NSFetchRequest<Pin>(entityName: "Pin")
    }

    @NSManaged public var latitude: Double
    @NSManaged public var longitude: Double
    @NSManaged public var latitude2: Double
    @NSManaged public var longitude2: Double
    @NSManaged public var garage: Garage?

}
