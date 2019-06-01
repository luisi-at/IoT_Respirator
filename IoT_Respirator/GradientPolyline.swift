//
//  GradientPolyline.swift
//  IoT_Respirator
//
//  Created by Alexander Luisi on 01/06/2019.
//  Copyright © 2019 Alexander Luisi. All rights reserved.
//
// Adapted for use from: https://stackoverflow.com/a/53126528 accessed 01/06/2019

import Foundation
import MapKit

class GradientPolyline: MKPolyline {
    var hues: [CGFloat]?
    public func getHue(from index: Int) -> CGColor {
        return UIColor(hue: (hues?[index])!, saturation: 1, brightness: 1, alpha: 1).cgColor
    }
}

extension GradientPolyline {
    convenience init(locations: [CLLocationCoordinate2D], readings: [ReadingPacket]) {
        // Initialize the superclass
        self.init(coordinates: locations, count: locations.count)
        
        // From the EPA's guide on how to calculate AQI: https://airnowtest.epa.gov/sites/default/files/2018-05/aqi-technical-assistance-document-may2016.pdf accessed 01/06/2019
        let aqi_HAZARD = 301, aqi_VERY_UNHEALTHY = 201, aqi_UNHEALTHY = 151, aqi_USG = 101, aqi_MODERATE = 51, aqi_GOOD = 50
        let H_MIN: Double = 0.3 // want a greeny color
        let H_MAX: Double = 0.0 // want a red color
        
        hues = readings.map( {
            let aqiEquiv: Int = $0.airQualityEstimate!
            
            // Select the hue based on the AQI value
            if aqiEquiv <= aqi_GOOD {
                return CGFloat(H_MIN)
            }
            // Weight the hue according to the AQI value
            if aqiEquiv > aqi_GOOD && aqiEquiv <= aqi_MODERATE {
                return CGFloat((H_MIN + ((aqiEquiv - aqi_GOOD) * H_MIN - H_MAX) / (aqi_MODERATE - aqi_GOOD)))
            }
            if aqiEquiv > aqi_MODERATE && aqiEquiv <= aqi_USG {
                return CGFloat((H_MIN + ((aqiEquiv - aqi_MODERATE) * H_MIN - H_MAX) / (aqi_USG - aqi_MODERATE)))
            }
            if aqiEquiv > aqi_USG && aqiEquiv <= aqi_UNHEALTHY {
                return CGFloat((H_MIN + ((aqiEquiv - aqi_USG) * H_MIN - H_MAX) / (aqi_UNHEALTHY - aqi_USG)))
            }
            if aqiEquiv > aqi_UNHEALTHY && aqiEquiv <= aqi_VERY_UNHEALTHY {
                return CGFloat((H_MIN + ((aqiEquiv - aqi_UNHEALTHY) * H_MIN - H_MAX) / (aqi_VERY_UNHEALTHY - aqi_UNHEALTHY)))
            }
            if aqiEquiv > aqi_VERY_UNHEALTHY && aqiEquiv <= aqi_HAZARD {
                return CGFloat((H_MIN + ((aqiEquiv - aqi_VERY_UNHEALTHY) * H_MIN - H_MAX) / (aqi_HAZARD - aqi_VERY_UNHEALTHY)))
            }
            
            // Default case to return the maximum pollution color
            return CGFloat(H_MAX)
            
        })
        
        
    }
}
