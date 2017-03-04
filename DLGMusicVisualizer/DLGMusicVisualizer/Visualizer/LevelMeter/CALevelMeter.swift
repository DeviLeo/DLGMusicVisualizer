//
//  CALevelMeter.swift
//  DLGMusicVisualizer
//
//  Created by Liu Junqi on 03/03/2017.
//  Copyright © 2017 DeviLeo. All rights reserved.
//

import UIKit
import AudioToolbox
import AVFoundation

class CALevelMeter: BaseVisualizer {

    static let kPeakFalloffPerSec: Double = 0.7
    static let kLevelFalloffPerSec: Double = 0.8
    
    var subLevelMeters: Array<LevelMeter>?
    var showsPeaks: Bool = true
    var peakFalloffLastFire: CFAbsoluteTime = 0
    
    override func layoutVisualizer() {
        self.layoutSubLevelMeters()
    }
    
    func layoutSubLevelMeters() {
        if self.subLevelMeters != nil {
            for meter in self.subLevelMeters! {
                meter.removeFromSuperview()
            }
            self.subLevelMeters = nil
        }
        
        var meters: Array<LevelMeter> = Array.init()
        var totalRect: CGRect = .zero
        if self.vertical {
            totalRect = CGRect.init(x: 0, y: 0, width: self.frame.size.width + 2, height: self.frame.size.height)
        } else {
            totalRect = CGRect.init(x: 0, y: 0, width: self.frame.size.width, height: self.frame.size.height + 2)
        }
        
        let count = self.channelNumbers.count
        for i in 0 ..< count {
            var r: CGRect = .zero
            if self.vertical {
                let x: CGFloat = totalRect.origin.x + (CGFloat(i) / CGFloat(count)) * totalRect.size.width
                let y: CGFloat = totalRect.origin.y
                let w: CGFloat = (1.0 / CGFloat(count)) * totalRect.size.width - 2.0
                let h: CGFloat = totalRect.size.height
                r = CGRect.init(x: x, y: y, width: w, height: h)
            } else {
                let x: CGFloat = totalRect.origin.x
                let y: CGFloat = totalRect.origin.y + (CGFloat(i) / CGFloat(count)) * totalRect.size.height
                let w: CGFloat = totalRect.size.width
                let h: CGFloat = (1.0 / CGFloat(count)) * totalRect.size.height - 2.0
                r = CGRect.init(x: x, y: y, width: w, height: h)
            }
            let meter: LevelMeter = self.useGL ? GLLevelMeter.init(frame: r) : LevelMeter.init(frame: r)
            meter.numLights = 30
            meter.vertical = self.vertical
            meters.append(meter)
            self.addSubview(meter)
        }
        
        self.subLevelMeters = meters
    }

    override func refresh() {
        var success: Bool = false
        
        // if we have no queue, but still have levels, gradually bring them down
        if self.player == nil {
            var maxLevel: CGFloat = -1.0
            let thisFire: CFAbsoluteTime = CFAbsoluteTimeGetCurrent()
            let timePass: CFAbsoluteTime = thisFire - self.peakFalloffLastFire
            for meter in self.subLevelMeters! {
                var newPeak: CGFloat = 0
                var newLevel: CGFloat = CGFloat(CFAbsoluteTime(meter.level) - timePass * CFAbsoluteTime(CALevelMeter.kLevelFalloffPerSec))
                if newLevel < 0 { newLevel = 0 }
                meter.level = newLevel
                if self.showsPeaks == true {
                    newPeak = CGFloat(CFAbsoluteTime(meter.peakLevel) - timePass * CFAbsoluteTime(CALevelMeter.kPeakFalloffPerSec))
                    if newPeak < 0 { newPeak = 0 }
                    meter.peakLevel = newPeak
                    if newPeak > maxLevel { maxLevel = newPeak }
                } else if newLevel > maxLevel {
                    maxLevel = newLevel
                }
                meter.setNeedsDisplay()
            }
            
            // stop the timer when the last level has hit 0
            if maxLevel <= 0 {
                self.updateTimer?.invalidate()
                self.updateTimer = nil
            }
            
            self.peakFalloffLastFire = thisFire
            success = true
        } else {
            self.player?.updateMeters()
            let count = self.channelNumbers.count
            for i in 0 ..< count {
                let channelIndex = self.channelNumbers[i]
                let channelView = self.subLevelMeters?[channelIndex]
                
                if channelIndex >= count { break }
                if channelIndex > 127 { break }
                
                let avgpwr = Double((self.player?.averagePower(forChannel: i))!)
                channelView?.level = CGFloat(self.meterTable.valueAt(in: avgpwr))
                if self.showsPeaks == true {
                    let peakpwr = Double((self.player?.peakPower(forChannel: i))!)
                    channelView?.peakLevel = CGFloat(self.meterTable.valueAt(in: peakpwr))
                } else {
                    channelView?.peakLevel = 0
                }
                channelView?.setNeedsDisplay()
                success = true
            }
        }
        
        if success == false {
            for meter in self.subLevelMeters! {
                meter.setNeedsDisplay()
            }
            print("ERROR: metering failed")
        }
    }
    
    override func setPlayer(player: AVAudioPlayer?) {
        super.setPlayer(player: player)
        if self.player != nil && player == nil {
            self.peakFalloffLastFire = CFAbsoluteTimeGetCurrent()
        }
        
        self.player = player
        if player == nil {
            for meter in self.subLevelMeters! {
                meter.setNeedsDisplay()
            }
        }
    }
}
