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

struct GlobalArrays
{
    static var globalData: [ReadingPacket] = []
    static var startTime: Date!
}

class FirstViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        // Load in the BLE manager on the first view to be shared across the other two
        BluetoothManager.shared.setup()
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
        let tempString = String(data: data, encoding: .ascii)!
        print(tempString)
        do {
            if let jsonContainer = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                let addition = ReadingPacket(json: jsonContainer, jsonString: rxString)
                GlobalArrays.globalData.append(addition!)
                // Probably a better way to do this without Notifications to avoid resource contention, but I'm going with what I know
                NotificationCenter.default.post(name: .didUpdateGlobalArray, object: nil, userInfo: nil) // Notify the other view data is available
                self.updateParticulates()
                self.updateTotalVOCs()
                self.updateCO2()
                // update NOx and CO
                self.updateRawVOC()
            }
        } catch let error {
            print(error.localizedDescription)
        }
        
        //let jsonContainer = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
        //let addition = ReadingPacket(json: jsonContainer, jsonString: rxString)
        
        // Add the latest data to the array
        //GlobalArrays.globalData.append(addition!)
        //self.updateChart()
        
    }
    
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
        let co2Line = LineChartDataSet(entries: co2, label: "Total VOC ppb")
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
        let ethLine = LineChartDataSet(entries: eth, label: "PM2.5 in ug/m^3")
        let h2Line = LineChartDataSet(entries: h2, label: "PM10 in ug/m^3")
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
    
}

extension Notification.Name
{
    static let didReceiveUartString = Notification.Name("didReceiveUartString")
    static let didUpdateGlobalArray = Notification.Name("didUpdateGlobalArray")
}



