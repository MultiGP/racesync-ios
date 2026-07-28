//
//  Race+UIExtensions.swift
//  RaceSync
//
//  Created by Ignacio Romero Zurbuchen on 2023-01-16.
//  Copyright © 2023 MultiGP Inc. All rights reserved.
//

import Foundation
import RaceSyncAPI

extension Race {

    var hasStarted: Bool {
        guard let startDate = startDate else { return false }
        return startDate.isPassed
    }
    
    func hasEnded(extendedByDays days: Int = 0) -> Bool {
        guard let referenceDate = endDate ?? startDate else { return false }
        let calendar = Calendar.current
        let extendedDate = calendar.date(byAdding: .day, value: days, to: calendar.startOfDay(for: referenceDate)) ?? referenceDate
        return calendar.startOfDay(for: Date()) > extendedDate
    }

    var hasEnded: Bool { hasEnded(extendedByDays: 0) }

    var inProgress: Bool {
        guard !isFinalized else { return false }
        return hasStarted && !hasEnded
    }

    var canShowResults: Bool {
        guard let results = results, results.count > 0 else { return false }

        return results.contains { entry in
            [entry.score, entry.totalLaps, entry.totalTime, entry.fastest3Laps, entry.fastest2Laps, entry.fastestLap]
                .contains { $0 != nil && !$0!.isEmpty }
        }
    }

    var canShowZippyQ: Bool {
//        guard hasStarted && !hasEnded else { return false }
        return isZippyQEnabled
    }

    func canCreateCalendarEvent() -> Bool {
        guard !hasEnded else { return false }
        return true
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
