//
//  PushNotificationController.swift
//  RaceSync
//
//  Created by Ignacio Romero Zurbuchen on 2025-05-20.
//  Copyright © 2025 MultiGP Inc. All rights reserved.
//

import UIKit
import RaceSyncAPI

class PushNotificationController {

    fileprivate let userApi = UserApi()
    fileprivate static let notificationCenter = UNUserNotificationCenter.current()

    typealias ObjectCompletionBlock<T> = (_ result: [T]) -> Void

    // MARK: - Remote Notification Fetching

    static func getNotificationMessages(_ completion: @escaping ObjectCompletionBlock<Message>) {

        notificationCenter.getDeliveredNotifications { notifications in
                let messages: [Message] = notifications.map { notification in
                    let content = notification.request.content

                    let apnsId = notification.request.identifier
                    let title = content.title
                    let detail = content.body
                    let timestamp = notification.date.timeIntervalSince1970

                    return Message(apnsId: apnsId, title: title, detail: detail, timestamp: timestamp)
                }

                completion(messages)
            }
    }

    static func clearNotificationMessage(_ message: Message) {

        notificationCenter.removeDeliveredNotifications(withIdentifiers: [message.apnsId])
    }

    static func clearAllNotificationMessages() {
        
        notificationCenter.removeAllDeliveredNotifications()
    }

    // MARK: - Remote Notification Registration

    static func isRegisteredForNotifications() -> Bool {
        return UIApplication.shared.isRegisteredForRemoteNotifications
    }

    func registerForNotifications(with deviceToken: Data) {

        let parts = deviceToken.map { String(format: "%02.2hhx", $0) }
        let token = parts.joined()

        // Call 'update' if the device was already registered
        let action: PushAction = Self.isRegisteredForNotifications() ? .update : .create

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

        userApi.registerPushNotification(forAction: .delete) { (status, error) in
            if status {
                Self.notificationCenter.removeAllPendingNotificationRequests()
                Self.notificationCenter.removeAllDeliveredNotifications()
                UIApplication.shared.unregisterForRemoteNotifications()
            }

            completion(status, error)
        }
    }

    func failedToRegisterForNotifications(with error: Error) {
        print("Failed to register for remote notifications: \(error.localizedDescription)")
    }
}

class PushNotificationStore {

    private static let key = "storedMessages"

    static func save(_ messages: [Message]) {
        if let data = try? JSONEncoder().encode(messages) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    static func load() -> [Message] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let messages = try? JSONDecoder().decode([Message].self, from: data) else {
            return []
        }
        return messages
    }

    static func add(_ message: Message) {
        var current = load()
        current.append(message)
        save(current)
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}
