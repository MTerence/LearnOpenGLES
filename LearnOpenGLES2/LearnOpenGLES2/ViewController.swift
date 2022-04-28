//
//  ViewController.swift
//  LearnOpenGLES2
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
class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let learnView = LearnView(frame: view.bounds)
        view.addSubview(learnView)
    }

}

