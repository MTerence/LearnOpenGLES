# LearnOpenGLES
LearnOpenGLES-Swift 用Swift语言实现的iOS端OpenGLES使用

## [LearnOpenGLES1] 将图片通过GLKViewController渲染到屏幕
```
class ViewController: GLKViewController {

    var mContext: EAGLContext?  = nil
    var mEffect: GLKBaseEffect? = nil
    var vertexBufferID = GLuint()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .red
        setupConfig()
        uploadVertexArray()
        uploadTextture()
    }
    
    deinit {
        if let glkView = self.view as? GLKView {
            EAGLContext.setCurrent(glkView.context)
        }
        
        if vertexBufferID != 0 {
            glDeleteBuffers(1, &vertexBufferID)
            vertexBufferID = 0
        }
        
        EAGLContext.setCurrent(nil)
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
        // generate、bind and initialize contents of buffer to be stored in GPU Memory
        // glGenBuffers 第一个参数用于指定要生成的缓存标识符的数量
        // glGenBuffers 第二个参数是一个指针，指向生成的标识符的内存地址
        // glGenBuffers 表示生成一个标识符，并保存到vertexBufferID实例变量中
        // glBindBuffer 绑定标识符的缓存到当前缓存
        // glBindBuffer 第一个参数表示要绑定的缓存类型, GL_ARRAY_BUFFER 用于指定顶点属性数组
        // glBufferData 复制顶点数据到当先上下文所绑定的顶点缓存中
        glGenBuffers(1, &vertexBufferID)
        glBindBuffer(GLenum(GL_ARRAY_BUFFER), vertexBufferID)
        glBufferData(GLenum(GL_ARRAY_BUFFER),   //指定缓存类型
                     MemoryLayout<GLfloat>.size * 30,   //要复制进这个缓存的字节数量
                     vertexData,    //要复制的字节地址
                     GLenum(GL_DYNAMIC_DRAW))   //缓存在未来会怎样被使用 GL_DYNAMIC_DRAW: 未来可能会频繁改变, GL_STATIC_DRAW: 缓存内容适合复制到GPU控制的内存，因为很少对齐改变，这有助于OpenGL ES优化内存
        
        //顶点数据传递到顶点着色器的postiion属性上
        let position = GLuint(GLKVertexAttrib.position.rawValue)
        //设置合适的格式从buffer里取数据
        //启动顶点渲染缓存操作
        glEnableVertexAttribArray(position)
        
        /*
         glVertexAttribPointer(_ indx: GLuint, _ size: GLint, _ type: GLenum, _ normalized: GLboolean, _ stride: GLsizei, _ ptr: UnsafeRawPointer!)
         indx: 顶点数据的索引 当前绑定的缓存包含每个顶点的位置信息
         size: 每个顶点数据的组件数量
         type: 数据中每个组件的类型，常用的有GL_FlOAT. GL_BYTE. GL_SHORT, 默认初始值为GL_FLOAT
         normalized: 小数点固定数据是否可以被改变，GL_FALSE
         stride: 步幅，每个顶点的保存需要多少个字节 连续偏移顶点值之间偏移量，默认为0
         ptrL: 从当前绑定的顶点缓存的开始配置偏移 + x 位置开始访问顶点数据
         */
        glVertexAttribPointer(position,
                              3,
                              GLenum(GL_FLOAT),
                              GLboolean(GL_FALSE),
                              GLsizei(MemoryLayout<GLfloat>.size * 5),
                              UnsafeRawPointer(bitPattern: 0))
        
        // 纹理坐标传递到顶点着色器的texCoordinate属性上
        let texCoord0 = GLuint(GLKVertexAttrib.texCoord0.rawValue)
        glEnableVertexAttribArray(GLuint(texCoord0))
        glVertexAttribPointer(texCoord0, 2, GLenum(GL_FLOAT), GLboolean(GL_FALSE), GLsizei(MemoryLayout<GLfloat>.size * 5), UnsafeRawPointer(bitPattern: MemoryLayout<GLfloat>.size * 3))
    }
    
    func uploadTextture() {
        let filePath = Bundle.main.path(forResource: "for_test", ofType: "jpg")!
        let options: [String: NSNumber] = [GLKTextureLoaderOriginBottomLeft: 1]
        let texture = try? GLKTextureLoader.texture(withContentsOfFile: filePath, options: options)
        
        //create a base effect that provides standard OpenGL ES 2.0
        // shading language programs and set constant to be used for all subsequent rendering
        mEffect = GLKBaseEffect()
        mEffect?.texture2d0.enabled = GLboolean(GL_TRUE)
        mEffect?.texture2d0.name = texture!.name
        mEffect?.useConstantColor = GLboolean(GL_TRUE)
    }
    
    override func glkView(_ view: GLKView, drawIn rect: CGRect) {
        // set the background color stored in the current context
        // 设置当前OpenGL ES 的上下文的`清除颜色`, 用于在上下午的帧缓存在被清除时，初始化每个像素的颜色值
        glClearColor(0.3, 0.6, 1.0, 1.0)
        // clear frame buffer(erase previous drawing)
        // 设置当前绑定的帧缓存的每个像素颜色为glClearColor 设定的颜色
        glClear(GLbitfield(GL_COLOR_BUFFER_BIT))
        
        mEffect?.prepareToDraw()
        //3. 绘制
        // GL_TRIANGLES渲染三角形
        // 0 缓存内需要渲染的第一个顶点位置
        // 6 缓存中需要渲染的顶点输了你
        glDrawArrays(GLenum(GL_TRIANGLES), 0, 6)
        
        //GPU运算与CPU运算是异步的
    }


}
```
