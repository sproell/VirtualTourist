//
//  MapViewController.swift
//  VirtualTourist
//
//  Created by Steve Proell on 8/23/15.
//  Copyright (c) 2015 Steve Proell. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class MapViewController: UIViewController, MKMapViewDelegate {

    @IBOutlet weak var mapView: MKMapView!
    let infoLabelHeight: CGFloat = 60
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let lpgr = UILongPressGestureRecognizer(target: self, action: "longTapMap:")
        lpgr.minimumPressDuration = 1.0
        mapView.addGestureRecognizer(lpgr)
        
        self.navigationItem.rightBarButtonItem = self.editButtonItem()
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "Ok", style: UIBarButtonItemStyle.Plain, target: nil, action: nil)
        createInfoLabel()
        
        addPinsToMap()
    }
    
    // Create view that informs user how to delete pins
    func createInfoLabel() {
        
        // Get boundaries for label
        let infoLabelWidth: CGFloat = view.bounds.width
        let viewBottom: CGFloat = view.bounds.height
        let infoLabelFrame: CGRect = CGRectMake(0, viewBottom, infoLabelWidth, infoLabelHeight)
        
        // Create the label
        var label = UILabel(frame: infoLabelFrame)
        label.textColor = UIColor.whiteColor()
        label.backgroundColor = UIColor.redColor()
        label.font = UIFont(name: "Verdana", size: 12)
        label.textAlignment = NSTextAlignment.Center
        label.text = "Tap Pins to Delete"

        self.view.addSubview(label)
    }
    
    lazy var sharedContext: NSManagedObjectContext = {
        return CoreDataStackManager.sharedInstance().managedObjectContext!
    }()
    
    func fetchAllPins() -> [Pin] {
        var error: NSError?
        
        // Create the Fetch Request
        let fetchRequest = NSFetchRequest(entityName: "Pin")
        
        // Execute the Fetch Request
        let results = sharedContext.executeFetchRequest(fetchRequest, error: &error)
        
        // Check for Errors
        if let error = error {
            println("Error in fetchAllPins(): \(error)")
        }
        
        // Return the results, cast to an array of Pin objects
        return results as! [Pin]
    }
    
    func addPinsToMap() {
        let pins = fetchAllPins()
        
        for pin in pins {
            println("adding a pin from storage")
            addPinToMap(pin)
        }
    }

    func longTapMap(sender: UIGestureRecognizer) {
        println("long tap:")
        
        // Only add pins when we begin the log tap
        if sender.state != UIGestureRecognizerState.Began { return }
        let touchLocation = sender.locationInView(mapView)
        let locationCoordinate = mapView.convertPoint(touchLocation, toCoordinateFromView: mapView)
        println("Tapped at lat: \(locationCoordinate.latitude) long: \(locationCoordinate.longitude)")
        
        println("adding a new pin")
        addPinToMap(Pin(lat: locationCoordinate.latitude, long: locationCoordinate.longitude, context: sharedContext))
        
        CoreDataStackManager.sharedInstance().saveContext()
    }
    
    func addPinToMap(pin: Pin) {
        dispatch_async(dispatch_get_main_queue(), {
            self.mapView.addAnnotation(pin)
        })
    }
    
    func mapView(mapView: MKMapView!, didSelectAnnotationView view: MKAnnotationView!) {
        println("tapped pin")
        
        // get annotation from view
        let pin = view.annotation as! Pin
        
        if editing {
            
            println("removing pin")
            
            // remove pin from map
            self.mapView.removeAnnotation(pin)
            
            // remove from context
            sharedContext.deleteObject(pin)
            CoreDataStackManager.sharedInstance().saveContext()
            
        } else {

            // segue to photo view controller
            let controller = storyboard!.instantiateViewControllerWithIdentifier("PhotoViewController") as! PhotoViewController
            controller.pin = pin
            
            self.navigationController!.pushViewController(controller, animated: true)
        }
    }
    
    override func setEditing(editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        println("editing: \(editing)")
        
        if editing {
            UIView.animateWithDuration(0.3, animations: { self.view.frame.origin.y -= self.infoLabelHeight }, completion: nil)
        } else {
            UIView.animateWithDuration(0.3, animations: { self.view.frame.origin.y += self.infoLabelHeight }, completion: nil)
        }
    }
}
