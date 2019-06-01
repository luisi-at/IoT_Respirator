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
    
}

extension SecondViewController: MKMapViewDelegate {
    
}
