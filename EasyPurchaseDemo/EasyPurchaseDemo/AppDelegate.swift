//
//  AppDelegate.swift
//  EasyPurchaseDemo
//
//  Created by rex on 27/9/23.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    // This method is called when the app finishes launching.
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        return true
    }
    
    // This method is called when the app is about to become inactive, e.g., when a phone call is received.
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state.
        // This can occur for certain types of temporary interruptions (e.g., an incoming phone call).
    }
    
    // This method is called when the app enters the background.
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough app state information to restore your app to its current state.
    }
    
    // This method is called when the app enters the foreground.
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state.
        // Here, you can undo many of the changes made on entering the background.
    }
    
    // This method is called when the app becomes active again (e.g., after returning from the background).
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the app was inactive.
    }
    
    // This method is called when the app is about to terminate. Save data if appropriate.
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate.
        // Save data if appropriate. See also applicationDidEnterBackground.
    }
}
