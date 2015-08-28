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
    
    var pins: [Pin]!
    let infoLabelHeight: CGFloat = 60
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let lpgr = UILongPressGestureRecognizer(target: self, action: "longTapMap:")
        lpgr.minimumPressDuration = 1.0
        mapView.addGestureRecognizer(lpgr)
        
        self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        createInfoLabel()
        
        pins = fetchAllPins()
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
        for pin in pins {
            println("adding a pin")
            addPinToMap(CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude))
        }
    }

    func longTapMap(sender: UIGestureRecognizer) {
        println("long tap:")
     
        // Only add pins when we begin the log tap
        if sender.state != UIGestureRecognizerState.Began { return }
        let touchLocation = sender.locationInView(mapView)
        let locationCoordinate = mapView.convertPoint(touchLocation, toCoordinateFromView: mapView)
        addPinToMap(locationCoordinate)
        
        pins.append(Pin(lat: locationCoordinate.latitude, long: locationCoordinate.longitude, context: sharedContext))
        
        CoreDataStackManager.sharedInstance().saveContext()
        
        println("Tapped at lat: \(locationCoordinate.latitude) long: \(locationCoordinate.longitude)")
    }
    
    func addPinToMap(coordinate: CLLocationCoordinate2D) {
        var annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        println("adding: \(coordinate.latitude) long: \(coordinate.longitude)")

        
        dispatch_async(dispatch_get_main_queue(), {
            self.mapView.addAnnotation(annotation)
        })
    }
    
    func mapView(mapView: MKMapView!, didSelectAnnotationView view: MKAnnotationView!) {
        println("tapped pin")
        
        // TODO: how to find pin in array?
        
        if editing {
            // remove pin
            
            // remove from array
            
            // remove from context
            // sharedContext.deleteObject()
            CoreDataStackManager.sharedInstance().saveContext()
            
        } else {
            // segue to photo view controller
            
            // set pin on view controller
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

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
