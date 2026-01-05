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

    var hasEnded: Bool {
        guard let startDate = startDate else { return false }

        if let endDate = endDate, startDate.isPassed {
            return endDate.isPassed(hours: 2)
        }
        return startDate.isPassed(hours: 8)
    }

    var inProgress: Bool {
        guard !isFinalized else { return false }
        return hasStarted && !hasEnded
    }

    var canShowResults: Bool {
        if isFinalized { return true } // Assume results should be displayed since the race is finalized already
        guard let results = results, results.count > 0 else { return false }
        return hasStarted
    }

    var canShowSchedule: Bool {
        return isZippyQEnabled && !isFinalized
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
