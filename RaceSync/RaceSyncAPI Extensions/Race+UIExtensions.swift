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

    func canCreateCalendarEvent() -> Bool {

        guard let startDate = startDate, startDate.timeIntervalSinceNow.sign == .plus else {
            return false
        }

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
