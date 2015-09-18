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

class PhotoViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, NSFetchedResultsControllerDelegate {
    
    let NUM_PHOTOS_TO_FETCH = 21
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var bottomButton: UIBarButtonItem!
    
    var pin: Pin!
    
    var selectedIndexes = [NSIndexPath]()
    var insertedIndexPaths: [NSIndexPath]!
    var deletedIndexPaths: [NSIndexPath]!

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
        
        // Perform the fetch of the photos for the pin
        fetchedResultsController.performFetch(nil)
        
        // Set the delegate to this view controller
        fetchedResultsController.delegate = self
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Lay out the collection view so that cells take up 1/3 of the width,
        // with no space in between.
        let layout : UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.minimumLineSpacing = 3
        layout.minimumInteritemSpacing = 3
        
        let width = floor((self.collectionView.frame.size.width-9)/3)
        layout.itemSize = CGSize(width: width, height: width)
        collectionView.collectionViewLayout = layout
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if pin.photos.isEmpty {
            loadPhotos()
        }
    }
    
    // Fetched Results Controller
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        
        let fetchRequest = NSFetchRequest(entityName: "Photo")
        
        fetchRequest.sortDescriptors = []
        fetchRequest.predicate = NSPredicate(format: "pin == %@", self.pin)
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
            managedObjectContext: self.sharedContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
        
        return fetchedResultsController
    }()
    
    // For CoreData convenience
    lazy var sharedContext: NSManagedObjectContext = {
        return CoreDataStackManager.sharedInstance().managedObjectContext!
    }()

    // Load photos from the flickr service
    func loadPhotos() {
        
        // don't allow the buttom button to be tapped when loading
        bottomButton.enabled = false
        
        FlickrClient.sharedInstance().getPhotosForLocation(pin.coordinate.latitude, longitude: pin.coordinate.longitude) { JSONResult, error in
            
            if let error = error {
                self.alertViewForError(error)
                
            } else {
                if let photoDictionaries = JSONResult {
                    
                    // Generate array of random indices to use to pull pictures from results
                    let indices = self.makeIndexList(self.NUM_PHOTOS_TO_FETCH, max: photoDictionaries.count - 1)
                    
                    for index in indices {
                        let dictionary = photoDictionaries[index]
                        let photo = Photo(dictionary: dictionary, context: self.sharedContext)
                        photo.pin = self.pin
                    }
                    
                    // re-enable the bottom button when we're done loading
                    dispatch_async(dispatch_get_main_queue()) {
                        self.bottomButton.enabled = true
                    }

                } else {
                    let error = NSError(domain: "Photo Parsing. Cant find photos in \(JSONResult)", code: 0, userInfo: nil)
                    self.alertViewForError(error)
                }
            }
        }
    }

    func alertViewForError(error: NSError) {
        let alertController = UIAlertController(title: "Error Occurred", message: error.localizedDescription, preferredStyle: UIAlertControllerStyle.Alert)
        alertController.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default,handler: nil))
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    func configureCell(cell: PhotoCollectionViewCell, photo: Photo) {
        
        // Set the photo image if we have one cached in memory/on disk
        if photo.image != nil {
            cell.imageView!.image = photo.image
        }
            
        else { // This is the interesting case. The photo has an image name, but it is not downloaded yet.
            
            cell.imageView!.image = nil
            cell.activityIndicator.startAnimating()
            
            // Start the task that will eventually download the image
            let task = FlickrClient.sharedInstance().taskForImage(photo.imagePath!) { data, error in
                
                if let error = error {
                    println("Photo download error: \(error.localizedDescription)")
                }
                
                if let data = data {

                    // Create the image
                    let image = UIImage(data: data)
                    
                    // update the model, so that the information gets cached
                    photo.image = image
                    
                    // update the cell later, on the main thread
                    dispatch_async(dispatch_get_main_queue()) {
                        cell.activityIndicator.stopAnimating()
                        cell.imageView!.image = image
                    }
                }
            }
            
            // This is the custom property on this cell. See TaskCancelingCollectionViewCell.swift for details.
            cell.taskToCancelifCellIsReused = task
        }
    }
    

    // UICollectionView
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let sectionInfo = self.fetchedResultsController.sections![section] as! NSFetchedResultsSectionInfo
        return sectionInfo.numberOfObjects
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {

        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("PhotoViewCell", forIndexPath: indexPath) as! PhotoCollectionViewCell
        
        // Get the photo for this cell from the fetchedresultscontroller
        let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        
        self.configureCell(cell, photo: photo)
        cell.imageView.alpha = 1.0
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! PhotoCollectionViewCell
        
        // Whenever a cell is tapped we will toggle its presence in the selectedIndexes array
        if let index = find(selectedIndexes, indexPath) {
            selectedIndexes.removeAtIndex(index)
            cell.imageView.alpha = 1.0
        } else {
            selectedIndexes.append(indexPath)
            cell.imageView.alpha = 0.5
        }
        
        // And update the buttom button
        updateBottomButton()
    }

    // Fetched Results Controller Delegate
    // Whenever changes are made to Core Data the following three methods are invoked. This first method is used to create
    // three fresh arrays to record the index paths that will be changed.
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        // We are about to handle some new changes. Start out with empty arrays for each change type
        insertedIndexPaths = [NSIndexPath]()
        deletedIndexPaths = [NSIndexPath]()
        selectedIndexes = [NSIndexPath]()
    }
    
    // The second method may be called multiple times, once for each Photo object that is added, deleted, or changed.
    // We store the incex paths into the three arrays.
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        
        switch type{
            
        case .Insert:
            println("Insert an item")
            // Here we are noting that a new Photo instance has been added to Core Data. We remember its index path
            // so that we can add a cell in "controllerDidChangeContent". Note that the "newIndexPath" parameter has
            // the index path that we want in this case
            insertedIndexPaths.append(newIndexPath!)
            break
        case .Delete:
            println("Delete an item")
            // Here we are noting that a Photo instance has been deleted from Core Data. We keep remember its index path
            // so that we can remove the corresponding cell in "controllerDidChangeContent". The "indexPath" parameter has
            // value that we want in this case.
            deletedIndexPaths.append(indexPath!)
            break
        case .Update:
            // Photo instances do not get updated in this app.
            println("Update an item.  We don't expect to see this in this app.")
            break
        case .Move:
            println("Move an item. We don't expect to see this in this app.")
            break
        default:
            break
        }
    }
    
    // This method is invoked after all of the changed in the current batch have been collected
    // into the three index path arrays (insert, delete, and upate). We now need to loop through the
    // arrays and perform the changes.
    //
    // The most interesting thing about the method is the collection view's "performBatchUpdates" method.
    // Notice that all of the changes are performed inside a closure that is handed to the collection view.
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        
        collectionView.performBatchUpdates({() -> Void in
            
            for indexPath in self.insertedIndexPaths {
                self.collectionView.insertItemsAtIndexPaths([indexPath])
            }
            
            for indexPath in self.deletedIndexPaths {
                self.collectionView.deleteItemsAtIndexPaths([indexPath])
            }
            
            // Save to core data once all of the collectionview changes have been processed
            CoreDataStackManager.sharedInstance().saveContext()
            
        }, completion: nil)
    }
    
    // Update the text of the bottom button based on if photos are selected or not
    func updateBottomButton() {
        if selectedIndexes.count > 0 {
            bottomButton.title = "Remove Selected Pictures"
        } else {
            bottomButton.title = "New Collection"
        }
    }
    
    // Bottom button is tapped - either get a new photo collection or remove the selected photos
    @IBAction func bottomButtonTapped(sender: AnyObject) {
        
        if selectedIndexes.isEmpty {
            deleteAllPhotos()
            loadPhotos()
        } else {
            deleteSelectedPhotos()
        }
        
        updateBottomButton()
    }
    
    // Remove all photos for this pin
    func deleteAllPhotos() {
        
        for photo in fetchedResultsController.fetchedObjects as! [Photo] {
            sharedContext.deleteObject(photo)
        }
    }
    
    // Remove only the selected photos
    func deleteSelectedPhotos() {
        
        var photosToDelete = [Photo]()
        
        for indexPath in selectedIndexes {
            photosToDelete.append(fetchedResultsController.objectAtIndexPath(indexPath) as! Photo)
        }
        
        for photo in photosToDelete {
            sharedContext.deleteObject(photo)
        }
        
        // All selected photos removed - reset the array
        selectedIndexes = [NSIndexPath]()
    }
    
    // Return a random list of indices to use in selecting random photos
    func makeIndexList(count:Int, max:Int) -> [Int] {
        var result:[Int] = []
        for i in 0..<count {
            result.append(Int(arc4random_uniform(UInt32(max)) + 1))
        }
        return result.sorted(<)
    }
}
