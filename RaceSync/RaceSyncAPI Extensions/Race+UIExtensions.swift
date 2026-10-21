//
//  Race+UIExtensions.swift
//  RaceSync
//
//  Created by Ignacio Romero Zurbuchen on 2023-01-16.
//  Copyright © 2023 MultiGP Inc. All rights reserved.
//

import Foundation
import RaceSyncAPI

/// A calendar-based interpretation of a race schedule, not its actual live state.
enum RaceScheduleState {
    case unknown
    case upcoming
    case current
    case past
}

extension Race {

    var scheduledEndDate: Date? {
        return endDate ?? startDate
    }

    var scheduleState: RaceScheduleState {
        guard let startDate, let scheduledEndDate else { return .unknown }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        if today < calendar.startOfDay(for: startDate) {
            return .upcoming
        }
        if today > calendar.startOfDay(for: scheduledEndDate) {
            return .past
        }
        return .current
    }

    /// Returns whether the current day falls within the scheduled race window,
    /// optionally extended before its start and after its end.
    func isWithinScheduledWindow(startingDaysBefore: Int = 0,
                                 endingDaysAfter: Int = 0) -> Bool {
        guard let startDate, let scheduledEndDate else { return false }
        let calendar = Calendar.current
        let windowStartDate = calendar.date(
            byAdding: .day,
            value: -startingDaysBefore,
            to: calendar.startOfDay(for: startDate)
        ) ?? startDate
        let windowEndDate = calendar.date(
            byAdding: .day,
            value: endingDaysAfter,
            to: calendar.startOfDay(for: scheduledEndDate)
        ) ?? scheduledEndDate
        let today = calendar.startOfDay(for: Date())
        return today >= windowStartDate && today <= windowEndDate
    }

    var canShowResults: Bool {
        guard let results = results, results.count > 0 else { return false }

        return results.contains { $0.hasResults }
    }

    var canShowZippyQ: Bool {
        return isZippyQEnabled
    }

    func canCreateCalendarEvent() -> Bool {
        return scheduleState != .past
    }

    func createCalendarEvent(with raceId: ObjectId) -> CalendarEvent? {
        let raceURL = URL(string: MGPWeb.getUrl(for: .raceView, value: raceId))

        guard canCreateCalendarEvent(), let startDate = startDate, let address = address else {
            return nil
        }

        let content = content.stripHTML()
        return CalendarEvent(title: name, location: address, description: content, startDate: startDate, endDate: endDate, url: raceURL)
    }
}
