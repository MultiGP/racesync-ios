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
        preloadDeliveredNotifications()
        refreshPushNotificationSettings()
    }

    // MARK: - Public

    static let shared = PushMessagesController()
    let store = PushMessagesStore()
    var authorizationStatus: UNAuthorizationStatus?

    var isMessagesViewShowing: Bool = false

    // MARK: - Badge Count

    func clearAllPushMessages() {
        store.removeAll()
        notificationCenter.removeAllDeliveredNotifications()
    }

    // MARK: - Remote Notification Registration

    func refreshPushNotificationSettings() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            self.authorizationStatus = settings.authorizationStatus
        }
    }

    func isPushNotificationsEnabled() -> Bool {
        return isAllowingNotifications() && isRegisteredForNotifications()
    }

    func isAllowingNotifications() -> Bool {
        guard let status = self.authorizationStatus else { return false }
        return (status == .authorized || status == .provisional)
    }

    func isRegisteredForNotifications() -> Bool {
        return UIApplication.shared.isRegisteredForRemoteNotifications
    }

    func requestAuthorizationPushNotifications() {

        notificationCenter.requestAuthorization(
            options: [.alert, .sound, .badge, .providesAppNotificationSettings]
           ) { granted, error in
               if granted {
                   DispatchQueue.main.async {
                       UIApplication.shared.registerForRemoteNotifications()
                   }
               } else {
                   Clog.log("Notification permission denied: \(error?.localizedDescription ?? "No error info")")
               }
           }
    }

    func didRegisterForPushNotifications(with deviceToken: Data, completion: StatusCompletionBlock? = nil) {

        let parts = deviceToken.map { String(format: "%02.2hhx", $0) }
        let token = parts.joined()

        // Call 'update' if the device was already registered
        let action: PushAction = isRegisteredForNotifications() ? .update : .create

        refreshPushNotificationSettings()

        userApi.registerPushNotification(forAction: action, deviceToken: token) { (status, error) in
            if let error = error {
                Clog.log("Failed to register device with API. Error: \(error.localizedDescription)")
            } else {
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .registeredForPushMessages, object: status)
                }

                Clog.log(status ? "Unregister device with API!" : "Failed to register device with API")
            }

            completion?(status, error)
        }
    }

    // Called when the user tapped on the notification
    func didReceivePushNotification(with userInfo: [AnyHashable : Any]) {

        Clog.log("Push notification in background : \(userInfo)")

        if isMessagesViewShowing {
            store.parseNotification(userInfo, broadcast: true)
        } else if let message = store.parseNotification(userInfo) {
            let vc = PushMessagesViewController(with: message)
            let nc = NavigationController(rootViewController: vc)
            let animated = UIApplication.shared.applicationState == .active ? true : false
            UIViewController.topMostViewController()?.present(nc, animated: animated)
        }
    }

    func unregisterForPushNotifications(_ completion: StatusCompletionBlock? = nil) {

        notificationCenter.removeAllPendingNotificationRequests()
        notificationCenter.removeAllDeliveredNotifications()
        UIApplication.shared.unregisterForRemoteNotifications() // TODO: is this really required?

        refreshPushNotificationSettings()

        userApi.registerPushNotification(forAction: .delete) { (status, error) in
            if let error = error {
                Clog.log("Failed to register device with API. Error: \(error.localizedDescription)")
            } else {
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .registeredForPushMessages, object: status)
                }
                
                Clog.log(status ? "Unregister device with API!" : "Failed to unregister device with API")
            }

            completion?(status, error)
        }
    }

    func failedToRegisterForPushNotifications(with error: Error) {
        Clog.log("Failed to register for remote notifications: \(error.localizedDescription)")
    }

    func preloadDeliveredNotifications() {

        notificationCenter.getDeliveredNotifications { notifications in
            for notification in notifications {
                let content = notification.request.content
                self.store.parseNotification(content.userInfo) // no need to broadcast this event
            }
        }
    }

    // MARK: - Private

    fileprivate let userApi = UserApi()
    fileprivate let notificationCenter = UNUserNotificationCenter.current()

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
        Clog.log("Push notification in foreground : \(content.userInfo)")
        store.parseNotification(content.userInfo, broadcast: isMessagesViewShowing)

        handleNotificationPresentation(completionHandler: completionHandler)
    }

    // Triggered whether the app is in background, foreground, or terminated
    private func userNotificationCenter(_ center: UNUserNotificationCenter,
                                        didReceive response: UNNotificationResponse,
                                        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {

        let content = response.notification.request.content
        Clog.log("Push notification tapped : \(content.userInfo)")
        store.parseNotification(content.userInfo, broadcast: isMessagesViewShowing)

        handleNotificationPresentation(completionHandler: completionHandler)
    }

    // Called when the application is launched in response to the user's request to view in-app notification settings.
    func userNotificationCenter(_ center: UNUserNotificationCenter, openSettingsFor notification: UNNotification?) {

        Clog.log("Push notification in-app notification settings")
    }
}

extension Notification.Name {
    static let registeredForPushMessages = Notification.Name("com.racecync.registeredForPushMessages")
}
