//
//  ThirdViewController.swift
//  IoT_Respirator
//
//  Created by Alexander Luisi on 29/05/2019.
//  Copyright © 2019 Alexander Luisi. All rights reserved.
//

import UIKit
import NotificationCenter

class ThirdViewController: UIViewController {

    @IBOutlet weak var textView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        NotificationCenter.default.addObserver(self, selector: #selector(updateTextView(_:)), name: .didReceiveJSONString, object: nil)
        
        textView.text = "Packet Debug: \n\n"
        
    }
    
    
    
    @objc func updateTextView(_ notification: Notification) {
        guard let debugString = notification.userInfo?["json"] as? String else { return }
        
        let index = GlobalArrays.globalData.endIndex - 1
        let roundedTime: String = String(format: "%.2f", GlobalArrays.globalData[index].timeReceived)
        textView.text +=  "Time Elapsed: " + roundedTime + "\n JSON: " + debugString + "\n\n"
        
        let range = NSMakeRange(textView.text.count - 1, 1)
        textView.scrollRangeToVisible(range)
        
    }

}

extension Notification.Name {
    static let didReceiveJSONString = Notification.Name("didReceiveJSONString")
}
