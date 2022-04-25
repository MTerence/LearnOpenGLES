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
// http://t.zoukankan.com/duzhaoquan-p-12905065.html
/*
 使用OpenGLES 渲染一张图片，主要步骤如下
 1. 创建图层
 2. 创建上下文
 3. 清空缓存区
 4. 设置renderbuffer
 5. 设置framebuffer
 6. 开始绘制，此步骤包含编译连接使用着色器程序，及加载纹理图片
 7. 析构函数中释放buffer
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
        //1. 创建图形上下文，指定opengles渲染api的版本
        mContext = EAGLContext(api: .openGLES2)
        guard let mContext = mContext,
              let glkView = self.view as? GLKView
        else { return }
        glkView.context = mContext
        // GLKViewDrawableColorFormat.RGBA8888  32位rgba的颜色 4*8=32
        // GLKViewDrawableColorFormat.SRGBA8888 srgb格式
        // GLKViewDrawableColorFormat.RGB565    16位rgb的颜色
        glkView.drawableColorFormat = GLKViewDrawableColorFormat.RGBA8888
        EAGLContext.setCurrent(mContext)
    }
    
    func uploadVertexArray() {
        //1. 设置顶点、纹理坐标
        let vertexData: [GLfloat] = [
            0.5, -0.5, 0.0,    1.0, 0.0, //右下
            0.5, 0.5, -0.0,    1.0, 1.0, //右上
            -0.5, 0.5, 0.0,    0.0, 1.0, //左上

            0.5, -0.5, 0.0,    1.0, 0.0, //右下
            -0.5, 0.5, 0.0,    0.0, 1.0, //左上
            -0.5, -0.5, 0.0,   0.0, 0.0, //左下
        ]
        //2. 顶点数据缓存(copy到缓冲区)
        var verbuffer = GLuint()
        glGenBuffers(1, &verbuffer)
        glBindBuffer(GLenum(GL_ARRAY_BUFFER), verbuffer)
        glBufferData(GLenum(GL_ARRAY_BUFFER), MemoryLayout<GLfloat>.size * 30, vertexData, GLenum(GL_DYNAMIC_DRAW))
        
        //顶点数据传递到顶点着色器的postiion属性上
        let position = GLuint(GLKVertexAttrib.position.rawValue)
        //设置合适的格式从buffer里取数据
        glEnableVertexAttribArray(position)
        /*
         glVertexAttribPointer(_ indx: GLuint, _ size: GLint, _ type: GLenum, _ normalized: GLboolean, _ stride: GLsizei, _ ptr: UnsafeRawPointer!)
         indx: 顶点数据的索引
         size: 每个顶点数据的组件数量
         type: 数据中每个组件的类型，常用的有GL_FlOAT. GL_BYTE. GL_SHORT, 默认初始值为GL_FLOAT
         normalized: 固定点数据值是否应该归一化，或者直接转化为固定值GL_FALSE
         stride: 连续便宜顶点值之间的便宜量，默认为0
         ptrL: 指定一个指针，指向数组中第一个顶点属性的第一个组件，默认为0
         */
        glVertexAttribPointer(position, 3, GLenum(GL_FLOAT), GLboolean(GL_FALSE), GLsizei(MemoryLayout<GLfloat>.size * 5), UnsafeRawPointer(bitPattern: 0))
        
        // 纹理坐标传递到顶点着色器的texCoordinate属性上
        let texCoord0 = GLuint(GLKVertexAttrib.texCoord0.rawValue)
        glEnableVertexAttribArray(GLuint(texCoord0))
        glVertexAttribPointer(texCoord0, 2, GLenum(GL_FLOAT), GLboolean(GL_FALSE), GLsizei(MemoryLayout<GLfloat>.size * 5), UnsafeRawPointer(bitPattern: MemoryLayout<GLfloat>.size * 3))
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
        //1. 设置背景颜色
        glClearColor(0.3, 0.6, 1.0, 1.0)
        //2. 清除深度缓冲区
        glClear(GLbitfield(GL_COLOR_BUFFER_BIT))
        
        mEffect?.prepareToDraw()
        //3. 绘制
        glDrawArrays(GLenum(GL_TRIANGLES), 0, 6)
    }


}

