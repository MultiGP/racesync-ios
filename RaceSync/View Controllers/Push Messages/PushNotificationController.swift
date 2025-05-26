//
//  PushNotificationController.swift
//  RaceSync
//
//  Created by Ignacio Romero Zurbuchen on 2025-05-20.
//  Copyright © 2025 MultiGP Inc. All rights reserved.
//
// https://www.multigp.com/MultiGP/views/sendNotification.php
//

import UIKit
import RaceSyncAPI

class PushNotificationController: NSObject {

    public static let shared = PushNotificationController()

    fileprivate let userApi = UserApi()
    fileprivate let notificationCenter = UNUserNotificationCenter.current()

    typealias ObjectCompletionBlock<T> = (_ result: [T]) -> Void

    // MARK: - Public Variables

    var notificationCount: Int {
        get { return UIApplication.shared.applicationIconBadgeNumber }
        set { UIApplication.shared.applicationIconBadgeNumber = newValue}
    }

    // MARK: - Stored Notification Fetching

    func getNotificationMessages(_ completion: @escaping ObjectCompletionBlock<PushMessage>) {

        notificationCenter.getDeliveredNotifications { notifications in
                let messages: [PushMessage] = notifications.map { notification in
                    let content = notification.request.content

                    let apnsId = notification.request.identifier
                    let title = content.title
                    let detail = content.body
                    let timestamp = notification.date.timeIntervalSince1970

                    return PushMessage(apnsId: apnsId, title: title, detail: detail, timestamp: timestamp)
                }

                completion(messages)
            }
    }

    func clearNotificationMessage(_ message: PushMessage) {

        guard let identifier = message.apnsId else { return }
        notificationCenter.removeDeliveredNotifications(withIdentifiers: [identifier])
    }

    func clearAllNotificationMessages() {
        
        notificationCenter.removeAllDeliveredNotifications()
    }

    // MARK: - Remote Notification Registration

    func isRegisteredForNotifications() -> Bool {
        return UIApplication.shared.isRegisteredForRemoteNotifications
    }

    func registerForNotifications() {

        notificationCenter.delegate = self
        notificationCenter.requestAuthorization(
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

extension PushNotificationController: UNUserNotificationCenterDelegate {

    // Called when a notification is received while app is in the foreground
    func userNotificationCenter( _ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler:
        @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let userInfo = notification.request.content.userInfo
        print("Push notification foreground: \(userInfo)")

        // Show the notification (banner, sound, etc.)
        completionHandler([.banner, .sound])
    }

    // Called when the user tapped on the notification
    // Triggered whether the app is in background, foreground, or terminated
    fileprivate func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler:
        @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        print("Push notification tapped: \(userInfo)")

        // Show the notification (banner, sound, etc.)
        completionHandler([.banner, .sound])
    }

    func application(_ application: UIApplication,
                     didReceiveRemoteNotification userInfo: [AnyHashable : Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        print("Push notification background: \(userInfo)")

        completionHandler(.newData)
    }
}

fileprivate class PushNotificationStore {

    private static let key = "storedMessages"

    static func save(_ messages: [PushMessage]) {
        if let data = try? JSONEncoder().encode(messages) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    static func load() -> [PushMessage] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let messages = try? JSONDecoder().decode([PushMessage].self, from: data) else {
            return []
        }
        return messages
    }

    static func add(_ message: PushMessage) {
        var current = load()
        current.append(message)
        save(current)
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}
