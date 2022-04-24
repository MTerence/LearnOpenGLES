//
//  ViewController.swift
//  LearnOpenGLES1
//
//  Created by Ternence on 2022/4/22.
//

import UIKit
import GLKit

/*
 'GLKViewController' was deprecated in iOS 12.0: OpenGLES API deprecated. (Define GLES_SILENCE_DEPRECATION to silence these warnings)
 Project--Build Settings - Preprocessor Macros 配置 GLES_SILENCE_DEPRECATION=1
 */
class ViewController: GLKViewController {

    var mContext: EAGLContext?  = nil
    var mEffect: GLKBaseEffect? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupConfig()
        uploadVertexArray()
        uploadTextture()
    }
    
    func setupConfig() {
        mContext = EAGLContext(api: .openGLES2)
        guard let mContext = mContext,
              let glkView = self.view as? GLKView
        else { return }
        glkView.context = mContext
        glkView.drawableColorFormat = .RGBA8888
        EAGLContext.setCurrent(mContext)
    }
    
    func uploadVertexArray() {
        let vertexData: [GLfloat] = [
            0.5, -0.5, 0.0,    1.0, 0.0, //右下
            0.5, 0.5, -0.0,    1.0, 1.0, //右上
            -0.5, 0.5, 0.0,    0.0, 1.0, //左上

            0.5, -0.5, 0.0,    1.0, 0.0, //右下
            -0.5, 0.5, 0.0,    0.0, 1.0, //左上
            -0.5, -0.5, 0.0,   0.0, 0.0, //左下
        ]
        //顶点数据缓存
        var buffer: GLuint = GLuint()
        glGenBuffers(1, &buffer)
        glBindBuffer(GLenum(GL_ARRAY_BUFFER), buffer)
        glBufferData(GLenum(GL_ARRAY_BUFFER), GLsizeiptr(GLsizei(MemoryLayout<GLfloat>.size * 30)), vertexData, GLenum(GL_STATIC_DRAW))
        //纹理数据缓存
        
        let position = GLuint(GLKVertexAttrib.position.rawValue)
        glEnableVertexAttribArray(position)
        glVertexAttribPointer(position, 3, GLenum(GL_FLOAT), GLboolean(GL_FALSE), GLsizei(MemoryLayout<GLfloat>.size * 5), UnsafeRawPointer(bitPattern: 0))
        
        let texCoord0 = GLuint(GLKVertexAttrib.texCoord0.rawValue)
        glEnableVertexAttribArray(GLuint(texCoord0))
        glVertexAttribPointer(texCoord0, 2, GLenum(GL_FLOAT), GLboolean(GL_FALSE), GLsizei(MemoryLayout<GLfloat>.size * 5), UnsafeRawPointer(bitPattern: 3))
    }
    
    func uploadTextture() {
        let filePath = Bundle.main.path(forResource: "for_test", ofType: "jpg")!
        let options: [String: NSNumber] = [GLKTextureLoaderOriginBottomLeft: 1]
        let texture = try? GLKTextureLoader.texture(withContentsOfFile: filePath, options: options)
        
        mEffect = GLKBaseEffect()
        mEffect?.texture2d0.enabled = GLboolean(GL_TRUE)
        mEffect?.texture2d0.name = texture!.name

    }
    
    override func glkView(_ view: GLKView, drawIn rect: CGRect) {
        glClearColor(0.3, 0.6, 1.0, 1.0)
        glClear(GLbitfield(GL_COLOR_BUFFER_BIT))
        
        mEffect?.prepareToDraw()
        glDrawArrays(GLenum(GL_TRIANGLES), 0, 6)

    }


}

