//
//  BaseVisualizer.swift
//  DLGMusicVisualizer
//
//  Created by DeviLeo on 2017/3/4.
//  Copyright © 2017年 DeviLeo. All rights reserved.
//

import UIKit
import AudioToolbox
import AVFoundation

class BaseVisualizer: UIView {
    
    var player: AVAudioPlayer?
    var channelNumbers: Array<Int> = [0]
    var meterTable: MeterTable = MeterTable.init(minDecibels: -80.0)
    var updateTimer: CADisplayLink?
    var vertical: Bool = false
    var useGL: Bool = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.doInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.doInit()
    }
    
    func registerNotifications() {
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(self.stopTimer), name: .UIApplicationWillResignActive, object: nil)
        nc.addObserver(self, selector: #selector(self.startTimer), name: .UIApplicationWillEnterForeground, object: nil)
    }
    
    func doInit() {
        self.vertical = self.frame.size.width < self.frame.size.height
        self.layoutVisualizer()
        self.registerNotifications()
    }
    
    func layoutVisualizer() {
    }
    
    func refresh() {
    }
    
    func setPlayer(player: AVAudioPlayer?) {
        if self.player == nil && player != nil {
            if self.updateTimer != nil {
                self.updateTimer?.invalidate()
            }
            self.updateTimer = CADisplayLink.init(target: self, selector: #selector(self.refresh))
            self.updateTimer?.add(to: RunLoop.current, forMode: .defaultRunLoopMode)
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
        }
    }
    
    func setChannels(channels: Array<Int>) {
        self.channelNumbers = channels
        self.layoutVisualizer()
    }
    
    func setUseGL(useGL: Bool) {
        self.useGL = useGL
        self.layoutVisualizer()
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
