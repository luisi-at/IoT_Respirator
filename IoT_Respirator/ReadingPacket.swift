//
//  ReadingPacket.swift
//  IoT_Respirator
//
//  Created by Alexander Luisi on 30/05/2019.
//  Copyright © 2019 Alexander Luisi. All rights reserved.
//

import Foundation

// The class to hold each of the readings from the 
class ReadingPacket
{
    var ethanolRelative: UInt16?
    var hydrogenRelative: UInt16?
    var totalVOC: UInt16?
    var carbonDioxideRelative: UInt16?
    var carbonMonoxideRelative: Int16?
    var nitrogenOxidesRelative: Int16?
    var particlulateMatter2p5: Float32?
    var particulateMatter10: Float32?
    var latitude: Double?
    var longitude: Double?
}
