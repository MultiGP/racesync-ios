//
//  NotificationScheduler+EventSession.swift
//  RaceSync
//
//  Created by Ignacio Romero Zurbubach on 2026-05-23.
//  Copyright © 2026 MultiGP Inc. All rights reserved.
//

import Foundation
import RaceSyncAPI
import ObjectMapper

// MARK: - EventSession Notification Keys

enum SessionNotificationKey {
    static let sessionJSON = "sessionJSON"
    static let categoryIdentifier = "EventSession"
}

// MARK: - NotificationScheduler + EventSession

extension NotificationScheduler {

    /// Schedules a local notification 1 hour before the session's startTime.
    /// Silently skips if startTime is missing or already in the past.
    func schedule(for session: EventSession, for hours: Double = 1) {
        let center = UNUserNotificationCenter.current()

        center.getNotificationSettings { [weak self] settings in
            switch settings.authorizationStatus {
            case .authorized, .provisional:
                self?.scheduleNotification(for: session, for: hours)

            case .notDetermined:
                center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                    if let error = error {
                        print("Auth error: \(error)")
                        return
                    }
                    if granted {
                        self?.scheduleNotification(for: session, for: hours)
                    }
                }

            case .denied, .ephemeral:
                print("Notifications not authorized, skipping session \(session.id).")

            @unknown default:
                break
            }
        }
    }
    
    private func scheduleNotification(for session: EventSession, for hours: Double = 1) {
                
        guard let startTime = session.startTime else {
            print("Session \(session.id) has no startTime, skipping.")
            return
        }

        let triggerDate = startTime.addingTimeInterval(-3600*hours) // 1 or more hours before

        guard triggerDate > Date() else {
            print("Session \(session.id) trigger date is in the past, skipping.")
            return
        }
        
        let title = "🔔 IO16: Your next event is up!"
        let body = sessionNotificationBody(for: session)

        // Pack the full session as JSON into userInfo for use when the notification is tapped
        let userInfo: [String: Any] = [
            SessionNotificationKey.sessionJSON: session.toJSONString() ?? "",
            SessionNotificationKey.categoryIdentifier: true
        ]
        
        schedule(identifier: session.id, title: title, body: body, triggerDate: triggerDate, userInfo: userInfo)
        
        if !AppplicationPreferences.hideNotificationSchedulerAlerts {
            AlertUtil.presentAlertMessage("We will notify you one (1) hour before '\(session.activity)' starts on \(session.dayName).",
                                          title: "Added to your bucket list",
                                          okTitle: "Don't Show Again", cancelTitle: "OK") { action in
                AppplicationPreferences.hideNotificationSchedulerAlerts = true
            }
        }
    }

    /// Cancels the scheduled notification for the given session.
    func cancel(for session: EventSession) {
        cancel(identifier: session.id)

        if !AppplicationPreferences.hideNotificationSchedulerAlerts {
            AlertUtil.presentAlertMessage("",
                                          title: "Removed from bucket list",
                                          okTitle: "Don't Show Again", cancelTitle: "OK") { action in
                AppplicationPreferences.hideNotificationSchedulerAlerts = true
            }
        }
    }

    /// Reconstructs an EventSession from a notification's userInfo, if present.
    func session(from userInfo: [AnyHashable: Any]) -> EventSession? {
        guard let jsonString = userInfo[SessionNotificationKey.sessionJSON] as? String else { return nil }
        return EventSession(JSONString: jsonString)
    }

    // MARK: - Private

    private func sessionNotificationBody(for session: EventSession) -> String {
        
        if let start = session.startTime {
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"
            formatter.timeZone = MGPEventTimeZone
            
            return "'\(session.activity)' starts at \(formatter.string(from: start))."
        } else {
            return "'\(session.activity)' starts in 1 hour." // in track.name
        }
    }
}
