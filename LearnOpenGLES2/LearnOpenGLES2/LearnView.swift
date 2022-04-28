//
//  LearnView.swift
//  LearnOpenGLES1
//
//  Created by Ternence on 2022/4/25.
//
//https://www.jianshu.com/p/ee597b2bd399
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

//EAGL前缀： Embeded Apple GL 嵌入式

import UIKit
import GLKit

class LearnView: UIView {
    
    weak var myEagLayer: CAEAGLLayer!
    weak var myContext: EAGLContext!
    var myColorRenderBuffer = GLuint()
    var myColorFrameBuffer = GLuint()
    
    
    /// 重写父类属性layerClass，将View返回的图层从CALayer替换为CAEAGLLayer
    override class var layerClass: AnyClass {
        return CAEAGLLayer.self
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.backgroundColor = UIColor.white
        
        //1. 创建图层
        setupLayer()
        //2. 设置图层上下文
        setupContext()
        //3. 清楚缓冲区
        destoryRenderAndFrameBuffer()
        //4. 设置渲染缓冲区
        setupRenderBuffer()
        //5. 设置帧缓冲区
        setupFrameBuffer()
        //6. 开始绘制
        render()
    }
    
    func setupLayer() {
        if let layer = self.layer as? CAEAGLLayer {
            myEagLayer = layer
        }
        
        // 设置放大倍数
        self.contentScaleFactor = UIScreen.main.scale
        // CALayer 默认是透明的，必须将它设置为不透明才能让其可见
        self.myEagLayer?.isOpaque = true
        //设置描述属性
        self.myEagLayer?.drawableProperties = [kEAGLDrawablePropertyRetainedBacking: false,
                                                   kEAGLDrawablePropertyColorFormat: kEAGLColorFormatRGBA8]

        /*
         kEAGLDrawablePropertyRetainedBacking: 不使用保留背景，即层的任何部分在显示到屏幕上时，都要重新绘制整个层的内容、这个枚举告诉core animation不保留任何以前绘制的图像以做重用
         kEAGLDrawablePropertyColorFormat: 可绘制表面的颜色格式
         kEAGLColorFormatRGBA8  32位rgba的颜色 4*8=32
         kEAGLColorFormatRGB565 srgb格式
         kEAGLColorFormatSRGBA8 16位rgb的颜色
         */
    }
    
    func setupContext() {
        if let con = EAGLContext(api: EAGLRenderingAPI.openGLES2){
            EAGLContext.setCurrent(con)
            self.myContext = con
            print("创建context成功")
        }else{
            print("创建context失败")
        }
    }
    
    
    // frameBuffer 相当于renderBuffer的管理者
    // frameBuffer Object 又称为FBO
    // renderBuffer又分为3类，colorBuffer/depthBuffer/stencilBuffer
    func destoryRenderAndFrameBuffer() {
        glDeleteFramebuffers(1, &myColorFrameBuffer)
        self.myColorFrameBuffer = 0
        
        glDeleteRenderbuffers(1, &myColorRenderBuffer)
        self.myColorRenderBuffer = 0
    }

    // 设置渲染缓冲区
    func setupRenderBuffer() {
        //1. 申请一个缓冲区标志
        glGenRenderbuffers(1, &self.myColorRenderBuffer)
        //2. 将标识符绑定到GL_RENDERBUFFER
        glBindRenderbuffer(GLenum(GL_RENDERBUFFER), self.myColorRenderBuffer)
        //3. 为可绘制对象Drawable object's CAEAGALayer的存储绑定到Open GLES renderbuffer 对象
        self.myContext?.renderbufferStorage(Int(GLenum(GL_RENDERBUFFER)), from: self.myEagLayer)
        
    }
    
