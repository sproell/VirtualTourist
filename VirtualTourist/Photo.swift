//
//  Photo.swift
//  VirtualTourist
//
//  Created by Steve Proell on 8/29/15.
//  Copyright (c) 2015 Steve Proell. All rights reserved.
//

import Foundation
import CoreData
import UIKit

@objc(Photo)

class Photo : NSManagedObject {
    
    @NSManaged var imagePath: String?
    @NSManaged var pin: Pin?
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(imagePath: String, context: NSManagedObjectContext) {
        
        // Core Data
        let entity =  NSEntityDescription.entityForName("Photo", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.imagePath = imagePath
    }
    
    convenience init(dictionary: [String : AnyObject], context: NSManagedObjectContext) {
        self.init(imagePath: dictionary["url_m"] as! String, context: context)
    }
    
    var image: UIImage? {
        
        // Use the filename of the image as the cache identifier!
        // Identifiers with slashes in the name cannot be found!
        
        get {
            return FlickrClient.Caches.imageCache.imageWithIdentifier(fileName()!)
        }
        
        set {
            FlickrClient.Caches.imageCache.storeImage(newValue, withIdentifier: fileName()!)
        }
    }

    func fileName() -> String? {
        let url = NSURL(fileURLWithPath: imagePath!)
        return url?.lastPathComponent
    }
    
    // Called when a managed object is deleted.  This insures the 
    // associated image is deleted from the persistent storage.
    override func prepareForDeletion() {
        super.prepareForDeletion()
        image = nil
    }
}
