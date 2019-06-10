//
//  ReadingPacket.swift
//  IoT_Respirator
//
//  Created by Alexander Luisi on 30/05/2019.
//  Copyright © 2019 Alexander Luisi. All rights reserved.
//

import Foundation
import MapKit

// MARK
// Used for the REST API project extension
// Want a lightweight version of the main structure since
// the AQI is the main source used for the map shading
struct WebPacket : Codable {
    
    let airQualityEstimate:Int
    let latitude: Double
    let longitude: Double
    let dateTaken: String
    
    init(aqi: Int, lat: Double, lng: Double) {
        self.airQualityEstimate = aqi
        self.latitude = lat
        self.longitude = lng
        // Get the current time and convert to string for the
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        self.dateTaken = formatter.string(from: Date())
    }
}

// The class to hold each of the readings from the board
struct ReadingPacket {
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
    var airQualityEstimate: Int?
    
}

extension ReadingPacket {
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
        
        self.particulateMatter2p5 = Float32(bitPattern: pm2p5) // Represent now as floating point number, using the bit pattern (in ug/m3)
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
        
        // Convert the relative values into ppm estimates
        let ppmCo = calculatePPMEquivalent(adcValue: self.carbonMonoxideRelative)
        let ppmNox = calculatePPMEquivalent(adcValue: self.nitrogenOxidesRelative)
        
        var aqiArray = [Int]()
        
        let coAQI = getAQIEquivalent(aqiType: "co", value: Double(ppmCo)) / 5
        aqiArray.append(coAQI)
        let noxAQI = getAQIEquivalent(aqiType: "nox", value: Double(ppmNox)) / 120
        aqiArray.append(noxAQI)
        let pm25AQI  = getAQIEquivalent(aqiType: "pm2.5", value: Double(self.particulateMatter2p5))
        aqiArray.append(pm25AQI)
        let pm10AQI = getAQIEquivalent(aqiType: "pm10", value: Double(self.particulateMatter10))
        aqiArray.append(pm10AQI)
        
        aqiArray.sort(by: >) // Sort in descending order to get the maximum value
        // This is the max value
        self.airQualityEstimate = aqiArray[0]

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
        
        if (latitudeFromFloat == 0) && (longitudeFromFloat == 0) {
            cllCoordinate = GlobalArrays.currentLocation
        }
        else {
            let point = CGPoint(x: latitudeFromFloat, y: longitudeFromFloat)
            cllCoordinate = CLLocationCoordinate2DMake(CLLocationDegrees(point.x), CLLocationDegrees(point.y))
        }
        
