//
//  CalendarUtil.swift
//  RaceSync
//
//  Created by Ignacio Romero Zurbuchen on 2020-01-14.
//  Copyright © 2020 MultiGP Inc. All rights reserved.
//

import UIKit
import EventKit
import RaceSyncAPI

struct CalendarEvent {
    let title: String
    let location: String
    let description: String
    let startDate: Date
    let endDate: Date?
    let url: URL?
}

class CalendarUtil {

    static func add(_ event: CalendarEvent) {
        let eventStore = EKEventStore()

        eventStore.requestAccess(to: .event) { (granted, error) in
            guard granted else { return }

            let ekevent = EKEvent(eventStore: eventStore)
            ekevent.title = event.title
            ekevent.location = event.location
            ekevent.notes = event.description
            ekevent.startDate = event.startDate
            ekevent.endDate = (event.endDate != nil) ? event.endDate : event.startDate.advanced(by: 3600) // add 1 hour diff
            ekevent.url = event.url
            ekevent.calendar = eventStore.defaultCalendarForNewEvents
            ekevent.isAllDay = false

            do {
                try eventStore.save(ekevent, span: .thisEvent) // saves the event to the calendar

                var buttonTitle: String? = nil
                var completion: AlertCompletionBlock?

                if let calendarURL = URL(string: ExternalAppSchemes.CalendarScheme), UIApplication.shared.canOpenURL(calendarURL) {
                    buttonTitle = "View Calendar"
                    completion = { action in
                        UIApplication.shared.open(calendarURL, options: [:], completionHandler: nil)
                    }
                }

                AlertUtil.presentAlertMessage("\(event.title) saved in your calendar!", title: "Event Saved", buttonTitle: buttonTitle, delay: 0.5, completion: completion)

            }  catch {
                Clog.log("error saving to calendar: \(error.localizedDescription)")

                AlertUtil.presentAlertMessage("The event couldn't be saved in your calendar.\n\(error.localizedDescription)", title: "Error", delay: 0.5)
            }
        }
    }
}
