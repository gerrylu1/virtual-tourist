//
//  ViewController.swift
//  VirtualTourist
//
//  Created by Gerry Low on 2020-06-06.
//  Copyright © 2020 Gerry Low. All rights reserved.
//

import UIKit
import MapKit

class TravelLocationsMapViewController: UIViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isHidden = true
        
        setupMapView()
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
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        saveCurrentMapRegion(mapView)
    }
    
    fileprivate func saveCurrentMapRegion(_ mapView: MKMapView) {
        let region = mapView.region
        let mapRegion = MapRegion(latitude: region.center.latitude, longitude: region.center.longitude, latitudeDelta: region.span.latitudeDelta, longitudeDelta: region.span.longitudeDelta)
        UserDefaults.standard.setValue(try? PropertyListEncoder().encode(mapRegion), forKey: AppDelegate.keyForMapRegion)
    }
    
}
