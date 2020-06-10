//
//  PhotoAlbumViewController.swift
//  VirtualTourist
//
//  Created by Gerry Low on 2020-06-06.
//  Copyright © 2020 Gerry Low. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class PhotoAlbumViewController: UIViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    @IBOutlet weak var newCollectionBarButton: UIBarButtonItem!
    @IBOutlet weak var noImagesLabel: UILabel!
    
    var dataController: DataController!
    var fetchedResultsController: NSFetchedResultsController<Photo>!
    
    var pin: Pin!
    var page = 1
    
    var imagesToBeDisplayed = 0
    var imagesToBeDownloaded = 0
    
    // set the number of photos to download if available for each collection
    let perPage = 25
    
    // set the compression quality for converting downloaded images to data for storing
    let compressionQuality: CGFloat = 0.7
    
    // set the desired layout for collection view
    let approximateDimensionForCellsInPhone:Int = 120
    let approximateDimensionForCellsInPad:Int = 300
    let spacingForCells:CGFloat = 3.0
    
    var approximateDimensionForCells:Int {
        if UIDevice.current.userInterfaceIdiom == .pad {
            return approximateDimensionForCellsInPad
        }
        else if UIDevice.current.userInterfaceIdiom == .phone {
            return approximateDimensionForCellsInPhone
        }
        else {
            assert(false, "The user is using an unrecognized device")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.isHidden = false
        setupFetchedResultsController()
        registerCollectionViewCells()
        flowLayoutAdjustment(width: collectionView.frame.size.width)
        loadPin()
    }
    
    fileprivate func registerCollectionViewCells() {
        let cell = UINib(nibName: "ImageCell", bundle: nil)
        collectionView.register(cell, forCellWithReuseIdentifier: "ImageCell")
    }
    
    fileprivate func flowLayoutAdjustment(width: CGFloat) {
        if isViewLoaded {
            let numberOfItemsInRow:Int = Int(width) / approximateDimensionForCells
            let dimension:CGFloat = width / CGFloat(numberOfItemsInRow) - spacingForCells * 2.0
            flowLayout.minimumInteritemSpacing = spacingForCells
            flowLayout.minimumLineSpacing = spacingForCells * 2
            flowLayout.itemSize = CGSize(width: dimension, height: dimension)
        }
    }
    
    fileprivate func loadPin() {
        let annotation = MKPointAnnotation()
        annotation.coordinate = CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
        mapView.showAnnotations([annotation], animated: true)
    }
    
    fileprivate func setupFetchedResultsController() {
        let fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
        let predicate = NSPredicate(format: "pin == %@", pin)
        fetchRequest.predicate = predicate
        let sortById = NSSortDescriptor(key: "id", ascending: true)
        fetchRequest.sortDescriptors = [sortById]
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: "lat\(pin.latitude)lon\(pin.longitude)-photos")
        fetchedResultsController.delegate = self
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
    }
    
    fileprivate func getPhotoCollection() {
        FlickrClient.searchPhotosByCoordinate(latitude: pin.latitude, longitude: pin.longitude, page: page, perPage: perPage, completion: handlePhotoSearchResponse(photoList:error:))
    }
    
    fileprivate func handlePhotoSearchResponse(photoList: PhotoList?, error: Error?) {
        guard let photoList = photoList else {
            print(error?.localizedDescription)
            return
        }
        // TODO: update attribute pages in data model Pin
        if photoList.photo.count > 0 {
            for photo in photoList.photo {
                let newPhoto = Photo(context: dataController.viewContext)
                newPhoto.id = photo.id
                newPhoto.farmId = String(photo.farm)
                newPhoto.serverId = photo.server
                newPhoto.secret = photo.secret
                newPhoto.pin = pin
            }
            try? dataController.save()
        } else {
            noImagesLabel.isHidden = false
            newCollectionBarButton.isEnabled = true
        }
    }
    
}

extension PhotoAlbumViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let numberOfObjects = fetchedResultsController.sections?[0].numberOfObjects ?? 0
        if numberOfObjects == 0 {
            getPhotoCollection()
        } else {
            imagesToBeDisplayed = numberOfObjects
        }
        return numberOfObjects
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageCell", for: indexPath) as! ImageCell
        let photo = fetchedResultsController.object(at: indexPath)
        if let imageData = photo.image, let image = UIImage(data: imageData) {
            cell.setImage(image)
            imagesToBeDisplayed -= 1
            if imagesToBeDisplayed == 0 {
                self.newCollectionBarButton.isEnabled = true
            }
        } else {
            cell.setImage(UIImage(named: "PhotoPlaceholder")!)
            imagesToBeDownloaded += 1
            FlickrClient.getPhotoImage(id: photo.id!, farmId: photo.farmId!, serverId: photo.serverId!, secret: photo.secret!) { (image, error) in
                guard let image = image else {
                    print(error?.localizedDescription)
                    return
                }
                DispatchQueue.global(qos: .utility).sync {
                    photo.image = image.jpegData(compressionQuality: self.compressionQuality)
                    self.imagesToBeDownloaded -= 1
                    if self.imagesToBeDownloaded == 0 {
                        try? self.dataController.save()
                        self.newCollectionBarButton.isEnabled = true
                    }
                }
            }
        }
        return cell
    }
    
}

extension PhotoAlbumViewController: NSFetchedResultsControllerDelegate {
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert: collectionView.insertItems(at: [newIndexPath!])
        case .delete: collectionView.deleteItems(at: [indexPath!])
        case .update: collectionView.reloadItems(at: [indexPath!])
        default: fatalError("Invalid change type in controller(_:didChange:at:for:newIndexPath:). Only .insert and .delete should be possible.")
        }
    }
    
}

extension PhotoAlbumViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let reuseId = "pin"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView?.pinTintColor = .red
        } else {
            pinView?.annotation = annotation
        }
        return pinView
    }
    
}