    // 设置帧缓冲区
    // 生成缓冲区后，需要将renderbuffer 跟framebuffer进行绑定
    // 调用glFzramebufferRenderbuffer函数进行绑定到对应的附着点上，后边的绘制才会起作用
    func setupFrameBuffer() {
        glGenFramebuffers(1, &self.myColorFrameBuffer)
        glBindFramebuffer(GLenum(GL_FRAMEBUFFER), self.myColorFrameBuffer)
        //将渲染缓冲区myColorRenderBuffer 通过 glFrameBufferRenderBuffer函数绑定到GL_COLOR_ATTACHMENT0
        glFramebufferRenderbuffer(GLenum(GL_FRAMEBUFFER), GLenum(GL_COLOR_ATTACHMENT0), GLenum(GL_RENDERBUFFER), self.myColorRenderBuffer)
    }
    
    func render() {
        glClearColor(0.5, 1.0, 0.5, 1.0)
        glClear(GLbitfield(GL_COLOR_BUFFER_BIT))
        
        let scale = UIScreen.main.scale
        glViewport(GLsizei(frame.origin.x * scale),
                   GLsizei(frame.origin.y * scale),
                   GLsizei(frame.size.width * scale),
                   GLsizei(frame.size.height * scale))
        
        //读取文件路径
        let vertFile = Bundle.main.path(forResource: "shaderv", ofType: "vsh")
        let fragFile = Bundle.main.path(forResource: "shaderf", ofType: "fsh")
        
        // 加载shader,读取顶点着色程序、片元着色程序
        let (isLinkSuccess, program) = loadShader(vertPath: vertFile!, fragPath: fragFile!)
        
        if !isLinkSuccess {
            return
        }
        
        //设置顶点、纹理坐标
        let vertexs: [GLfloat] = [
            0.5, -0.5, -1.0,     1.0, 0.0,
           -0.5, 0.5, -1.0,     0.0, 1.0,
           -0.5, -0.5, -1.0,    0.0, 0.0,
                  
           0.5, 0.5, -1.0,      1.0, 1.0,
          -0.5, 0.5, -1.0,     0.0, 1.0,
           0.5, -0.5, -1.0,     1.0, 0.0,
       ]
        
        // generate、bind and initialize contents of buffer to be stored in GPU Memory
        //  处理顶点数据(copy到缓冲区)
        var verbuffer = GLuint()
        glGenBuffers(1, &verbuffer)
        glBindBuffer(GLenum(GL_ARRAY_BUFFER), verbuffer)
        glBufferData(GLenum(GL_ARRAY_BUFFER), MemoryLayout<GLfloat>.size * 30, vertexs, GLenum(GL_DYNAMIC_DRAW))
        
        //将顶点数据通过Program传递到顶点着色器程序的position属性上
        //.1 glGetAttribLocation用来获取vertext attrib的入口的
        //.2 告诉open gl es， 通过glEnableVertexAttribArray打开开关
        //.3 最后数据是通过glVertexAttribPointer传递进去的
        let position = glGetAttribLocation(program, "position")
        glEnableVertexAttribArray(GLuint(position))
        glVertexAttribPointer(GLuint(position), 3, GLenum(GL_FLOAT), GLboolean(GL_FALSE), GLsizei(MemoryLayout<GLfloat>.size * 5), UnsafeRawPointer(bitPattern: 0))
        
        //纹理坐标通过Program传递到顶点着色器程序的textCoordinate属性上
        let textutre = glGetAttribLocation(program, "textCoordinate")
        glEnableVertexAttribArray(GLuint(textutre))
        glVertexAttribPointer(GLuint(textutre), 2, GLenum(GL_FLOAT), GLboolean(GL_FALSE), GLsizei(MemoryLayout<GLfloat>.size * 5), UnsafeRawPointer(bitPattern: MemoryLayout<GLfloat>.size * 3))
        
        //加载纹理图片
        self.setupTextureImage(imageName: "for_test")
        //设置纹理采样器
        //glUniform1f(glGetUniformLocation(program, "colorMap"), 0)
        
        rotateTextureImage(program: program)
        
        //绘制
        glDrawArrays(GLenum(GL_TRIANGLES), 0, 6)
        //提交
        myContext?.presentRenderbuffer(Int(GL_RENDERBUFFER))
    }

