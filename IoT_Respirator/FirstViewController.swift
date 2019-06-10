//
//  FirstViewController.swift
//  IoT_Respirator
//
//  Created by Alexander Luisi on 29/05/2019.
//  Copyright © 2019 Alexander Luisi. All rights reserved.
//

import UIKit
import NotificationCenter
import Charts
import CoreLocation

struct GlobalArrays
{
    static var globalData: [ReadingPacket] = []
    static var startTime: Date!
    static var currentLocation: CLLocationCoordinate2D!
    static var webData: [WebPacket] = []
}

class FirstViewController: UIViewController, CLLocationManagerDelegate {
    
    let locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        // Load in the BLE manager on the first view to be shared across the other two
        BluetoothManager.shared.setup()
        
        // Request the current position of the user for backup
        // (Probably should be in another place in the code, but it'll work
        locationManager.requestAlwaysAuthorization()
        locationManager.requestWhenInUseAuthorization()
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
        }
        
        // Register a notification so that the data can be retrieved from the BLE methods
        NotificationCenter.default.addObserver(self, selector: #selector(onUartReceived(_:)), name: .didReceiveUartString, object: nil)
        GlobalArrays.startTime = Date() // TODO change this when the 'start' button is pressed
    }
    
    @IBOutlet weak var chartView: LineChartView!
    @IBOutlet weak var vocChartView: LineChartView!
    @IBOutlet weak var co2ChartView: LineChartView!
    @IBOutlet weak var noxcoChartView: LineChartView!
    @IBOutlet weak var rawVOCChartView: LineChartView!
    
    @objc func onUartReceived(_ notification: Notification)
    {
        print("UART Recieved via notification \n")
        guard let rxString = notification.userInfo?["uart"] as? String else { return }
        //print(rxString)
        
        // Deserialize the JSON here and add to the global array
        //let data = rxString.data(using: .ascii)! // convert the JSON string to data in pure ASCII (unsigned char)
        let trimmedString = rxString.replacingOccurrences(of: "\0", with: "")
        
        let data = trimmedString.data(using: .ascii)!
        //let tempString = String(data: data, encoding: .ascii)!
        //print(tempString)
        do {
            if let jsonContainer = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                let addition = ReadingPacket(json: jsonContainer, jsonString: rxString)
                GlobalArrays.globalData.append(addition!)
                
                // Probably a better way to do this without Notifications to avoid resource contention, but I'm going with what I know
                NotificationCenter.default.post(name: .didUpdateGlobalArray, object: nil, userInfo: nil) // Notify the other view data is available
                
                // Create the packet to push to the web API
                let webAddition = WebPacket(aqi: (addition?.airQualityEstimate)!, lat: Double((addition?.mapKitCoordinate!.latitude)!),
                                            lng: Double((addition?.mapKitCoordinate!.longitude)!))
                GlobalArrays.webData.append(webAddition)
                
                // Push the data to the server
                postData(packet: webAddition)
                
                self.updateParticulates()
                self.updateTotalVOCs()
                self.updateCO2()
                self.updateRawCoNox()
                self.updateRawVOC()
                print("Estimated AQI Value: \(String(describing: addition?.airQualityEstimate))")
                NotificationCenter.default.post(name: .didReceiveJSONString, object: nil, userInfo: ["json": trimmedString])
                
            }
        } catch let error {
            print(error.localizedDescription)
        }
        
    }
    
    // Get the current location of the user for use if the GPS drops/fails
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let locationValue: CLLocationCoordinate2D = manager.location?.coordinate else { return }
        GlobalArrays.currentLocation = locationValue
    }
    
    // POST the data to the webserver
    func postData(packet: WebPacket) {
        // Make an encoder
        let jsonEncoder = JSONEncoder()
        do {
            let jsonData = try jsonEncoder.encode(packet)
            let jsonString = String(data: jsonData, encoding: .utf8)
            print(jsonString!)
            // Make the http POST request here
            
            var urlComponents = URLComponents()
            urlComponents.scheme = "http"
            urlComponents.host = "192.168.1.206" // This only works on the local network! Will need to change to the AWS instance when 'on the move'
            urlComponents.port = 5000
            urlComponents.path = "/data"
            let url = urlComponents.url!
            // Make this URL a request
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            // Set the content type otherwise the API won't be able to accept it
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            // Insert the request into the body
            request.httpBody = jsonData
            
            // POST the data and look at the reponse
            let task = URLSession.shared.dataTask(with: request) { (data, response, error ) in
                // Really just need to post here
                // Let the other view handle any issues
                if let error = error {
                    print(error)
                }
            }
            task.resume()
            
        }
        catch let error {
            print(error.localizedDescription)
        }
        
        
    }
    
    
    // Update the charts
    private func updateParticulates(){
        var pm25 = [ChartDataEntry]()
        var pm10 = [ChartDataEntry]()
        
        // Plot the pm2.5 and pm10 data in the chart
        for i in 0..<GlobalArrays.globalData.count {
            let value1 = ChartDataEntry(x: GlobalArrays.globalData[i].timeReceived, y: Double(GlobalArrays.globalData[i].particulateMatter2p5))
            pm25.append(value1)
            let value2 = ChartDataEntry(x: GlobalArrays.globalData[i].timeReceived, y: Double(GlobalArrays.globalData[i].particulateMatter10))
            pm10.append(value2)
        }
        
        // Form the data into a data set
        let pm25Line = LineChartDataSet(entries: pm25, label: "PM2.5 in ug/m^3")
        let pm10Line = LineChartDataSet(entries: pm10, label: "PM10 in ug/m^3")
        pm25Line.colors = [UIColor.blue]
        pm10Line.colors = [UIColor.red]
        
        // Disable the circles
        pm25Line.drawCirclesEnabled = false
        pm10Line.drawCirclesEnabled = false
        
        let data = LineChartData()
        data.addDataSet(pm25Line)
        data.addDataSet(pm10Line)
        
        data.setDrawValues(false)
        
        chartView.data = data
        chartView.xAxis.labelPosition = .bottom
        chartView.rightAxis.enabled = false
        
        chartView.chartDescription?.text = "Particulate Concentration"

    }
    
    private func updateTotalVOCs(){
        var tvoc = [ChartDataEntry]()
        
        // Plot the pm2.5 and pm10 data in the chart
        for i in 0..<GlobalArrays.globalData.count {
            let value1 = ChartDataEntry(x: GlobalArrays.globalData[i].timeReceived, y: Double(GlobalArrays.globalData[i].totalVOC))
            tvoc.append(value1)
            
        }
        
        // Form the data into a data set
        let tvocLine = LineChartDataSet(entries: tvoc, label: "Total VOC ppb")
        tvocLine.colors = [UIColor.blue]
        
        // Disable the circles
        tvocLine.drawCirclesEnabled = false
        
        let data = LineChartData()
        data.addDataSet(tvocLine)
        
        data.setDrawValues(false)
        
        vocChartView.data = data
        vocChartView.xAxis.labelPosition = .bottom
        vocChartView.rightAxis.enabled = false
        
        vocChartView.chartDescription?.text = "Total VOC Concentration"
        
    }
    
    private func updateCO2(){
        var co2 = [ChartDataEntry]()
        
        // Plot the pm2.5 and pm10 data in the chart
        for i in 0..<GlobalArrays.globalData.count {
            let value1 = ChartDataEntry(x: GlobalArrays.globalData[i].timeReceived, y: Double(GlobalArrays.globalData[i].carbonDioxideRelative))
            co2.append(value1)
            
        }
        
        // Form the data into a data set
        let co2Line = LineChartDataSet(entries: co2, label: "Total CO2 ppm")
        co2Line.colors = [UIColor.blue]
        
        // Disable the circles
        co2Line.drawCirclesEnabled = false
        
        let data = LineChartData()
        data.addDataSet(co2Line)
        
        data.setDrawValues(false)
        
        co2ChartView.data = data
        co2ChartView.xAxis.labelPosition = .bottom
        co2ChartView.rightAxis.enabled = false
        
        co2ChartView.chartDescription?.text = "Equivalent CO2 Concentration"
        
    }
    
    // Update CO/NOx here
    
    private func updateRawVOC(){
        var eth = [ChartDataEntry]()
        var h2 = [ChartDataEntry]()
        
        // Plot the pm2.5 and pm10 data in the chart
        for i in 0..<GlobalArrays.globalData.count {
            let value1 = ChartDataEntry(x: GlobalArrays.globalData[i].timeReceived, y: Double(GlobalArrays.globalData[i].ethanolRelative))
            eth.append(value1)
            let value2 = ChartDataEntry(x: GlobalArrays.globalData[i].timeReceived, y: Double(GlobalArrays.globalData[i].hydrogenRelative))
            h2.append(value2)
        }
        
        // Form the data into a data set
        let ethLine = LineChartDataSet(entries: eth, label: "Raw Ethanol Value")
        let h2Line = LineChartDataSet(entries: h2, label: "Raw Hydrogen Value")
        ethLine.colors = [UIColor.blue]
        h2Line.colors = [UIColor.red]
        
        // Disable the circles
        ethLine.drawCirclesEnabled = false
        h2Line.drawCirclesEnabled = false
        
        let data = LineChartData()
        data.addDataSet(ethLine)
        data.addDataSet(h2Line)
        
        data.setDrawValues(false)
        
        rawVOCChartView.data = data
        rawVOCChartView.xAxis.labelPosition = .bottom
        rawVOCChartView.rightAxis.enabled = false
        
        rawVOCChartView.chartDescription?.text = "Particulate Concentration"
        
    }
    
    private func updateRawCoNox(){
        var co = [ChartDataEntry]()
        var nox = [ChartDataEntry]()
        
        // Plot the pm2.5 and pm10 data in the chart
        for i in 0..<GlobalArrays.globalData.count {
            let value1 = ChartDataEntry(x: GlobalArrays.globalData[i].timeReceived, y: Double(GlobalArrays.globalData[i].carbonMonoxideRelative))
            co.append(value1)
            let value2 = ChartDataEntry(x: GlobalArrays.globalData[i].timeReceived, y: Double(GlobalArrays.globalData[i].nitrogenOxidesRelative))
            nox.append(value2)
        }
        
        // Form the data into a data set
        let coLine = LineChartDataSet(entries: co, label: "Carbon Monoxide ADC Value")
        let noxLine = LineChartDataSet(entries: nox, label: "Nitrogen Oxides ADC Value")
        coLine.colors = [UIColor.blue]
        noxLine.colors = [UIColor.red]
        
        // Disable the circles
        coLine.drawCirclesEnabled = false
        noxLine.drawCirclesEnabled = false
        
        let data = LineChartData()
        data.addDataSet(coLine)
        data.addDataSet(noxLine)
        
        data.setDrawValues(false)
        
        noxcoChartView.data = data
        noxcoChartView.xAxis.labelPosition = .bottom
        noxcoChartView.rightAxis.enabled = false
        
        noxcoChartView.chartDescription?.text = "Raw Carbon Monoxide and Nitrogen Oxides"
        
    }
    
}

extension Notification.Name
{
    static let didReceiveUartString = Notification.Name("didReceiveUartString")
}



