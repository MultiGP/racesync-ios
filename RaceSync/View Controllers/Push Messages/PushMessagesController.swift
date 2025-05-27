//
//  PushMessagesController.swift
//  RaceSync
//
//  Created by Ignacio Romero Zurbuchen on 2025-05-20.
//  Copyright © 2025 MultiGP Inc. All rights reserved.
//
// https://www.multigp.com/MultiGP/views/sendNotification.php
//

import UIKit
import RaceSyncAPI

class PushMessagesController: NSObject {

    override init() {
        super.init()
        notificationCenter.delegate = self
        preloadDeliveredNotifications()

        notificationCenter.getNotificationSettings { settings in
            print("🔍 Notification settings: \(settings)")
        }
    }

    // MARK: - Public

    static let shared = PushMessagesController()
    let store = PushMessagesStore()

    var isMessagesViewShowing: Bool = false

    var notificationsCount: Int {
        get { return UIApplication.shared.applicationIconBadgeNumber }
        set { UIApplication.shared.applicationIconBadgeNumber = newValue}
    }

    // MARK: - Badge Count

    func clearPushMessagesCount() {
        notificationsCount = 0
    }

    func clearAllPushMessages() {
        clearPushMessagesCount()
        store.removeAll()
        notificationCenter.removeAllDeliveredNotifications()
    }

    // MARK: - Remote Notification Registration

    func isRegisteredForNotifications() -> Bool {
        return UIApplication.shared.isRegisteredForRemoteNotifications
    }

    func registerForNotifications() {

        notificationCenter.requestAuthorization(
            options: [.alert, .sound, .badge, .providesAppNotificationSettings]
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

    func didRegisterForNotifications(with deviceToken: Data, completion: StatusCompletionBlock?) {

        let parts = deviceToken.map { String(format: "%02.2hhx", $0) }
        let token = parts.joined()

        // Call 'update' if the device was already registered
        let action: PushAction = isRegisteredForNotifications() ? .update : .create

        userApi.registerPushNotification(forAction: action, deviceToken: token) { (status, error) in
            if let error = error {
                print("Failed to register device with API. Error: \(error.localizedDescription)")
            } else {
                if status {
                    print("Register device with API!")
                } else {
                    print("Failed to register device with API")
                }
            }

            completion?(status, error)
        }
    }

    // Called when the user tapped on the notification
    func didReceiveRemoteNotification(with userInfo: [AnyHashable : Any]) {

        print("Push notification in background : \(userInfo)")

        if isMessagesViewShowing {
            store.parseNotification(userInfo, broadcast: true)
        } else {
            store.parseNotification(userInfo)

            let vc = NavigationController(rootViewController: PushMessagesViewController())
            let animated = UIApplication.shared.applicationState == .active ? true : false
            UIViewController.topMostViewController()?.present(vc, animated: animated)
        }
    }

    func unregisterForNotifications(_ completion: StatusCompletionBlock?) {

        notificationCenter.removeAllPendingNotificationRequests()
        notificationCenter.removeAllDeliveredNotifications()
        UIApplication.shared.unregisterForRemoteNotifications()

        userApi.registerPushNotification(forAction: .delete) { (status, error) in
            if let error = error {
                print("Failed to register device with API. Error: \(error.localizedDescription)")
            } else {
                if status {
                    print("Unregister device with API!")
                } else {
                    print("Failed to register device with API")
                }
            }

            completion?(status, error)
        }
    }

    func failedToRegisterForNotifications(with error: Error) {
        print("Failed to register for remote notifications: \(error.localizedDescription)")
    }

    // MARK: - Private

    fileprivate let userApi = UserApi()
    fileprivate let notificationCenter = UNUserNotificationCenter.current()

    fileprivate func preloadDeliveredNotifications() {

        notificationCenter.getDeliveredNotifications { notifications in
            for notification in notifications {
                let content = notification.request.content
                self.store.parseNotification(content.userInfo) // no need to broadcast this event
            }
        }
    }

    fileprivate func handleNotificationPresentation(completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {

        if !isMessagesViewShowing {
            completionHandler([.banner, .sound])
        } else {
            completionHandler([])
        }
    }
}

extension PushMessagesController: UNUserNotificationCenterDelegate {

    // Called when a notification is received while app is in the foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                    willPresent notification: UNNotification,
                                    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {

        let content = notification.request.content
        print("Push notification in foreground : \(content.userInfo)")
        store.parseNotification(content.userInfo, broadcast: isMessagesViewShowing)

        handleNotificationPresentation(completionHandler: completionHandler)
    }

    // Triggered whether the app is in background, foreground, or terminated
    private func userNotificationCenter(_ center: UNUserNotificationCenter,
                                        didReceive response: UNNotificationResponse,
                                        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {

        let content = response.notification.request.content
        print("Push notification tapped : \(content.userInfo)")
        store.parseNotification(content.userInfo, broadcast: isMessagesViewShowing)

        handleNotificationPresentation(completionHandler: completionHandler)
    }

    // Called when the application is launched in response to the user's request to view in-app notification settings.
    func userNotificationCenter(_ center: UNUserNotificationCenter, openSettingsFor notification: UNNotification?) {

        print("Push notification in-app notification settings")
    }
}
