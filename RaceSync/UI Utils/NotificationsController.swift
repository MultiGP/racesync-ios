//
//  NotificationsController.swift
//  RaceSync
//
//  Created by Ignacio Romero Zurbuchen on 2025-04-28.
//  Copyright © 2025 MultiGP Inc. All rights reserved.
//

import Foundation
import UserNotifications

class NotificationsController: NSObject {

    public static let shared = NotificationsController()


}

extension NotificationsController: UNUserNotificationCenterDelegate {

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler:
        @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}
