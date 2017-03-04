//
//  CircleVisualizer.swift
//  DLGMusicVisualizer
//
//  Created by DeviLeo on 2017/3/4.
//  Copyright © 2017年 DeviLeo. All rights reserved.
//

import UIKit

class CircleVisualizer: BaseVisualizer {
    
    let bgColor: UIColor = UIColor.black
    let frColor: UIColor = UIColor.white
    let fr2Color: UIColor = UIColor.red
    let segCount: Int = 18
    var degreePerSeg: Int = 0
    var curSeg: Int = 0
    var aniSeg: Int = 0
    var angleBias: Int = 0
    var power: Array<Array<CGFloat>> = Array.init()
    
    override func doInit() {
        self.degreePerSeg = 360 / self.segCount
    }
    
    override func setChannels(channels: Array<Int>) {
        super.setChannels(channels: channels)
        for _ in channels {
            let p = Array<CGFloat>.init(repeating: 0, count: segCount + 1)
            self.power.append(p)
        }
    }
    
    override func refresh() {
        self.setNeedsDisplay()
    }

    override func draw(_ rect: CGRect) {
        let ctx = UIGraphicsGetCurrentContext()
        
        bgColor.set()
        ctx?.fill(self.bounds)
        
        
        if (self.player != nil) {
            self.player?.updateMeters()
            
            let count = self.channelNumbers.count
            for i in 0 ..< (segCount - 1) {
                for j in 0 ..< count {
                    self.power[j][i+1] = self.power[j][i]
                }
            }
            
            for i in 0 ..< count {
                let channelIndex = self.channelNumbers[i]
                
                if channelIndex >= count { break }
                if channelIndex > 127 { break }
                
                let avgpwr = self.player?.averagePower(forChannel: channelIndex)
                self.power[channelIndex][0] = CGFloat(self.meterTable.valueAt(in: Double(avgpwr!)))
            }
            
            let center = CGPoint.init(x: self.bounds.midX, y: self.bounds.midY)
            frColor.set()
            for i in 0 ..< aniSeg {
                let startAngle = self.radian(degree: CGFloat(i * degreePerSeg + angleBias)) - CGFloat(M_PI_2)
                let endAngle = self.radian(degree: CGFloat((i + 1) * degreePerSeg + angleBias)) - CGFloat(M_PI_2)
                let radius: CGFloat = 80
                let startPt = self.pointOnCircle(center: center, radius: radius, radian: startAngle, clockwise: false)
                let endPt = self.pointOnCircle(center: center, radius: radius, radian: endAngle, clockwise: false)
                let midAngle = (startAngle + endAngle) / 2
                let midRadius = radius + 80 * self.power[0][i]
                let midPt = self.pointOnCircle(center: center, radius: midRadius, radian: midAngle, clockwise: false)
                
                let startAngle2 = self.radian(degree: CGFloat(i * degreePerSeg - angleBias)) - CGFloat(M_PI_2)
                let endAngle2 = self.radian(degree: CGFloat((i + 1) * degreePerSeg - angleBias)) - CGFloat(M_PI_2)
                let midAngle2 = (startAngle2 + endAngle2) / 2
                let midRadius2 = radius - 80 * self.power[1][i]
                let midPt2 = self.pointOnCircle(center: center, radius: midRadius2, radian: midAngle2, clockwise: false)
                
                ctx?.move(to: startPt)
                ctx?.addLine(to: midPt)
                ctx?.addLine(to: endPt)
                ctx?.addEllipse(in: .init(origin: midPt2, size: .init(width: 4, height: 4)))
            }
            ctx?.strokePath()
            
            if aniSeg < segCount {
                aniSeg += 1
            }
            
            if angleBias < 360 {
                angleBias += 1
            } else {
                angleBias = 0
            }
        }
        
    }
    
    func radian(degree: CGFloat) -> CGFloat {
        return CGFloat(Double(degree) * M_PI / 180.0)
    }
    
    func radianOfPoint(point: CGPoint) -> Double {
        if point.x == 0 {
            if point.y > 0 { return M_PI_2 }
            else if point.y < 0 { return (M_PI + M_PI_2) }
            else { return 0 }
        } else if point.y == 0 {
            if point.x < 0 { return M_PI }
            else { return 0 }
        }
        let v = point.y / point.x
        let rad = atan(Double(v))
        var r = rad // Quadrant I
        if (point.x < 0 && point.y > 0) ||// Quadrant II
            (point.x < 0 && point.y < 0) { // Quadrant III
            r += M_PI
        } else if point.x > 0 && point.y < 0 { // Quadrant IV
            r += M_PI + M_PI
        }
        return r
    }
    
    func pointOnCircle(center: CGPoint, radius: CGFloat, radian: CGFloat, clockwise: Bool) -> CGPoint {
        let x: CGFloat = radius * cos(radian)
        let y: CGFloat = clockwise ? -radius * sin(radian) : radius * sin(radian)
        let fx = x + center.x
        let fy = y + center.y
        return CGPoint.init(x: fx, y: fy)
    }
    
    func endPointOnArc(center: CGPoint, radius: CGFloat, start: CGPoint, radian: CGFloat, clockwise: Bool) -> CGPoint {
        let r = radianOfPoint(point: start)
        let rad = clockwise ? r - Double(radian) : r + Double(radian)
        return pointOnCircle(center: center, radius: radius, radian: CGFloat(rad), clockwise: false)
    }
}
