//
//  MeterTable.swift
//  DLGMusicVisualizer
//
//  Created by Liu Junqi on 03/03/2017.
//  Copyright © 2017 DeviLeo. All rights reserved.
//

import UIKit

class MeterTable: NSObject {
    
    var minDecibels: Double
    var decibelResolution: Double
    var scaleFactor: Double
    var table: Array<Double> = Array.init()
    
    override convenience init() {
        self.init(minDecibels: -80, tableSize: 400, root: 2.0)
    }
    
    convenience init(minDecibels: Double) {
        self.init(minDecibels: minDecibels, tableSize: 400, root: 2.0)
    }
    
    init(minDecibels: Double, tableSize: Int, root: Double) {
        self.minDecibels = minDecibels
        self.decibelResolution = minDecibels / Double(tableSize - 1)
        self.scaleFactor = 1.0 / self.decibelResolution
        if (minDecibels >= 0.0) {
            print("MeterTable minDecibels must be negative")
            return
        }
        let minAmp: Double = pow(10.0, 0.05 * minDecibels)
        let ampRange: Double = 1.0 - minAmp
        let invAmpRange: Double = 1.0 / ampRange
        
        let rroot: Double = 1.0 / Double(root)
        for i in 0 ..< tableSize {
            let decibels: Double = Double(i) * self.decibelResolution
            let amp: Double = pow(10.0, 0.05 * decibels)
            let adjAmp = (amp - minAmp) * invAmpRange
            let meter = pow(adjAmp, rroot)
            self.table.append(meter)
        }
    }
    
    func valueAt(in decibels: Double) -> Double {
        if decibels < self.minDecibels { return 0.0 }
        if decibels >= 0.0 { return 1.0 }
        let index = Int(decibels * self.scaleFactor)
        return self.table[index]
    }
}
