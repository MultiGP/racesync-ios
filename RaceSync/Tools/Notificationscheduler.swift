//
//  NotificationScheduler.swift
//  RaceSync
//
//  Created by Ignacio Romero Zurbuchen on 2026-05-23.
//  Copyright © 2026 MultiGP Inc. All rights reserved.
//

import Foundation
import UserNotifications

/// Generic local notification scheduler.
class NotificationScheduler {

    // MARK: - Singleton

    static let shared = NotificationScheduler()

    // MARK: - Scheduling

    /// Schedules a local notification at the given trigger date.
    /// - Parameters:
    ///   - identifier: Unique string to identify this notification (used to cancel it later).
    ///   - title: Notification title.
    ///   - body: Notification body.
    ///   - triggerDate: The exact date/time to fire the notification.
    ///   - userInfo: Optional dictionary attached to the notification content.
    public func schedule(identifier: String, title: String, body: String, triggerDate: Date, userInfo: [String: Any] = [:]
    ) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.userInfo = userInfo

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: triggerDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        center.add(request) { error in
            if let error = error {
                print("Failed to schedule '\(identifier)': \(error)")
            } else {
                print("Scheduled '\(identifier)' for \(triggerDate)")
            }
        }
    }

    // MARK: - Cancellation

    public func cancel(identifier: String) {
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        print("Cancelled '\(identifier)'")
    }

    public func cancelAll() {
        center.removeAllPendingNotificationRequests()
    }

    // MARK: - Inspection

    public func getPending(completion: @escaping ([UNNotificationRequest]) -> Void) {
        center.getPendingNotificationRequests { requests in
            DispatchQueue.main.async { completion(requests) }
        }
    }
    
    private var center = UNUserNotificationCenter.current()
}
