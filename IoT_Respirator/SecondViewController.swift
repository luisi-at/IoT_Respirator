//
//  SecondViewController.swift
//  IoT_Respirator
//
//  Created by Alexander Luisi on 29/05/2019.
//  Copyright © 2019 Alexander Luisi. All rights reserved.
//

import UIKit
import MapKit
import NotificationCenter // raise an event when the array has been added to

class SecondViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        NotificationCenter.default.addObserver(self, selector: #selector(onGlobalUpdated(_:)), name: .didUpdateGlobalArray, object: nil)
    }

    
    @IBOutlet weak var mapView: MKMapView!
    
    @objc func onGlobalUpdated(_ notification: Notification) {
        
        // Extract the data here from the global array
        // TODO- call the map update routine
        
    }
    
    @IBAction func mapTypeChanged(_ sender: UISegmentedControl) {
    
        //mapView.mapType = MKMapType.init(rawValue: UInt(sender.selectedSegmentIndex)) ?? .standard
        
        switch sender.selectedSegmentIndex {
        case 0:
            mapView.mapType = .standard
            // Draw the gradient of the AQI
            addPollutionOnMapView()
        case 1:
            mapView.mapType = .hybrid
            // Draw the route taken
            addRouteOnMapView()
        default:
            mapView.mapType = .standard
        }
    
    }
    
    func addRouteOnMapView() {
        var coordinatesList = [CLLocationCoordinate2D]()
        
        // Extract the coordinates
        for i in 0..<GlobalArrays.globalData.count {
            // build up the array of coordinates for the line
            let coord = GlobalArrays.globalData[i].mapKitCoordinate
            coordinatesList.append(coord!)
        }
 
        let routePolyline = MKPolyline(coordinates: coordinatesList, count: coordinatesList.count)
        mapView.addOverlay(routePolyline)
        
    }
    
    func addPollutionOnMapView() {
        var coordinatesList = [CLLocationCoordinate2D]()
        
        // Extract the coordinates
        for i in 0..<GlobalArrays.globalData.count {
            // build up the array of coordinates for the line
            let coord = GlobalArrays.globalData[i].mapKitCoordinate
            coordinatesList.append(coord!)
        }
        
        let pollutionPolyline = GradientPolyline(coordinates: coordinatesList, count: coordinatesList.count)
        mapView.addOverlay(pollutionPolyline)
    }
    
    
}

extension SecondViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        
        // Checks for the route view
        if let overlay = overlay as? MKPolyline {
            let lineView = MKPolylineRenderer(overlay: overlay)
            lineView.strokeColor = UIColor.blue
            return lineView
        }
        
        // Check for the gradient view
        if let overlay = overlay as? GradientPolyline {
            let polylineRender = GradientPolylineRenderer(overlay: overlay)
            polylineRender.lineWidth = 5
            return polylineRender
        }
        
        return MKOverlayRenderer()
    }
    
    
}

// Subclass the polyline to add an identifier (may cause issues?)

