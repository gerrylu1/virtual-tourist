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
    
    // set the number of photos to download if available for each collection
    let perPage = 30
    
    // set the compression quality for converting downloaded images to data for storing
    let compressionQuality: CGFloat = 0.7
    
    // set the desired layout for collection view
    let approximateDimensionForCellsInPhone:Int = 120
    let approximateDimensionForCellsInPad:Int = 180
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
        checkStoredImages()
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
    
    fileprivate func checkStoredImages() {
        let numberOfObjects = fetchedResultsController.sections?[0].numberOfObjects ?? 0
        if numberOfObjects > 0 {
            let imagesToBeDisplayed = numberOfObjects
            var imagesToBeDownloaded = 0
            var imagesInStorage = 0
            for index in 0...(numberOfObjects - 1) {
                let photo = fetchedResultsController.sections?[0].objects?[index] as! Photo
                if photo.image != nil {
                    imagesInStorage += 1
                } else {
                    imagesToBeDownloaded += 1
                    FlickrClient.getPhotoImage(id: photo.id!, farmId: photo.farmId!, serverId: photo.serverId!, secret: photo.secret!) { (image, error) in
                        // "if" is used here instead of "guard" since "imagesToBeDownloaded" still need to be counted regardless of the result of the download
                        if let image = image {
                            DispatchQueue.global(qos: .utility).sync {
                                photo.image = image.jpegData(compressionQuality: self.compressionQuality)
                                try? self.dataController.save()
                            }
                        } else {
                            // fail silently
                        }
                        imagesToBeDownloaded -= 1
                        if imagesToBeDownloaded == 0 {
                            self.newCollectionBarButton.isEnabled = true
                        }
                    }
                }
            }
            if imagesInStorage == imagesToBeDisplayed {
                newCollectionBarButton.isEnabled = true
            }
        } else {
            getPhotoCollection()
        }
    }
    
    fileprivate func getPhotoCollection() {
        var numberOfObjects = fetchedResultsController.sections?[0].numberOfObjects ?? 0
        while numberOfObjects > 0 {
            let photo = fetchedResultsController.sections?[0].objects?[0] as! Photo
            dataController.viewContext.delete(photo)
            try? dataController.save()
            numberOfObjects = fetchedResultsController.sections?[0].numberOfObjects ?? 0
        }
        noImagesLabel.isHidden = true
        FlickrClient.searchPhotosByCoordinate(latitude: pin.latitude, longitude: pin.longitude, page: Int(pin.page), perPage: perPage, completion: handlePhotoSearchResponse(photoList:error:))
    }
    
    fileprivate func handlePhotoSearchResponse(photoList: PhotoList?, error: Error?) {
        guard let photoList = photoList else {
            showAlert(title: "Downloading Photos Failed", message: error?.localizedDescription, on: self)
            return
        }
        pin.pages = Int64(photoList.pages)
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
            checkStoredImages()
        } else {
            noImagesLabel.isHidden = false
            newCollectionBarButton.isEnabled = true
        }
    }
    
    @IBAction func newCollectionBarButtonTapped(_ sender: Any) {
        showAlertOKCancel(title: "New Collection", message: "Fetching a new collection will remove all photos in this album, continue?", on: self, completion: handleNewCollectionRequest)
    }
    
    fileprivate func handleNewCollectionRequest() {
        newCollectionBarButton.isEnabled = false
        if pin.page < pin.pages {
            pin.page += 1
        } else {
            pin.page = 1
        }
        getPhotoCollection()
    }
    
}

extension PhotoAlbumViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchedResultsController.sections?[0].numberOfObjects ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageCell", for: indexPath) as! ImageCell
        let photo = fetchedResultsController.object(at: indexPath)
        if let imageData = photo.image, let image = UIImage(data: imageData) {
            cell.setImage(image)
        } else {
            cell.setImage(UIImage(named: "PhotoPlaceholder")!)
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        showAlertOnDelete(title: "Delete Photo", message: "Are you sure you want to delete this photo?", on: self) {
            let photo = self.fetchedResultsController.object(at: indexPath)
            self.dataController.viewContext.delete(photo)
            try? self.dataController.save()
        }
    }
    
}

extension PhotoAlbumViewController: NSFetchedResultsControllerDelegate {
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert: collectionView.insertItems(at: [newIndexPath!])
        case .delete: collectionView.deleteItems(at: [indexPath!])
        case .update: collectionView.reloadItems(at: [indexPath!])
        default: fatalError("Invalid change type in controller(_:didChange:at:for:newIndexPath:). Only .insert, .update and .delete should be possible.")
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
