//
//  BLEPeripheral.swift
//  IoT_Respirator
//
//  Created by Alexander Luisi on 29/05/2019.
//  Copyright © 2019 Alexander Luisi. All rights reserved.
//

import Foundation
import CoreBluetooth
import NotificationCenter // not the most ideal way of publishing/subscribing data

class CentralManager: NSObject
{
    private var centralManager: CBCentralManager!
    var peripherals: [CBPeripheral] = []
    var uartPeripheral: CBPeripheral!
    
    
    
    override init()
    {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: DispatchQueue.main)
    }
}

extension CentralManager: CBCentralManagerDelegate
{
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state
        {
        case .unknown:
            print("Unknown state")
        case .resetting:
            print("Resetting state")
        case .unsupported:
            print("Unsupported state")
        case .unauthorized:
            print("Unauthorized state")
        case .poweredOff:
            print("Powered off state")
        case .poweredOn:
            // Search for peripherals if the Bluetooth is powered on
            centralManager.scanForPeripherals(withServices: [nrfuartCBUUID])
        default:
            print("Catch all state")
            
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        // Diverges from the tutorial, uses Nordic's BLE UART service UUID
        uartPeripheral = peripheral;
        uartPeripheral.delegate = self // Point to own delegate
        centralManager.stopScan()
        centralManager.connect(uartPeripheral) // Connect to the nRF52
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected")
        
        uartPeripheral.discoverServices(nil) // Look at the services that the nRF52 firmware provides
    }
}

extension CentralManager: CBPeripheralDelegate
{
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        
        guard let services = peripheral.services else { return }
        for service in services{
            print(service) // print the services provides by the nRF52 firmware to the console
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else {return}
        
        for characteristic in characteristics
        {
            print(characteristic) // print the characteristics provides by the nRF52 firmware to the console
            if characteristic.properties.contains(.read)
            {
                print("\(characteristic.uuid): properties contains .read")
                peripheral.readValue(for: characteristic)
            }
            if characteristic.properties.contains(.notify)
            {
                print("\(characteristic.uuid): properties contains .notify")
                peripheral.setNotifyValue(true, for: characteristic)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        switch characteristic.uuid
        {
        case nrfuartRxCBUUID:
            print(characteristic.value ?? "no value") // Print the JSON string from the to the console
        case nrfuartTxCBUUID:
            //print("Tx Char \r\n")
            let received = uartString(from: characteristic)
            //print(received)
            let userInfo = ["uart": received]
            // Raise a notification that the string has arrived
            NotificationCenter.default.post(name: .didReceiveUartString, object: nil, userInfo: userInfo)
            
            
        default:
            print("Unhandled Characteristic UUID: \(characteristic.uuid)")
        }
    }
    
    private func uartString(from characteristic: CBCharacteristic) -> String
    {
        guard let characteristicData = characteristic.value else { return "ERROR" }
        
        let byteArray = [UInt8](characteristicData)
        let chars = byteArray.map{ Character(UnicodeScalar($0)) }
        
        return String(Array(chars))
        
    }
}
