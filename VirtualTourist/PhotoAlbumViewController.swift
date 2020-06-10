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
    
    var dataController: DataController!
    var fetchedResultsController: NSFetchedResultsController<Photo>!
    
    var pin: Pin!
    var page = 1
    
    // set the number of photos to download if available for each collection
    let perPage = 25
    
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
        FlickrClient.searchPhotosByCoordinate(latitude: pin.latitude, longitude: pin.longitude, page: page, perPage: perPage) { (photoList, error) in
            guard let photoList = photoList else {
                print(error?.localizedDescription)
                return
            }
            // TODO: update attribute pages in data model Pin
            for photo in photoList.photo {
                let newPhoto = Photo(context: self.dataController.viewContext)
                newPhoto.id = photo.id
                newPhoto.farmId = String(photo.farm)
                newPhoto.serverId = photo.server
                newPhoto.secret = photo.secret
                newPhoto.pin = self.pin
            }
            do {
                try self.fetchedResultsController.performFetch()
            } catch {
                fatalError("The fetch could not be performed: \(error.localizedDescription)")
            }
            self.collectionView.reloadData()
        }
    }
    
}

extension PhotoAlbumViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let numberOfObjects = fetchedResultsController.sections?[0].numberOfObjects ?? 0
        if numberOfObjects == 0 {
            getPhotoCollection()
        }
        return numberOfObjects
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
    
}

extension PhotoAlbumViewController: NSFetchedResultsControllerDelegate {
    
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
