//
//  TaskCancelingCollectionViewCell.swift
//  VirtualTourist
//
//  Created by Jason on 1/31/15.
//  Borrowed by Steve on 9/15/15.
//  Copyright (c) 2015 Udacity. All rights reserved.
//

import UIKit

class TaskCancelingCollectionViewCell : UICollectionViewCell {

    // The property uses a property observer. Any time its
    // value is set it canceles the previous NSURLSessionTask
    
    var imageName: String = ""
    
    var taskToCancelifCellIsReused: NSURLSessionTask? {

        didSet {
            if let taskToCancel = oldValue {
                taskToCancel.cancel()
            }
        }
    }
}
