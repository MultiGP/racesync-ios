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

    public static let shared = PushMessagesController()
    public let store = PushMessagesStore()

    fileprivate let userApi = UserApi()
    fileprivate let notificationCenter = UNUserNotificationCenter.current()

    typealias ObjectCompletionBlock<T> = (_ result: [T]) -> Void

    override init() {
        super.init()
        notificationCenter.delegate = self
        preloadDeliveredNotifications()
    }

    // MARK: - Public Variables

    var notificationsCount: Int {
        get { return UIApplication.shared.applicationIconBadgeNumber }
        set { UIApplication.shared.applicationIconBadgeNumber = newValue}
    }

    // MARK: - Stored Notification Fetching

//    func getNotificationMessages(_ completion: @escaping ObjectCompletionBlock<PushMessage>) {
//
//        notificationCenter.getDeliveredNotifications { notifications in
//                let messages: [PushMessage] = notifications.map { notification in
//                    let content = notification.request.content
//
//                    let title = content.title
//                    let detail = content.body
//                    let timestamp = notification.date.timeIntervalSince1970
//
//                    return PushMessage(title: title, detail: detail, timestamp: timestamp)
//                }
//
//                completion(messages)
//            }
//    }

    func clearNotificationsCount() {
        notificationsCount = 0
    }

    func clearAllNotificationMessages() {

        clearNotificationsCount()
        notificationCenter.removeAllDeliveredNotifications()
        store.removeAll()
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

    func didRegisterForNotifications(with deviceToken: Data) {

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
        }
    }

    func didReceiveRemoteNotification(with userInfo: [AnyHashable : Any]) {

        print("Push notification in background : \(userInfo)")

        store.parseNotification(userInfo)
    }

    func unregisterForNotifications(_ completion: @escaping StatusCompletionBlock) {

        notificationCenter.removeAllPendingNotificationRequests()
        notificationCenter.removeAllDeliveredNotifications()
        UIApplication.shared.unregisterForRemoteNotifications()

        userApi.registerPushNotification(forAction: .delete, completion)
    }

    func failedToRegisterForNotifications(with error: Error) {
        print("Failed to register for remote notifications: \(error.localizedDescription)")
    }
}

extension PushMessagesController: UNUserNotificationCenterDelegate {

    // Called when a notification is received while app is in the foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {

        let content = notification.request.content
        print("Push notification in foreground : \(content.userInfo)")

        store.parseNotification(content.userInfo)

        // Show the notification (banner, sound, etc.)
        completionHandler([.banner, .sound])
    }

    // Called when the user tapped on the notification
    // Triggered whether the app is in background, foreground, or terminated
    private func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {

        let content = response.notification.request.content
        print("Push notification tapped : \(content.userInfo)")
        store.parseNotification(content.userInfo)

        // Show the notification (banner, sound, etc.)
        completionHandler([.banner, .sound])
    }

    // Called when the application is launched in response to the user's request to view in-app notification settings.
    func userNotificationCenter(_ center: UNUserNotificationCenter, openSettingsFor notification: UNNotification?) {

        print("Push notification in-app notification settings")
    }
}

extension PushMessagesController {

    fileprivate func preloadDeliveredNotifications() {

        notificationCenter.getDeliveredNotifications { notifications in
            for notification in notifications {
                let content = notification.request.content
                self.store.parseNotification(content.userInfo)
            }
        }
    }
}
