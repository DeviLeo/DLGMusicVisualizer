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

class CALevelMeter: UIView {

    static let kPeakFalloffPerSec: Double = 0.7
    static let kLevelFalloffPerSec: Double = 0.8
    static let kMinDBvalue: Double = -80.0
    
    var player: AVAudioPlayer?
    var channelNumbers: Array<Int> = [0]
    var subLevelMeters: Array<LevelMeter>?
    var meterTable: MeterTable = MeterTable.init(minDecibels: CALevelMeter.kMinDBvalue)
    var updateTimer: CADisplayLink?
    var showsPeaks: Bool = true
    var vertical: Bool = false
    var userGL: Bool = false
    var peakFalloffLastFire: CFAbsoluteTime = 0
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.vertical = frame.size.width < frame.size.height
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.vertical = self.frame.size.width < self.frame.size.height
    }
    
    func registerNotifications() {
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(self.stopTimer), name: .UIApplicationWillResignActive, object: nil)
        nc.addObserver(self, selector: #selector(self.startTimer), name: .UIApplicationWillEnterForeground, object: nil)
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
            let meter: LevelMeter = LevelMeter.init(frame: r)
            meter.numLights = 30
            meter.vertical = self.vertical
            meters.append(meter)
            self.addSubview(meter)
        }
        
        self.subLevelMeters = meters
    }

    func refresh() {
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
    
    func setPlayer(player: AVAudioPlayer?) {
        if self.player == nil && player != nil {
            if self.updateTimer != nil {
                self.updateTimer?.invalidate()
            }
            self.updateTimer = CADisplayLink.init(target: self, selector: #selector(self.refresh))
            self.updateTimer?.add(to: RunLoop.current, forMode: .defaultRunLoopMode)
        } else if self.player != nil && player == nil {
            self.peakFalloffLastFire = CFAbsoluteTimeGetCurrent()
        }
        
        self.player = player
        
        if self.player != nil {
            self.player?.isMeteringEnabled = true
            let channelCount = (self.player?.numberOfChannels)!
            if self.player?.numberOfChannels != self.channelNumbers.count {
                var channels: Array<Int> = Array.init()
                for i in 0 ..< channelCount {
                    channels.append(i)
                }
                self.setChannels(channels: channels)
            }
        } else {
            for meter in self.subLevelMeters! {
                meter.setNeedsDisplay()
            }
        }
    }
    
    func setChannels(channels: Array<Int>) {
        self.channelNumbers = channels
        self.layoutSubLevelMeters()
    }
    
    @objc func startTimer() {
        if self.player != nil {
            self.updateTimer = CADisplayLink.init(target: self, selector: #selector(self.refresh))
            self.updateTimer?.add(to: RunLoop.current, forMode: .defaultRunLoopMode)
        }
    }
    
    @objc func stopTimer() {
        self.updateTimer?.invalidate()
        self.updateTimer = nil
    }
}
