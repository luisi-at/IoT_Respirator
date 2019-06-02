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

    var selected: UInt8 = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        NotificationCenter.default.addObserver(self, selector: #selector(onGlobalUpdated(_:)), name: .didUpdateGlobalArray, object: nil)
        
        // Zoom to current location on load
        guard let userLocation = GlobalArrays.currentLocation else { return }
        let span = MKCoordinateSpan(latitudeDelta: 0.002, longitudeDelta: 0.002)
        let viewRegion = MKCoordinateRegion(center: userLocation, span: span)
        mapView.setRegion(viewRegion, animated: true)
        mapView.showsUserLocation = true
        
    }

    
    @IBOutlet weak var mapView: MKMapView!
    
    @objc func onGlobalUpdated(_ notification: Notification) {
        
        // Extract the data here from the global array
        // TODO- call the map update routine
        mapView.removeOverlays(mapView.overlays)
        
        switch selected {
        case 0:
            // Draw the gradient of the AQI
            
            addPollutionOnMapView()
            
        case 1:
            // Draw the route taken
           
            addRouteOnMapView()
        default:
            break;
        }
        
    }
    
    @IBAction func mapTypeChanged(_ sender: UISegmentedControl) {
    
        //mapView.mapType = MKMapType.init(rawValue: UInt(sender.selectedSegmentIndex)) ?? .standard
        
        switch sender.selectedSegmentIndex {
        case 0:
            mapView.mapType = .standard
            selected = 0
            //addPollutionOnMapView()
        case 1:
            mapView.mapType = .hybrid
            selected = 1
            //addRouteOnMapView()
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
        
        let pollutionPolyline = GradientPolyline(locations: coordinatesList, readings: GlobalArrays.globalData)
            //GradientPolyline(coordinates: coordinatesList, count: coordinatesList.count, GlobalArrays.globalData)
        
        mapView.addOverlay(pollutionPolyline)
    }
    
    
}

extension SecondViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        
        // Checks for the route view
        if selected == 1 {
            let lineView = MKPolylineRenderer(overlay: overlay)
            lineView.strokeColor = UIColor.blue
            lineView.lineJoin = .round
            lineView.lineCap = .round
            lineView.miterLimit = 10
            lineView.lineWidth = 10
            return lineView
        }
        
        // Check for the gradient view
        if selected == 0 {
            let polylineRender = GradientPolylineRenderer(overlay: overlay)
            polylineRender.lineWidth = 10
            polylineRender.lineJoin = .round
            polylineRender.miterLimit = 10
            polylineRender.lineCap = .round
            return polylineRender
        }
        
        return MKOverlayRenderer()
    }
    
    
}

// Subclass the polyline to add an identifier (may cause issues?)
extension Notification.Name {
    static let didUpdateGlobalArray = Notification.Name("didUpdateGlobalArray")
}

