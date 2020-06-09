//
//  ViewController.swift
//  VirtualTourist
//
//  Created by Gerry Low on 2020-06-06.
//  Copyright © 2020 Gerry Low. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class TravelLocationsMapViewController: UIViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    
    var dataController: DataController!
    
    var pins: [Pin] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupMapView()
        setupFetchedResultsController()
        setupGestureRecognizer()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isHidden = true
    }
    
    fileprivate func setupMapView() {
        mapView.isRotateEnabled = false
        if let mapRegion = try? PropertyListDecoder().decode(MapRegion.self, from: UserDefaults.standard.value(forKey: AppDelegate.keyForMapRegion) as! Data) {
            let center = CLLocationCoordinate2D(latitude: mapRegion.latitude, longitude: mapRegion.longitude)
            let span = MKCoordinateSpan(latitudeDelta: mapRegion.latitudeDelta, longitudeDelta: mapRegion.longitudeDelta)
            let region = MKCoordinateRegion.init(center: center, span: span)
            mapView.setRegion(region, animated: true)
        }
    }
    
    fileprivate func setupFetchedResultsController() {
        let fetchRequest: NSFetchRequest<Pin> = Pin.fetchRequest()
        do {
            let result = try dataController.viewContext.fetch(fetchRequest)
            pins = result
            loadPins()
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
    }
    
    fileprivate func setupGestureRecognizer() {
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(self.addPin(gestureRecognizer:)))
        mapView.addGestureRecognizer(gestureRecognizer)
    }
    
    fileprivate func loadPins() {
        if pins.count > 0 {
            var annotations: [MKPointAnnotation] = []
            for index in 0...(pins.count - 1) {
                let annotation = MKPointAnnotation()
                annotation.title = String(index)
                annotation.coordinate = CLLocationCoordinate2D(latitude: pins[index].latitude, longitude: pins[index].longitude)
                annotations.append(annotation)
            }
            mapView.addAnnotations(annotations)
        }
    }
    
    @objc func addPin(gestureRecognizer: UITapGestureRecognizer) {
        if gestureRecognizer.state == .began {
            let location = gestureRecognizer.location(in: mapView)
            let coordinate = mapView.convert(location, toCoordinateFrom: mapView)
            // Add annotation to context view
            let pin = Pin(context: dataController.viewContext)
            pin.latitude = coordinate.latitude
            pin.longitude = coordinate.longitude
            do {
                try dataController.save()
                // Add annotation on map
                let annotation = MKPointAnnotation()
                annotation.title = String(pins.count)
                annotation.coordinate = coordinate
                mapView.addAnnotation(annotation)
                // Add to pins array for index referencing
                pins.append(pin)
            } catch {
                fatalError("New pin could not be saved: \(error.localizedDescription)")
            }
        }
    }
    
}

extension TravelLocationsMapViewController: MKMapViewDelegate {
    
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
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        let photoAlbumViewController = storyboard?.instantiateViewController(withIdentifier: "PhotoAlbumViewController") as! PhotoAlbumViewController
        let index = Int((view.annotation?.title)!!)!
        photoAlbumViewController.pin = pins[index]
        photoAlbumViewController.dataController = dataController
        navigationController?.pushViewController(photoAlbumViewController, animated: true)
        mapView.deselectAnnotation(view.annotation, animated: false)
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        saveCurrentMapRegion(mapView)
    }
    
    fileprivate func saveCurrentMapRegion(_ mapView: MKMapView) {
        let region = mapView.region
        let mapRegion = MapRegion(latitude: region.center.latitude, longitude: region.center.longitude, latitudeDelta: region.span.latitudeDelta, longitudeDelta: region.span.longitudeDelta)
        UserDefaults.standard.setValue(try? PropertyListEncoder().encode(mapRegion), forKey: AppDelegate.keyForMapRegion)
    }
    
}
