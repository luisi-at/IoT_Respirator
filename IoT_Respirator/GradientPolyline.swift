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
        
        // From the EPA's guide on how to calculate AQI:
        // https://airnowtest.epa.gov/sites/default/files/2018-05/aqi-technical-assistance-document-may2016.pdf
        // accessed 01/06/2019
        let aqi_HAZARD: Double = 301
        let aqi_VERY_UNHEALTHY: Double = 201
        let aqi_UNHEALTHY: Double = 151
        let aqi_USG: Double = 101
        let aqi_MODERATE: Double = 51
        let aqi_GOOD: Double = 50
        
        let H_MIN: Double = 0.33 // want a green color
        let H_MAX: Double = 0.01 // want a red color
        let H_DIFF: Double = H_MIN - H_MAX
        
        hues = readings.map( {
            let aqiEquiv: Double = Double($0.airQualityEstimate!)
            
            // Select the hue based on the AQI value
            if aqiEquiv <= aqi_GOOD {
                return CGFloat(H_MIN)
            }
            // Weight the hue according to the AQI value
            if aqiEquiv > aqi_GOOD && aqiEquiv <= aqi_MODERATE {
                
                let interval = (aqi_MODERATE - aqi_GOOD)
                let mult = ((aqiEquiv - aqi_GOOD) * (H_DIFF))
                return CGFloat((H_MAX +  mult / interval))
                
            }
            
            if aqiEquiv > aqi_MODERATE && aqiEquiv <= aqi_USG {
                
                let interval = (aqi_USG - aqi_MODERATE)
                let mult = ((aqiEquiv - aqi_MODERATE) * (H_DIFF))
                return CGFloat((H_MAX +  mult / interval))
                
            }
            if aqiEquiv > aqi_USG || aqiEquiv <= aqi_UNHEALTHY {
                
                let interval = (aqi_UNHEALTHY - aqi_USG)
                let mult = ((aqiEquiv - aqi_USG) * (H_DIFF))
                return CGFloat((H_MAX +  mult / interval))
                
            }
            if aqiEquiv > aqi_UNHEALTHY || aqiEquiv <= aqi_VERY_UNHEALTHY {
                
                let interval = (aqi_VERY_UNHEALTHY - aqi_UNHEALTHY)
                let mult = ((aqiEquiv - aqi_UNHEALTHY) * (H_DIFF))
                return CGFloat((H_MAX +  mult / interval))
                
            }
            if aqiEquiv > aqi_VERY_UNHEALTHY || aqiEquiv <= aqi_HAZARD {
                
                let interval = (aqi_HAZARD - aqi_VERY_UNHEALTHY)
                
                return CGFloat((H_MAX + ((aqiEquiv - aqi_VERY_UNHEALTHY) * (H_MIN - H_MAX)) / interval))
                
            }
            
            // Default case to return the maximum pollution color
            return CGFloat(H_MAX)
            
        })
    }
    
    // Use this for the pollution history
    convenience init(locations: [CLLocationCoordinate2D], readings: [WebPacket]) {
        // Initialize the superclass
        self.init(coordinates: locations, count: locations.count)
        
        // From the EPA's guide on how to calculate AQI:
        // https://airnowtest.epa.gov/sites/default/files/2018-05/aqi-technical-assistance-document-may2016.pdf
        // accessed 01/06/2019
        let aqi_HAZARD: Double = 301
        let aqi_VERY_UNHEALTHY: Double = 201
        let aqi_UNHEALTHY: Double = 151
        let aqi_USG: Double = 101
        let aqi_MODERATE: Double = 51
        let aqi_GOOD: Double = 50
        
        let H_MIN: Double = 0.33 // want a green color
        let H_MAX: Double = 0.01 // want a red color
        let H_DIFF: Double = H_MIN - H_MAX
        
        hues = readings.map( {
            let aqiEquiv: Double = Double($0.airQualityEstimate)
            
            // Select the hue based on the AQI value
            if aqiEquiv <= aqi_GOOD {
                print(H_MIN)
                return CGFloat(H_MIN)
            }
            // Weight the hue according to the AQI value
            if aqiEquiv > aqi_GOOD && aqiEquiv <= aqi_MODERATE {
                
                let interval = (aqi_MODERATE - aqi_GOOD)
                let mult = ((aqiEquiv - aqi_GOOD) * (H_DIFF))
                return CGFloat((H_MIN -  (mult / interval)))
                
            }
            
            if aqiEquiv > aqi_MODERATE && aqiEquiv <= aqi_USG {
                
                let interval = (aqi_USG - aqi_MODERATE)
                let mult = ((aqiEquiv - aqi_MODERATE) * (H_DIFF))
                return CGFloat((H_MIN -  (mult / interval)))
                
            }
            if aqiEquiv > aqi_USG && aqiEquiv <= aqi_UNHEALTHY {
                
                let interval = (aqi_UNHEALTHY - aqi_USG)
                let mult = ((aqiEquiv - aqi_USG) * (H_DIFF))
                return CGFloat((H_MIN -  (mult / interval)))
                
            }
            if aqiEquiv > aqi_UNHEALTHY && aqiEquiv <= aqi_VERY_UNHEALTHY {
                
                let interval = (aqi_VERY_UNHEALTHY - aqi_UNHEALTHY)
                let mult = ((aqiEquiv - aqi_UNHEALTHY) * (H_DIFF))
                return CGFloat((H_MIN -  (mult / interval)))
                
            }
            if aqiEquiv > aqi_VERY_UNHEALTHY && aqiEquiv <= aqi_HAZARD {
                
                let interval = (aqi_HAZARD - aqi_VERY_UNHEALTHY)
                let mult = (aqiEquiv - aqi_VERY_UNHEALTHY) * H_DIFF
                
                return CGFloat((H_MIN - (mult / interval)))
                
            }
            
            // Default case to return the maximum pollution color
            return CGFloat(H_MAX)
            
        })
    }
    
    
    
}