    func setupTextureImage(imageName: String) {
        guard let image = UIImage(named: imageName)?.cgImage else { return }
        let width = image.width
        let height = image.height
        
        //开辟内存，绘制到这个内存上去
        //rgba公4个byte
        let spriteData: UnsafeMutablePointer = UnsafeMutablePointer<GLubyte>.allocate(capacity: MemoryLayout<GLubyte>.size * width * height * 4)
        
        UIGraphicsBeginImageContext(CGSize(width: width, height: height))
        //获取context
        let spriteContext = CGContext(data: spriteData, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4, space: image.colorSpace!, bitmapInfo: image.bitmapInfo.rawValue)
        
        spriteContext?.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        UIGraphicsEndImageContext()
        
        glBindTexture(GLenum(GL_TEXTURE_2D), 0)
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MIN_FILTER), GL_LINEAR)
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MAG_FILTER), GL_LINEAR)
        
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_S), GL_CLAMP_TO_EDGE)
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_T), GL_CLAMP_TO_EDGE)
        

        glTexImage2D(GLenum(GL_TEXTURE_2D), 0, GL_RGBA, GLsizei(width), GLsizei(height), 0, GLenum(GL_RGBA), GLenum(GL_UNSIGNED_BYTE), spriteData)
        glBindTexture(GLenum(GL_TEXTURE_2D), 0)
        free(spriteData)
    }
    
    
    //c语言编译流程： 预编译、编译、汇编、链接
    //glsl的编译主要有glCompileShader、glAttachShader、glLinkProgram这三步
    func loadShader(vertPath: String, fragPath: String) -> (Bool, GLuint) {
        let program = glCreateProgram()
        
        // 顶点着色器
        if let vertShader = compileShader(type: GLenum(GL_VERTEX_SHADER), file: vertPath) {
            //1. 把编译后的着色器代码附着到最终的程序上
            glAttachShader(program, vertShader)
            //2. 释放不需要的shader
            glDeleteShader(vertShader)
        }
        
        //片元着色器
        if let fragShader = compileShader(type: GLenum(GL_FRAGMENT_SHADER), file: fragPath) {
            glAttachShader(program, fragShader)
            glDeleteShader(fragShader)
        }
        
        //链接着色器
        glLinkProgram(program)
        
        //获取链接状态
        var status: GLint = 0
        glGetProgramiv(program, GLenum(GL_LINK_STATUS), &status)
        if status == GLenum(GL_FALSE) {
            //链接错误
            let message = UnsafeMutablePointer<GLchar>.allocate(capacity: 512)
            glGetProgramInfoLog(program, GLsizei(MemoryLayout<GLchar>.size * 512), nil, message)
            let str = String.init(utf8String: message)
            print(str ?? "没有取到ProgramInfoLog")
            return (false, program)
        } else {
            print("link success")
            //链接成功，使用着色器程序
            glUseProgram(program)
            return (true, program)
        }
    }
    
    //读取并编译着色器程序
    func compileShader(type: GLenum, file: String) -> GLuint? {
        //1. 创建一个空着色器
        let verShader: GLuint = glCreateShader(type)
        //2. 获取源文件中的代码字符串
        guard let shaderString = try? String.init(contentsOfFile: file, encoding: String.Encoding.utf8) else { return nil }
        //3. 转成C字符串赋值给已创建的shader
        shaderString.withCString { pointer in
            var pon: UnsafePointer<GLchar>? = pointer
            glShaderSource(verShader, 1, &pon, nil)
        }
        
        //编译
        glCompileShader(verShader)
        return verShader
    }
    
    func rotateTextureImage(program: GLuint) {
        let rotate = glGetUniformLocation(program, "rotateMatrix")
        let radians = 10 * 3.141592 / 180
        let s = GLfloat(sin(radians))
        let c = GLfloat(cos(radians))

        let zRotation: [GLfloat] = [
            c, -s, 0, 0.2, //
            s, c, 0, 0,//
            0, 0, 1.0, 0,//
            0.0, 0, 0, 1.0//
        ]

        glUniformMatrix4fv(rotate, 1, 0, zRotation)

    }
}
