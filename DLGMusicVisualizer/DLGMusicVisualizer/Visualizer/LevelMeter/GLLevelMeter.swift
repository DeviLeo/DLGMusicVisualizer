//
//  GLLevelMeter.swift
//  DLGMusicVisualizer
//
//  Created by DeviLeo on 2017/3/3.
//  Copyright © 2017年 DeviLeo. All rights reserved.
//

import UIKit
import OpenGLES

class GLLevelMeter: LevelMeter {
    var backingWidth: GLint = 0
    var backingHeight: GLint = 0
    var context: EAGLContext?
    var viewRenderBuffer: GLuint = 0
    var viewFrameBuffer: GLuint = 0
    
    override class var layerClass: AnyClass {
        get {
            return CAEAGLLayer.self
        }
    }
    
    deinit {
        if EAGLContext.current() === self.context {
            EAGLContext.setCurrent(nil)
        }
        self.context = nil
        print("GL Level Meter deinit")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        EAGLContext.setCurrent(self.context)
        self.destroyFrameBuffer()
        _ = self.createFrameBuffer()
        self.drawView()
    }
    
    override func draw(_ rect: CGRect) {
        self.drawView()
    }
    
    override func setNeedsDisplay() {
        self.drawView()
    }
    
    // MARK: - Init
    override func doInit() {
        self.level = 0
        self.numLights = 0
        self.variableLightIntensity = true
        
        self.bgColor = UIColor.init(red: 0, green: 0, blue: 0, alpha: 0.6)
        self.borderColor = UIColor.init(red: 0, green: 0, blue: 0, alpha: 1)
        
        self.colorThresholds[0].maxValue = 0.4
        self.colorThresholds[0].color = UIColor.init(red: 0, green: 1, blue: 0, alpha: 1)
        self.colorThresholds[1].maxValue = 0.8
        self.colorThresholds[1].color = UIColor.init(red: 1, green: 1, blue: 0, alpha: 1)
        self.colorThresholds[2].maxValue = 1
        self.colorThresholds[2].color = UIColor.init(red: 1, green: 0, blue: 0, alpha: 1)
        self.vertical = self.frame.size.width < self.frame.size.height
        
        if self.responds(to: #selector(getter: self.contentScaleFactor)) == true {
            self.contentScaleFactor = UIScreen.main.scale
            self.scaleFactor = self.contentScaleFactor
        } else {
            self.scaleFactor = 1.0
        }
        
        let eaglLayer: CAEAGLLayer = self.layer as! CAEAGLLayer
        eaglLayer.isOpaque = true
        eaglLayer.drawableProperties = [
            kEAGLDrawablePropertyRetainedBacking : false,
            kEAGLDrawablePropertyColorFormat : kEAGLColorFormatRGBA8
        ]
        self.context = EAGLContext.init(api: .openGLES1)
        if self.context == nil ||
            !EAGLContext.setCurrent(self.context) ||
            !self.createFrameBuffer() {
            return
        }
        
        self.setupView()
    }
    
    func setupView() {
        // Sets up matrices and transforms for OpenGL ES
        glViewport(0, 0, self.backingWidth, self.backingHeight)
        glMatrixMode(GLenum(GL_PROJECTION))
        glLoadIdentity()
        glOrthof(0, GLfloat(self.backingWidth), 0, GLfloat(self.backingHeight), -1.0, 1.0)
        glMatrixMode(GLenum(GL_MODELVIEW))
        
        // Clears the view with black
        glClearColor(0, 0, 0, 1)
        
        glEnableClientState(GLenum(GL_VERTEX_ARRAY))
    }
    
    func createFrameBuffer() -> Bool {
        // OES suffix means support OES_framebuffer_object extension on OpenGL ES 1.1
        // But it is the core specification in OpenGL ES 2.0 (no OES suffix)
        // http://stackoverflow.com/questions/3272748/glgenframebuffersoes-vs-glgenframebuffers
        glGenFramebuffersOES(1, &self.viewFrameBuffer)
        glGenRenderbuffersOES(1, &self.viewRenderBuffer)
        
        glBindFramebufferOES(GLenum(GL_FRAMEBUFFER_OES), self.viewFrameBuffer)
        glBindRenderbufferOES(GLenum(GL_RENDERBUFFER_OES), self.viewRenderBuffer)
        self.context?.renderbufferStorage(Int(GL_RENDERBUFFER_OES), from: (self.layer as! CAEAGLLayer))
        glFramebufferRenderbufferOES(GLenum(GL_FRAMEBUFFER_OES), GLenum(GL_COLOR_ATTACHMENT0_OES), GLenum(GL_RENDERBUFFER_OES), self.viewRenderBuffer)
        
        glGetRenderbufferParameterivOES(GLenum(GL_RENDERBUFFER_OES), GLenum(GL_RENDERBUFFER_WIDTH_OES), &self.backingWidth)
        glGetRenderbufferParameterivOES(GLenum(GL_RENDERBUFFER_OES), GLenum(GL_RENDERBUFFER_HEIGHT_OES), &self.backingHeight)
        
        if glCheckFramebufferStatusOES(GLenum(GL_FRAMEBUFFER_OES)) != GLenum(GL_FRAMEBUFFER_COMPLETE_OES) {
            print("Failed to make complete framebuffer object %x", glCheckFramebufferStatusOES(GLenum(GL_FRAMEBUFFER_OES)))
            return false
        }
        
        return true
    }
    
    func destroyFrameBuffer() {
        glDeleteFramebuffersOES(1, &self.viewFrameBuffer)
        self.viewFrameBuffer = 0
        glDeleteRenderbuffersOES(1, &self.viewRenderBuffer)
        self.viewRenderBuffer = 0
    }
    
