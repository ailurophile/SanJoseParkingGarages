//
//  Garage+CoreDataProperties.swift
//  SanJoseParkingGarages
//
//  Created by Lisa Litchfield on 5/17/17.
//  Copyright © 2017 Lisa Litchfield. All rights reserved.
//

import Foundation
import CoreData


extension Garage {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Garage> {
        return NSFetchRequest<Garage>(entityName: "Garage")
    }

    @NSManaged public var capacity: String?
    @NSManaged public var name: String?
    @NSManaged public var open: Bool
    @NSManaged public var spaces: String?
    @NSManaged public var timestamp: NSDate?
    @NSManaged public var pin: Pin?

}
