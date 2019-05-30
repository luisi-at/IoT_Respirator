//
//  BLEPeripheral.swift
//  IoT_Respirator
//
//  Created by Alexander Luisi on 29/05/2019.
//  Copyright © 2019 Alexander Luisi. All rights reserved.
//

import Foundation
import CoreBluetooth

class PeripheralManager: NSObject
{
    private var peripheralManager: CBCentralManager!
    
    override init()
    {
        super.init()
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
    }
}

extension PeripheralManager: CBPeripheralDelegate
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
            print("Tx Char \r\n")
            let received = uartString(from: characteristic)
            print(received)
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
