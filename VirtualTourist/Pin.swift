//
//  Pin.swift
//  VirtualTourist
//
//  Created by Steve Proell on 8/23/15.
//  Copyright (c) 2015 Steve Proell. All rights reserved.
//

import CoreData

@objc(Pin)

class Pin : NSManagedObject {
    
    @NSManaged var latitude: Double
    @NSManaged var longitude: Double
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(lat: Double, long: Double, context: NSManagedObjectContext) {
        
        // Core Data
        let entity =  NSEntityDescription.entityForName("Pin", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        latitude = lat
        longitude = long
    }
}




