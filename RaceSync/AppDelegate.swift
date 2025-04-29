//
//  AppDelegate.swift
//  RaceSync
//
//  Created by Ignacio Romero Zurbuchen on 2019-10-23.
//  Copyright © 2019 MultiGP Inc. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    // MARK: - Public Variables

    var window: UIWindow?
    var orientationLock: UIInterfaceOrientationMask = .portrait

    // MARK: - UIApplicationDelegate Methods

    func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        Appearance.configureUIAppearance()
        return true
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    #if !DEBUG
        EventTracker.configure()
    #endif
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) { }

    func applicationDidEnterBackground(_ application: UIApplication) { }

    func applicationWillEnterForeground(_ application: UIApplication) { }

    func applicationDidBecomeActive(_ application: UIApplication) { }

    func applicationWillTerminate(_ application: UIApplication) { }

    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return self.orientationLock;
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        return true
    }

    public func registerForAPNs() {

        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(
               options: [.alert, .sound, .badge]
           ) { granted, error in
               if granted {
                   DispatchQueue.main.async {
                       UIApplication.shared.registerForRemoteNotifications()
                   }
               } else {
                   print("Notification permission denied: \(error?.localizedDescription ?? "No error info")")
               }
           }
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenParts = deviceToken.map { String(format: "%02.2hhx", $0) }
        let token = tokenParts.joined()
        print("Device Token: \(token)")
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notifications: \(error.localizedDescription)")
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {

    // For in-app notification handling
    func userNotificationCenter( _ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler:
        @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}

