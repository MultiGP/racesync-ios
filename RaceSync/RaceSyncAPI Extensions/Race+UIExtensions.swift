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

    var canShowResults: Bool {
        if isFinalized { return true } // Assume results should be displayed since the race is finalized already
        guard let results = results, results.count > 0 else { return false }
        guard let startDate = startDate else { return false }
        return startDate.isPassed
    }

    var canShowSchedule: Bool {
        return isZippyQEnabled && !isFinalized
    }

    func canCreateCalendarEvent() -> Bool {
        if let endDate = endDate, endDate.isPassed {
            return false
        }
        else if let startDate = startDate, startDate.isPassed(by: 1) {
            return false
        }
        else {
            return true
        }
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
