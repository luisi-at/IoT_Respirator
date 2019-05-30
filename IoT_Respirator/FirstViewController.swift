//
//  FirstViewController.swift
//  IoT_Respirator
//
//  Created by Alexander Luisi on 29/05/2019.
//  Copyright © 2019 Alexander Luisi. All rights reserved.
//

import UIKit
import NotificationCenter


class FirstViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        // Load in the BLE manager on the first view to be shared across the other two
        BluetoothManager.shared.setup()
        // Register a notification so that the data can be retrieved from the BLE methods
        NotificationCenter.default.addObserver(self, selector: #selector(onUartReceived(_:)), name: .didReceiveUartString, object: nil)
    }

    @objc func onUartReceived(_ notification: Notification)
    {
        print("UART Recieved via notification \n")
        guard let rxString = notification.userInfo?["uart"] as? String else { return }
        
        print("\(rxString) \n")
        
    }
    
}

extension Notification.Name
{
    static let didReceiveUartString = Notification.Name("didReceiveUartString")
}


