//
//  PhotoViewController.swift
//  VirtualTourist
//
//  Created by Steve Proell on 8/28/15.
//  Copyright (c) 2015 Steve Proell. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class PhotoViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    var pin: Pin!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        dispatch_async(dispatch_get_main_queue(), {
            self.mapView.addAnnotation(self.pin)
            
            // Center and zoom on to new point
            var span = MKCoordinateSpanMake(0.1, 0.1)
            var region = MKCoordinateRegion(center: self.pin!.coordinate, span: span)
            self.mapView.setRegion(region, animated: false)
        })
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Lay out the collection view so that cells take up 1/3 of the width,
        // with no space in between.
        let layout : UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        
        let width = floor(self.collectionView.frame.size.width/3)
        layout.itemSize = CGSize(width: width, height: width)
        collectionView.collectionViewLayout = layout
    }
    
    override func viewWillAppear(animated: Bool) {
        
        if pin.photos.isEmpty {
            
            FlickrClient.sharedInstance().getPhotosForLocation(pin.coordinate.latitude, longitude: pin.coordinate.longitude) { JSONResult, error in
                
                println("vwa:loading photos")
                
                if let error = error {
                    self.alertViewForError(error)
                
                } else {
                    if let photoDictionaries = JSONResult {
                        
                        // Parse the array of photos dictionaries
                        var photos = photoDictionaries.map() { (dictionary: [String : AnyObject]) -> Photo in
                            let photo = Photo(dictionary: dictionary, context: self.sharedContext)
                            photo.pin = self.pin
                            return photo
                        }
                        
                        println("found \(photos.count) photos!")
                        
                        // Update the collection view on the main thread
                        dispatch_async(dispatch_get_main_queue()) {
                            self.collectionView.reloadData()
                        }
                        
                        // Save the context
                        CoreDataStackManager.sharedInstance().saveContext()
                        
                    } else {
                        let error = NSError(domain: "Photo Parsing. Cant find photos in \(JSONResult)", code: 0, userInfo: nil)
                        self.alertViewForError(error)
                    }
                }
            }
        }
    }
    
    lazy var sharedContext: NSManagedObjectContext = {
        return CoreDataStackManager.sharedInstance().managedObjectContext!
    }()
    
    func alertViewForError(error: NSError) {
        
    }
    
    func configureCell(cell: PhotoCollectionViewCell, photo: Photo) {
        
        var photoImage = UIImage(named: "photoPlaceHolder")
        
        cell.imageView!.image = nil
        
        // Set the photo image - assume each photo has an image path
        if photo.image != nil {
            println("image exists")
            photoImage = photo.image
        }
            
        else { // This is the interesting case. The photo has an image name, but it is not downloaded yet.
            
            // Start the task that will eventually download the image
            let task = FlickrClient.sharedInstance().taskForImage(photo.imagePath!) { data, error in
                
                if let error = error {
                    println("Photo download error: \(error.localizedDescription)")
                }
                
                if let data = data {
                    
                    println("downloaded image")

                    // Create the image
                    let image = UIImage(data: data)
                    
                    // update the model, so that the information gets cached
                    photo.image = image
                    
                    // update the cell later, on the main thread
                    dispatch_async(dispatch_get_main_queue()) {
                        cell.imageView!.image = image
                    }
                }
            }
            
            // This is the custom property on this cell. See TaskCancelingTableViewCell.swift for details.
            //cell.taskToCancelifCellIsReused = task
        }
        
        cell.imageView!.image = photoImage
    }
    

    // UICollectionView
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        //let sectionInfo = self.fetchedResultsController.sections![section] as! NSFetchedResultsSectionInfo
        
        //println("number Of Cells: \(sectionInfo.numberOfObjects)")
        //return sectionInfo.numberOfObjects
        
        return pin.photos.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("PhotoViewCell", forIndexPath: indexPath) as! PhotoCollectionViewCell
        
        let photo = pin.photos[indexPath.row]
        
        self.configureCell(cell, photo: photo)
        
        return cell
    }
    
    //func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        //let cell = collectionView.cellForItemAtIndexPath(indexPath) as! ColorCell
        
        // Whenever a cell is tapped we will toggle its presence in the selectedIndexes array
        //if let index = find(selectedIndexes, indexPath) {
        //    selectedIndexes.removeAtIndex(index)
        //} else {
        //    selectedIndexes.append(indexPath)
        //}
        
        // Then reconfigure the cell
        //configureCell(cell, atIndexPath: indexPath)
        
        // And update the buttom button
        //updateBottomButton()
    //}
    
}
