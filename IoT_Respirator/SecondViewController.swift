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

// Array to hold the array from the response
struct DataFromAPI {
    static var apiArray: [WebPacket] = []
}

class SecondViewController: UIViewController {

    var selected: UInt8 = 0
    var gradientLayer: CAGradientLayer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        NotificationCenter.default.addObserver(self, selector: #selector(onGlobalUpdated(_:)), name: .didUpdateGlobalArray, object: nil)
        fillColorViewer()
        
        // Zoom to current location on load
        guard let userLocation = GlobalArrays.currentLocation else { return }
        let span = MKCoordinateSpan(latitudeDelta: 0.002, longitudeDelta: 0.002)
        let viewRegion = MKCoordinateRegion(center: userLocation, span: span)
        mapView.setRegion(viewRegion, animated: true)
        mapView.showsUserLocation = true
        
        selected = 0

    }

    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var colorViewer: UIView!
    
    @objc func onGlobalUpdated(_ notification: Notification) {
        
        // Extract the data here from the global array
        // TODO- call the map update routine
        
        
        switch selected {
        case 0:
            // Draw the gradient of the AQI
            mapView.removeOverlays(mapView.overlays)
            addPollutionOnMapView()
            
        case 1:
            // Draw the route taken
            mapView.removeOverlays(mapView.overlays)
            addRouteOnMapView()
        default:
            break;
        }
        
    }
    
    @IBAction func mapTypeChanged(_ sender: UISegmentedControl) {
    
        //mapView.mapType = MKMapType.init(rawValue: UInt(sender.selectedSegmentIndex)) ?? .standard
        
        switch sender.selectedSegmentIndex {
        case 0:
            mapView.removeOverlays(mapView.overlays)
            mapView.mapType = .standard
            selected = 0
            //addPollutionOnMapView()
        case 1:
            mapView.removeOverlays(mapView.overlays)
            mapView.mapType = .hybrid
            selected = 1
            //addRouteOnMapView()
        case 2:
            mapView.removeOverlays(mapView.overlays)
            mapView.mapType = .standard
            selected = 2
            getPollutionHistory()
            // Pull in the web data in the corresponding function call
            // Use this for the route history
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
    
    // For showing the AQI shading key
    func fillColorViewer() {
        gradientLayer = CAGradientLayer()
        
        gradientLayer.frame = colorViewer.bounds
        gradientLayer.colors = [UIColor.red.cgColor, UIColor.yellow.cgColor, UIColor.green.cgColor]
        
        colorViewer.layer.addSublayer(gradientLayer)
        
    }
    
    func getPollutionHistory() {
        var coordinatesList: [CLLocationCoordinate2D] = []
        //var webModel: [WebPacket] = []
        
        var urlComponents = URLComponents()
        urlComponents.scheme = "http"
        urlComponents.host = "192.168.1.206" // This only works on the local network! Will need to change to the AWS instance when 'on the move'
        urlComponents.port = 5000
        
        // Get the formatter for the date
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        // Form yesterday's date as a test for proof of concept:
        var dateComponents = DateComponents()
        dateComponents.setValue(-1, for: .day)
        let yesterday = Calendar.current.date(byAdding: dateComponents, to: Date())!
        urlComponents.path = "/data/" + formatter.string(from: yesterday)
        
        let url = urlComponents.url!
        // Make this URL a request
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        
        // GET the data and look at the reponse
        let task = URLSession.shared.dataTask(with: request) { (data, response, error ) -> Void in
            // Let the other view handle
            
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                // Show an error message if the data is not able to be retrieved
                let alert = UIAlertController(title: "Unable to get Pollution History", message: "The server could not find your pollution data", preferredStyle: .alert)
                alert.addAction((UIAlertAction(title: "OK", style: .cancel, handler: nil)))
                // Present the alert
                self.present(alert, animated: true)
                return
            }
 
            // The response contains the data, deserialize into an array of pollution indices
            // using the Codable Protocol
            print(String(data: data!, encoding: .utf8)!)
            
            do {
                let decoder = JSONDecoder()
                let webModel = try decoder.decode([WebPacket].self, from: data!)
                DataFromAPI.apiArray = webModel
            } catch let error {
                print(error.localizedDescription)
            }
            
            //print(response!)
            
        }
        task.resume()
 
        
        // Check if the array has some points
        if !DataFromAPI.apiArray.isEmpty {
            // Get the coordinates for the map
            for i in 0..<DataFromAPI.apiArray.count {
                let coord = CLLocationCoordinate2D(latitude: CLLocationDegrees(DataFromAPI.apiArray[i].latitude), longitude: DataFromAPI.apiArray[i].longitude)
                coordinatesList.append(coord)
            }
            
            let pollutionPolyline = GradientPolyline(locations: coordinatesList, readings: DataFromAPI.apiArray)
            mapView.addOverlay(pollutionPolyline)
            
        } else {
            // Don't shade the map if there's nothing the shade
            return
        }
        
        
        
    }
    
    
}

extension SecondViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        
        // Checks for the route view
        
        // Check for the gradient view for the pollution real time and pollution history
        if selected == 0 || selected == 2 {
            let polylineRender = GradientPolylineRenderer(overlay: overlay)
            polylineRender.lineWidth = 15
            polylineRender.lineJoin = .round
            polylineRender.miterLimit = 10
            polylineRender.lineCap = .round
            return polylineRender
        }
        
        if selected == 1 {
            let lineView = MKPolylineRenderer(overlay: overlay)
            lineView.strokeColor = UIColor.blue
            lineView.lineJoin = .round
            lineView.lineCap = .round
            lineView.miterLimit = 10
            lineView.lineWidth = 10
            return lineView
        }
        
        if selected == 0 || selected == 2 {
            let polylineRender = GradientPolylineRenderer(overlay: overlay)
            polylineRender.lineWidth = 15
            polylineRender.lineJoin = .round
            polylineRender.miterLimit = 10
            polylineRender.lineCap = .round
            return polylineRender
        }
        
        if selected == 2 {
            let polylineRender = GradientPolylineRenderer(overlay: overlay)
            polylineRender.lineWidth = 15
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