        return cllCoordinate
        
    }
    
    private func calculatePPMEquivalent(adcValue: Int32) -> Int {
        
        // From the MiCS calibration datasheet - THESE ARE AN ESTIMATE
        if adcValue <= 0 {
            return 0
        }
        
        let c1: Double = 1000
        let r1: Double = 50000
        let c2: Double = 3500
        let r2: Double = 40000
        
        let adcResolution: Double = 4095
        let gain: Double = 6
        let systemVoltage: Double = 3.3 // Voltage of the nRF52832 on the board
        // value is the ADC reading
        let boardResistor: Double = 10000
        
        let measuredVoltage = ((Double(adcValue) * systemVoltage) / adcResolution) * gain
        
        let rMeasured: Double = (boardResistor / measuredVoltage) - boardResistor
        
        let logC = log((c1/c2))
        let logR = log((r2/r1))
        let logRMeasured = log((rMeasured.magnitude/r1)) // force to be positive
        
        let intermediate = (logC * logR)/logRMeasured
        let x: Int = Int(c1 * pow(10, intermediate.magnitude)) / 200 // apply a scaling factor
        
        return abs(x)
    }
    
    
    // Get the equivalent AQI reading for each of the incoming values
    // Note that minute-by-minute values are not usable for a proper AQI measurement, hence 'equivalent'
    private func getAQIEquivalent(aqiType: String, value: Double) -> Int {
        
        switch aqiType {
        case "pm2.5":
            return getParticulate25AQI(value: value)
        case "pm10":
            return getParticulate10AQI(value: value)
        case "co":
            return getCarbonMonoxideAQI(value: value)
        case "nox":
            return getNitrousOxidesAQI(value: value)
        default:
            return 0
        }
        
    }
    
    // Calculate the AQI index to be used as an Equivalent AQI value
    
    private func getParticulate25AQI(value: Double) -> Int {
        
        if value >= 0 && value <= 12.0 {
            let index = Int((((50 - 0)/(12.0 - 0)) * (value - 0)) + 0)
            return index
        }
        if value >= 12.1 && value <= 35.4 {
            let index = Int((((100 - 51)/(35.4 - 12.1)) * (value - 12.1)) + 51)
            return index
        }
        if value >= 35.5 && value <= 55.4 {
            let index = Int((((150 - 101)/(55.4 - 35.5)) * (value - 35.5)) + 101)
            return index
        }
        if value >= 55.5 && value <= 150.4 {
            let index = Int((((200 - 151)/(150.4 - 55.5)) * (value - 55.5)) + 151)
            return index
        }
        if value >= 150.5 && value <= 250.4 {
            let index = Int((((300 - 201)/(250.4 - 150.5)) * (value - 150.5)) + 201)
            return index
        }
        if value >= 250.5 && value <= 350.4 {
            let index = Int((((400 - 301)/(350.4 - 250.5)) * (value - 250.5)) + 301)
            return index
        }
        if value >= 350.5 && value <= 500.4 {
            let index = Int((((500 - 401)/(500.4 - 350.5)) * (value - 350.5)) + 401)
            return index
        }
        
        return 0
        
    }
    
    private func getParticulate10AQI(value: Double) -> Int {
        
        if value >= 0 && value <= 54 {
            let index = Int((((50 - 0)/(54 - 0)) * (value - 0)) + 0)
            return index
        }
        if value >= 55 && value <= 154 {
            let index = Int((((100 - 51)/(154 - 55)) * (value - 55)) + 51)
            return index
        }
        if value >= 155 && value <= 254 {
            let index = Int((((150 - 101)/(254 - 155)) * (value - 155)) + 101)
            return index
        }
        if value >= 255 && value <= 354 {
            let index = Int((((200 - 151)/(354 - 255)) * (value - 255)) + 151)
            return index
        }
        if value >= 355 && value <= 424 {
            let index = Int((((300 - 201)/(424 - 355)) * (value - 355)) + 201)
            return index
        }
        if value >= 425 && value <= 504 {
            let index = Int((((400 - 301)/(504 - 425)) * (value - 425)) + 301)
            return index
        }
        if value >= 505 && value <= 604 {
            let index = Int((((500 - 401)/(604 - 505)) * (value - 505)) + 401)
            return index
        }
        
        return 0
        
    }
    
    private func getCarbonMonoxideAQI(value: Double) -> Int {
        
        if value >= 0 && value <= 4.4 {
            let index = Int((((50 - 0)/(4.4 - 0)) * (value - 0)) + 0)
            return index
        }
        if value >= 4.5 && value <= 9.4 {
            let index = Int((((100 - 51)/(9.4 - 4.5)) * (value - 4.5)) + 51)
            return index
        }
        if value >= 9.5 && value <= 12.4 {
            let index = Int((((150 - 101)/(12.4 - 9.5)) * (value - 9.5)) + 101)
            return index
        }
        if value >= 12.5 && value <= 15.4 {
            let index = Int((((200 - 151)/(15.4 - 12.5)) * (value - 12.5)) + 151)
            return index
        }
        if value >= 15.5 && value <= 30.4 {
            let index = Int((((300 - 201)/(30.4 - 15.5)) * (value - 15.5)) + 201)
            return index
        }
        if value >= 30.5 && value <= 40.4 {
            let index = Int((((400 - 301)/(40.4 - 30.5)) * (value - 30.5)) + 301)
            return index
        }
        if value >= 40.5 && value <= 50.4 {
            let index = Int((((500 - 401)/(50.4 - 40.5)) * (value - 50.4)) + 401)
            return index
        }
        
        return 0
        
    }
    
    // These values are estimates and are not based on scientific fact,
    // Nor are they based on the AQI Technical Recommendations Document
    private func getNitrousOxidesAQI(value: Double) -> Int {
        
        if value >= 0 && value <= 0.5 {
            let index = Int((((50 - 0)/(0.5 - 0)) * (value - 0)) + 0)
            return index
        }
        if value >= 0.6 && value <= 1.5 {
            let index = Int((((100 - 51)/(1.5 - 0.6)) * (value - 0.6)) + 51)
            return index
        }
        if value >= 1.6 && value <= 2.5 {
            let index = Int((((150 - 101)/(2.5 - 1.6)) * (value - 1.6)) + 101)
            return index
        }
        if value >= 2.6 && value <= 3.5 {
            let index = Int((((200 - 151)/(3.5 - 2.6)) * (value - 2.6)) + 151)
            return index
        }
        if value >= 3.6 && value <= 4.5 {
            let index = Int((((300 - 201)/(4.5 - 3.6)) * (value - 3.6)) + 201)
            return index
        }
        if value >= 4.6 && value <= 5.0 {
            let index = Int((((400 - 301)/(5.0 - 4.6)) * (value - 4.6)) + 301)
            return index
        }
        if value >= 5.1 {
            let index = 500
            return index
        }
        
        return 0
        
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

