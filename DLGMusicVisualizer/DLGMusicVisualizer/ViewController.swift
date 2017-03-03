//
//  ViewController.swift
//  DLGMusicVisualizer
//
//  Created by Liu Junqi on 02/03/2017.
//  Copyright © 2017 DeviLeo. All rights reserved.
//

import UIKit
import AVFoundation

@objc(ViewController)
class ViewController: UIViewController, AVAudioSessionDelegate, AVAudioPlayerDelegate {
    
    var url: String?
    
    @IBOutlet weak var vContainer: UIView?
    @IBOutlet weak var vTopBar: UIView?
    @IBOutlet weak var btnBack: UIButton?
    @IBOutlet weak var vBottomBar: UIView?
    @IBOutlet weak var lblTitle: UILabel?
    @IBOutlet weak var btnPlay: UIButton?
    @IBOutlet weak var btnPrev: UIButton?
    @IBOutlet weak var btnNext: UIButton?
    @IBOutlet weak var pvProgress: UIProgressView?
    @IBOutlet weak var lblCurrentTime: UILabel?
    @IBOutlet weak var lblTotalTime: UILabel?
    
    var updateTimer: Timer?
    var player: AVAudioPlayer?
    var visualizer: CALevelMeter?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.initPlayer()
        self.updateTitle()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.registerNotificaions()
        self.initVisualizer()
        self.playAudio()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.pauseAudio()
        self.unregisterNotification()
    }
    
    deinit {
        print("ViewController deinit")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Init
    func initPlayer() {
        let url: URL? = URL.init(fileURLWithPath: self.url!)
        if url == nil { return }
        do {
            try self.player = AVAudioPlayer.init(contentsOf: url!)
            self.player?.numberOfLoops = 1
            self.player?.delegate = self
        } catch let error as NSError {
            print("AVAudioPlayer.init error: \(error)")
        }
        do {
            let audio: AVAudioSession = AVAudioSession.sharedInstance()
            try audio.setCategory(AVAudioSessionCategoryPlayback)
        } catch let error as NSError {
            print("AVAudioSession.setCategory error: \(error)")
        }
    }
    
    func initVisualizer() {
        if self.visualizer != nil {
            self.visualizer?.removeFromSuperview()
            self.visualizer = nil
        }
        let meter: CALevelMeter = CALevelMeter.init(frame: (self.vContainer?.bounds)!)
        self.vContainer?.addSubview(meter)
        self.vContainer?.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[v]|",
                                                                       options: NSLayoutFormatOptions.init(rawValue: 0),
                                                                       metrics: nil,
                                                                       views: ["v":meter]))
        self.vContainer?.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[v]|",
                                                                       options: NSLayoutFormatOptions.init(rawValue: 0),
                                                                       metrics: nil,
                                                                       views: ["v":meter]))
        self.visualizer = meter
    }
    
    func registerNotificaions() {
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(self.handleAudioSessionInterruption(notif:)), name: .AVAudioSessionInterruption, object: AVAudioSession.sharedInstance())
    }
    
    func unregisterNotification() {
        let nc = NotificationCenter.default
        nc.removeObserver(self)
    }
    
    func updateTitle() {
        if self.player == nil {
            self.lblTitle?.text = "DLGMusicVisualizer"
        } else {
            let url = self.player?.url
            if url == nil {
                self.lblTitle?.text = "DLGMusicVisualizer"
            } else {
                let name = url?.lastPathComponent
                self.lblTitle?.text = name
            }
        }
    }
    
    func startUpdateTimer() {
        if self.updateTimer == nil {
            self.updateTimer = Timer.scheduledTimer(timeInterval: 0.2,
                                                    target: self,
                                                    selector: #selector(self.updateProgress(t:)),
                                                    userInfo: nil,
                                                    repeats: true)
        } else {
            self.updateTimer?.fire()
        }
        self.updateProgress(t: self.updateTimer!)
    }
    
    func stopUpdateTimer() {
        if self.updateTimer != nil {
            self.updateTimer?.invalidate()
            self.updateTimer = nil
        }
        self.updateProgress(t: nil)
    }
    
    func playAudio() {
        self.player?.play()
        self.startUpdateTimer()
        self.btnPlay?.isSelected = true
        self.visualizer?.setPlayer(player: self.player)
    }
    
    func pauseAudio() {
        self.player?.pause()
        self.stopUpdateTimer()
        self.btnPlay?.isSelected = false
        self.visualizer?.setPlayer(player: nil)
    }
    
    // MARK: - Events
    @IBAction func onBackTapped(sender: Any) {
        _ = self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func onPlayTapped(sender: Any) {
        let play: Bool = !(self.btnPlay?.isSelected)!
        if play == true {
            self.playAudio()
        } else {
            self.pauseAudio()
        }
    }
    
    @IBAction func onPrevTapped(sender: Any) {
        self.player?.currentTime -= 1
    }
    
    @IBAction func onNextTapped(sender: Any) {
        self.player?.currentTime += 1
    }
    
    
    // MARK: - Gesture
    @IBAction func onTapGestureRecognized(recognizer: UIGestureRecognizer) {
        if recognizer.state == .ended {
            let showHUD: Bool = (self.vTopBar?.isHidden)!
            self.vTopBar?.isHidden = !showHUD
            self.vBottomBar?.isHidden = !showHUD
        }
    }
    
    // MARK: - Timer
    func updateProgress(t: Timer?) {
        let duration = (self.player?.duration)!
        let ds: String = self.time2string(t: duration)
        let current = (self.player?.currentTime)!
        let cs: String = self.time2string(t: current)
        let progress = current / duration
        self.lblCurrentTime?.text = cs
        self.lblTotalTime?.text = ds
        self.pvProgress?.progress = Float(progress)
    }
    
    func time2string(t: TimeInterval) -> String {
        let sec: Int = Int(t)
        let m: Int = sec / 60
        let s: Int = sec % 60
        let str: String = String.init(format: "%zd:%02zd", m, s)
        return str
    }
    
    // MARK: - AVAudioSessionDelegate
    
    
    // MARK: - Notifications
    func handleAudioSessionInterruption(notif: Notification) {
        let reason = notif.userInfo![AVAudioSessionRouteChangeReasonKey] as! AVAudioSessionRouteChangeReason
        let route = notif.userInfo![AVAudioSessionRouteChangePreviousRouteKey] as! AVAudioSessionRouteDescription
        
        print("Route Changed: ")
        switch reason {
        case .newDeviceAvailable:
            print("\t\tNew Device Available")
            self.playAudio()
            break
        case .oldDeviceUnavailable:
            print("\t\tOld Device Unavailable")
            self.pauseAudio()
            break
        case .categoryChange:
            print("\t\tCategory Change")
            print("\t\tNew Category: \(AVAudioSession.sharedInstance().category)")
            break
        case .override:
            print("\t\tOverride")
            break
        case .wakeFromSleep:
            print("\t\tWake From Sleep")
            break
        case .noSuitableRouteForCategory:
            print("\t\tNo Suitable Route For Category")
            break
        default:
            print("\t\tUnknown Reason: \(reason)")
        }
        
        print("Previous route: \(route)")
    }
    
    // MARK: - AVAudioPlayerDelegate
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if flag == false {
            print("Playback finished unsuccessfully")
        }
        
        player.currentTime = 0
        self.updateProgress(t: nil)
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        print("Audio player decode error: \(error)")
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: nil) { (context) in
            self.initVisualizer()
            if self.player?.isPlaying == true {
                self.visualizer?.setPlayer(player: self.player)
            }
        }
    }
}

