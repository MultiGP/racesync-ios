//
//  RaceEntry+UIExtensions.swift
//  RaceSync
//
//  Created by Ignacio Romero on 2026-08-15.
//  Copyright © 2026 MultiGP Inc. All rights reserved.
//

import RaceSyncAPI

extension ResultEntry {

    var hasResults: Bool {
        return hasResultValues(
            score,
            totalLaps,
            totalTime,
            fastestLap,
            fastest2Laps,
            fastest3Laps
        )
    }
}

extension ZippyqEntry {

    var hasResults: Bool {
        return hasResultValues(
            score,
            totalLaps,
            totalTime,
            fastestLap,
            fastest2Laps,
            fastest3Laps
        )
    }
}

private func hasResultValues(_ values: String?...) -> Bool {
    return values.contains { $0?.isEmpty == false }
}