    func drawView() {
        if self.viewFrameBuffer == 0 { return }
        
        // Make sure that you are drawing to the current context
        EAGLContext.setCurrent(self.context)
        
        glBindFramebufferOES(GLenum(GL_FRAMEBUFFER_OES), self.viewFrameBuffer)
        
        let bgColor: CGColor = self.bgColor.cgColor
        if bgColor.numberOfComponents != 4 {
            self.bail()
            return
        }
        
        let rgba: [CGFloat] = bgColor.components!
        glClearColor(GLfloat(rgba[0]), GLfloat(rgba[1]), GLfloat(rgba[2]), 1)
        glClear(GLbitfield(GL_COLOR_BUFFER_BIT))
        
        glPushMatrix()
        
        var bounds: CGRect = .zero
        if self.vertical {
            glScalef(1, -1, 1)
            bounds = CGRect.init(x: 0, y: -1, width: self.bounds.size.width * self.scaleFactor, height: self.bounds.size.height * self.scaleFactor)
        } else {
            glTranslatef(0, GLfloat(self.bounds.size.height * self.scaleFactor), 0)
            glRotatef(-90, 0, 0, 1)
            bounds = CGRect.init(x: 0, y: 1, width: self.bounds.height * self.scaleFactor, height: self.bounds.size.width * self.scaleFactor)
        }
        
        if self.numLights == 0 {
            var currentTop: CGFloat = 0
            
            for ct in self.colorThresholds {
                let val = min(ct.maxValue, self.level)
                let rect = CGRect.init(x: 0, y: bounds.size.height * currentTop,
                                       width: bounds.size.width, height: bounds.size.height * (val - currentTop))
                print("Drawing rect \(rect)")
                
                let vertices: [GLfloat] = [
                    GLfloat(rect.minX), GLfloat(rect.minY),
                    GLfloat(rect.maxX), GLfloat(rect.minY),
                    GLfloat(rect.minX), GLfloat(rect.maxY),
                    GLfloat(rect.maxX), GLfloat(rect.maxY),
                ]
                
                let color: CGColor = (ct.color?.cgColor)!
                if color.numberOfComponents != 4 {
                    self.bail()
                    return
                }
                
                let rgba: [CGFloat] = color.components!
                glColor4f(GLfloat(rgba[0]), GLfloat(rgba[1]), GLfloat(rgba[2]), GLfloat(rgba[3]))
                
                glVertexPointer(2, GLenum(GL_FLOAT), 0, vertices)
                glDrawArrays(GLenum(GL_TRIANGLE_STRIP), 0, 4)
                
                if self.level < ct.maxValue { break }
                
                currentTop = val
            }
        } else {
            var lightMinVal: CGFloat = 0
            var insetAmount: CGFloat = 0
            let lightVSpace: CGFloat = bounds.size.height / CGFloat(self.numLights)
            if lightVSpace < 4.0 { insetAmount = 0 }
            else if lightVSpace < 8.0 { insetAmount = 0.5 }
            else { insetAmount = 1.0 }
            
            var peakLight: Int = -1
            if self.peakLevel > 0 {
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
                    lightIntensity = LEVELMETER_CLAMP(min: 0, x: lightIntensity, max: 1)
                    if !self.variableLightIntensity && lightIntensity > 0 {
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
                
                lightRect = CGRect.init(x: 0, y: bounds.origin.y * (bounds.size.height * (CGFloat(i) / CGFloat(self.numLights))),
                                        width: bounds.size.width, height: bounds.size.height * (1.0 / CGFloat(self.numLights)))
                lightRect = lightRect.insetBy(dx: insetAmount, dy: insetAmount)
                
                let vertices: [GLfloat] = [
                    GLfloat(lightRect.minX), GLfloat(lightRect.minY),
                    GLfloat(lightRect.maxX), GLfloat(lightRect.minY),
                    GLfloat(lightRect.minX), GLfloat(lightRect.maxY),
                    GLfloat(lightRect.maxX), GLfloat(lightRect.maxY),
                ]
                glVertexPointer(2, GLenum(GL_FLOAT), 0, vertices)
                glColor4f(1, 0, 0, 1)
                
                if lightIntensity == 1 {
                    let color: CGColor = (lightColor?.cgColor)!
                    if color.numberOfComponents != 4 {
                        self.bail()
                        return
                    }
                    let rgba: [CGFloat] = color.components!
                    glColor4f(GLfloat(rgba[0]), GLfloat(rgba[1]), GLfloat(rgba[2]), GLfloat(rgba[3]))
                    glDrawArrays(GLenum(GL_TRIANGLE_STRIP), 0, 4)
                } else if lightIntensity > 0 {
                    let color: CGColor = (lightColor?.cgColor)!
                    if color.numberOfComponents != 4 {
                        self.bail()
                        return
                    }
                    let rgba: [CGFloat] = color.components!
                    glColor4f(GLfloat(rgba[0]), GLfloat(rgba[1]), GLfloat(rgba[2]), GLfloat(lightIntensity))
                    glDrawArrays(GLenum(GL_TRIANGLE_STRIP), 0, 4)
                }
                
                lightMinVal = lightMaxVal
            }
        }
        
        self.bail()
    }
    
    func bail() {
        glPopMatrix()
        glFlush()
        glBindRenderbufferOES(GLenum(GL_RENDERBUFFER_OES), self.viewRenderBuffer)
        self.context?.presentRenderbuffer(Int(GL_RENDERBUFFER_OES))
    }
}
