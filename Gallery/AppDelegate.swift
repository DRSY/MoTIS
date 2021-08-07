//
//  AppDelegate.swift
//  Gallery
//
//  Created by Alex on 16.02.2021.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = GalleryBilder.getGalleryVC()
        window?.makeKeyAndVisible()
        
        return true
    }

}

