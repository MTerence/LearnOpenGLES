//
//  AppDelegate.swift
//  LearnOpenGLES3
//
//  Created by Ternence on 2022/4/22.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.backgroundColor = .white
        let vc = ViewController()
        window.rootViewController = vc
        window.makeKeyAndVisible()
        self.window = window
        
        return true
    }


}

