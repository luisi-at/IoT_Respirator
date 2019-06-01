//
//  ReadingPacket.swift
//  IoT_Respirator
//
//  Created by Alexander Luisi on 30/05/2019.
//  Copyright © 2019 Alexander Luisi. All rights reserved.
//

import Foundation
import MapKit

// The class to hold each of the readings from the board
struct ReadingPacket
{
    var ethanolRelative: UInt16
    var hydrogenRelative: UInt16
    var totalVOC: UInt16
    var carbonDioxideRelative: UInt16
    var carbonMonoxideRelative: Int32
    var nitrogenOxidesRelative: Int32
    var particulateMatter2p5: Float32
    var particulateMatter10: Float32
    var location: (latitude: Float32, longitude: Float32)
    var timeReceived: Double // to show progression over the graph, gives the x axis
    var originalJSON: String // required,
    var mapKitCoordinate: CLLocationCoordinate2D? // this optional upon instance creation
    
}

extension ReadingPacket{
    init?(json: [String: Any], jsonString: String){
        guard let gasReadingsJSON = json["GASR"] as? [String: UInt16],
            let eth = gasReadingsJSON["ETRV"],
            let hyd = gasReadingsJSON["H2RV"],
            let tvoc = gasReadingsJSON["TVOC"],
            let co2 = gasReadingsJSON["CO2V"],
            let co = gasReadingsJSON["CORV"],
            let nox = gasReadingsJSON["NORV"],
            
            let particulateReadingsJSON = json["PMRS"] as? [String: UInt32],
            let pm2p5 = particulateReadingsJSON["PM25"],
            let pm10 = particulateReadingsJSON["PM10"],
            
            let positionReadingsJSON = json["POSN"] as? [String: UInt32],
            let latVal = positionReadingsJSON["LATV"],
            let latScale = positionReadingsJSON["LATS"],
            let longVal = positionReadingsJSON["LNGV"],
            let longScale = positionReadingsJSON["LNGS"]
            
            
        else{
            return nil
        }
        
        self.ethanolRelative = eth
        self.hydrogenRelative = hyd
        self.totalVOC = tvoc
        self.carbonDioxideRelative = co2
        self.carbonMonoxideRelative = Int32(co)
        self.nitrogenOxidesRelative = Int32(nox)
        
        self.particulateMatter2p5 = Float32(bitPattern: pm2p5) // Represent now as floating point number, using the bit pattern
        self.particulateMatter10 = Float32(bitPattern: pm10)
        
        self.timeReceived =  Date().timeIntervalSince(GlobalArrays.startTime) // Timestamp the reading from when the recording started
        
        self.originalJSON = jsonString
        
        self.location = (0,0)
        let lat = convertToCoordinate(unsignedValue: latVal, unsignedScale: latScale)
        let long = convertToCoordinate(unsignedValue: longVal, unsignedScale: longScale)
        let coords = (lat, long)
        self.location = coords
        // Assign the mapkit coordinate to prevent duplicate processing
        self.mapKitCoordinate = returnCLLocationCoordinate(lat: lat, long: long)
        
    }
    
    private func convertToCoordinate(unsignedValue: UInt32, unsignedScale: UInt32) -> Float32{
        
        let degrees = (Int32)(unsignedValue / (unsignedScale * 100))
        let minutes = (Int32)(unsignedValue % (unsignedScale * 100))
        
        let scaling = (Float32)(60 * unsignedScale)
        let intermediate = ((Float32)(degrees) + (Float)(minutes) / scaling)
        let coord = (Float32)(intermediate) // split to help with compile-time
        
        return coord
    }
    
    private func returnCLLocationCoordinate(lat: Float32, long: Float32) -> CLLocationCoordinate2D {
        
        let latitudeFromFloat = Double(lat)
        let longitudeFromFloat = Double(long)
        
        var cllCoordinate: CLLocationCoordinate2D
        
        if (latitudeFromFloat != 0) && (longitudeFromFloat != 0) {
            cllCoordinate = GlobalArrays.currentLocation
        }
        else {
            let point = CGPoint(x: latitudeFromFloat, y: longitudeFromFloat)
            cllCoordinate = CLLocationCoordinate2DMake(CLLocationDegrees(point.x), CLLocationDegrees(point.y))
        }
        
        return cllCoordinate
        
    }
    
}

/*
 init(_ incomingJSONString: String)
 {
 originalJSON = incomingJSONString
 let data = originalJSON.data(using: .ascii)! // convert the JSON string to data in pure ASCII (unsigned char)
 guard let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else
 {
 return
 }
 
 // Deserialize the JSON packet during the init
 let name = json["ETRV"] as? String
 
 
 }
*/

