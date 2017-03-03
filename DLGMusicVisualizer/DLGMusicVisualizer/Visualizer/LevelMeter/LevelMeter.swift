//
//  LevelMeter.swift
//  DLGMusicVisualizer
//
//  Created by Liu Junqi on 03/03/2017.
//  Copyright © 2017 DeviLeo. All rights reserved.
//

import UIKit

struct LevelMeterColorThreshold {
    var maxValue: CGFloat = 0.0
    var color: UIColor? = nil
}

class LevelMeter: UIView {
    
    var numLights: Int = 0
    var level: CGFloat = 0
    var peakLevel: CGFloat = 0
    var colorThresholds: Array<LevelMeterColorThreshold> = Array.init(repeating: LevelMeterColorThreshold(), count: 3)
    var vertical: Bool = false
    var variableLightIntensity: Bool = true
    var bgColor: UIColor = UIColor.init(white: 0, alpha: 0.6)
    var borderColor: UIColor = UIColor.init(white: 0, alpha: 1)
    var scaleFactor: CGFloat = 0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.doInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.doInit()
    }
    
    func doInit() {
        self.colorThresholds[0].maxValue = 0.25
        self.colorThresholds[0].color = UIColor.init(red: 0, green: 1, blue: 0, alpha: 1)
        self.colorThresholds[1].maxValue = 0.8
        self.colorThresholds[1].color = UIColor.init(red: 1, green: 1, blue: 0, alpha: 1)
        self.colorThresholds[2].maxValue = 1
        self.colorThresholds[2].color = UIColor.init(red: 1, green: 0, blue: 0, alpha: 1)
        self.vertical = self.frame.size.width < self.frame.size.height
    }
    
    deinit {
        print("Level Meter deinit")
    }
    
    @inline(__always) func LEVELMETER_CLAMP<T : Comparable>(min: T, x: T, max: T) -> T {
        return (x < min ? min : (x > max ? max : x))
    }
    
    func compareLevelThresholds(_ a: LevelMeterColorThreshold, _ b: LevelMeterColorThreshold) -> Int {
        if a.maxValue > b.maxValue { return 1 }
        if a.maxValue < b.maxValue { return -1 }
        return 0
    }

    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        let ctx: CGContext? = UIGraphicsGetCurrentContext()
        let cs: CGColorSpace = CGColorSpaceCreateDeviceRGB()
        var bounds: CGRect = CGRect.zero
        
        ctx?.translateBy(x: 0.0, y: self.bounds.size.height)
        if self.vertical {
            ctx?.scaleBy(x: 1.0, y: -1.0)
            bounds = self.bounds
        } else {
            ctx?.rotate(by: -(CGFloat)(M_PI_2))
            bounds = CGRect.init(x: 0, y: 0, width: self.bounds.size.height, height: self.bounds.size.width)
        }
        ctx?.setFillColorSpace(cs)
        ctx?.setStrokeColorSpace(cs)
        
        if self.numLights == 0 {
            var currentTop: CGFloat = 0
            
            self.bgColor.set()
            ctx?.fill(bounds)
            
            for ct in self.colorThresholds {
                let val: CGFloat = min(ct.maxValue, self.level)
                let rect: CGRect = CGRect.init(x: 0, y: bounds.size.height * currentTop,
                                               width: bounds.size.width, height: bounds.size.height * (val - currentTop))
                ct.color?.set()
                ctx?.fill(rect)
                
                if self.level < ct.maxValue { break }
                currentTop = val
            }
            
            self.borderColor.set()
            ctx?.stroke(bounds.insetBy(dx: 0.5, dy: 0.5))
        } else {
            var lightMinVal: CGFloat = 0
            var insetAmount: CGFloat = 0
            let lightVSpace: CGFloat = bounds.size.height / CGFloat(self.numLights)
            if lightVSpace < 4.0 { insetAmount = 0 }
            else if lightVSpace < 8.0 { insetAmount = 0.5 }
            else { insetAmount = 1.0 }
            
            var peakLight: Int = -1
            if self.peakLevel > 0.0 {
                peakLight = Int(self.peakLevel * CGFloat(self.numLights))
                if peakLight >= self.numLights { peakLight = self.numLights - 1 }
            }
            
            for i in 0 ..< self.numLights {
                let lightMaxVal: CGFloat = CGFloat(i + 1) / CGFloat(self.numLights)
                var lightIntensity: CGFloat = 0
                var lightRect: CGRect = .zero
                var lightColor: UIColor?
                
                if i == peakLight {
                    lightIntensity = 1
                } else {
                    lightIntensity = (self.level - lightMinVal) / (lightMaxVal - lightMinVal)
                    if self.variableLightIntensity == false && lightIntensity > 0 {
                        lightIntensity = 1
                    }
                }
                
                lightColor = self.colorThresholds[0].color
                let count = self.colorThresholds.count - 1
                for j in 0 ..< count {
                    let thisct = self.colorThresholds[j]
                    let nextct = self.colorThresholds[j + 1]
                    if thisct.maxValue <= lightMaxVal {
                        lightColor = nextct.color
                    }
                }
                
                lightRect = CGRect.init(x: 0, y: bounds.size.height * (CGFloat(i) / CGFloat(self.numLights)),
                                        width: bounds.size.width, height: bounds.size.height * (1.0 / CGFloat(self.numLights)))
                lightRect = lightRect.insetBy(dx: insetAmount, dy: insetAmount)
                
                self.bgColor.set()
                ctx?.fill(lightRect)
                
                if lightIntensity == 1 {
                    lightColor?.set()
                    ctx?.fill(lightRect)
                } else if lightIntensity > 0 {
                    let color: CGColor? = lightColor?.cgColor.copy(alpha: lightIntensity)
                    if color != nil {
                        ctx?.setFillColor(color!)
                        ctx?.fill(lightRect)
                    }
                }
                
                self.borderColor.set()
                ctx?.stroke(lightRect.insetBy(dx: 0.5, dy: 0.5))
                
                lightMinVal = lightMaxVal
            }
        }
    }

}
