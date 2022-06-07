//
//  AGLKView.swift
//  LearnOpenGLES1
//
//  Created by Ternence on 2022/4/28.
//

import UIKit

protocol AGLKViewDelegate : AnyObject{
    func glkView(glkView: AGLKView, drawInRect rect: CGRect)
}

class AGLKView: UIView {

    weak var delegat: AGLKViewDelegate? = nil
    
    var defaultFrameBuffer = GLuint()
    var colorRenderBuffer  = GLuint()
    var drawableWidth = GLint()
    var drawableHeight = GLuint()
    
    var context: EAGLContext? {
        willSet {
            EAGLContext.setCurrent(newValue)
            if defaultFrameBuffer != 0 {
                glDeleteBuffers(1, &defaultFrameBuffer)
                defaultFrameBuffer = 0
            }
            
            if colorRenderBuffer != 0 {
                glDeleteRenderbuffers(1, &colorRenderBuffer)
                colorRenderBuffer = 0
            }
        }
        
        didSet {
            if context != nil {
                EAGLContext.setCurrent(context)
                glGenFramebuffers(1, &defaultFrameBuffer)
                glBindFramebuffer(GLenum(GL_FRAMEBUFFER),
                                  defaultFrameBuffer)
                
                glGenRenderbuffers(1, &colorRenderBuffer)
                glBindRenderbuffer(GLenum(GL_RENDERBUFFER),
                                   colorRenderBuffer)
                
                // Attach color render buffer to bound Frame buffer
                glFramebufferRenderbuffer(GLenum(GL_FRAMEBUFFER),
                                          GLenum(GL_COLOR_ATTACHMENT0),
                                          GLenum(GL_RENDERBUFFER),
                                          GLuint(colorRenderBuffer))
            }
        }
    }

    //return the CALayer subclass to be used by CoreAnimation with this view
    override class var layerClass: AnyClass {
        return CAEAGLLayer.self
    }

    public
    init(frame: CGRect, context aContext: EAGLContext) {
        super.init(frame: frame)
        self.context = aContext
        guard let eaglLayer = self.layer as? CAEAGLLayer else { return }
        eaglLayer.drawableProperties = [kEAGLDrawablePropertyRetainedBacking: false,
                                        kEAGLDrawablePropertyColorFormat: kEAGLColorFormatSRGBA8]
        
    }
    
    
    
    private
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    internal
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func display(_ layer: CALayer) {
        guard let context = context else { return }

        glViewport(0, 0,GLsizei(self.drawableWidth), GLsizei(self.drawableHeight))
        self.draw(self.bounds)
        context.presentRenderbuffer(Int(GL_RENDERBUFFER))
    }
    
    override func draw(_ rect: CGRect) {
        self.delegat?.glkView(glkView: self, drawInRect: self.bounds)
    }
}
