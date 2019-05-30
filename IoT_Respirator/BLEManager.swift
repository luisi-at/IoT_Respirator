//
//  BLEManager.swift
//  IoT_Respirator
//
//  Created by Alexander Luisi on 29/05/2019.
//  Copyright © 2019 Alexander Luisi. All rights reserved.
//

import Foundation
import CoreBluetooth

let nrfuartCBUUID = CBUUID(string: "6E400001-B5A3-F393-E0A9-E50E24DCCA9E")    // UART Service
let nrfuartTxCBUUID = CBUUID(string: "6E400003-B5A3-F393-E0A9-E50E24DCCA9E")  // UART TX Characteristic
let nrfuartRxCBUUID = CBUUID(string: "6E400002-B5A3-F393-E0A9-E50E24DCCA9E")  // UART RX Characteristic

class BluetoothManager : NSObject
{
    static let shared = BluetoothManager()
    private var centralManager: CentralManager!
    
    var deviceCharacteristic: [CBPeripheral: CBCharacteristic] = [:]
    var connectedPeripherals: [CBPeripheral] { return centralManager.peripherals }
    
    
    func setup()
    {
        centralManager = CentralManager()
    }
    
}
