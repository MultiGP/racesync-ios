//
//  ResultEntryViewModel.swift
//  RaceSync
//
//  Created by Ignacio Romero Zurbuchen on 2024-12-19.
//  Copyright © 2024 MultiGP Inc. All rights reserved.
//

import RaceSyncAPI
import UIKit

class ResultEntryViewModel: Descriptable {

    let entry: ResultEntry
    let lapCount: Int
    let resultLabel: String?

    init(with entry: ResultEntry, from race: Race) {
        self.entry = entry
        self.resultLabel = Self.resultLabel(for: entry, for: race)
        self.lapCount = Self.resultLapCount(for: entry)
    }
}

extension ResultEntryViewModel {

    static let noResultPlaceholder: String = "Did not complete laps"

    static func combinedResults(from entries: [ResultEntry]?, for scoringFormat: ScoringFormat) -> [ResultEntry]? {
        guard let entries = entries else { return nil }

        enum SortOrder {
            case lowest
            case highest
        }

        let formatMapping: [ScoringFormat: (key: KeyPath<ResultEntry, String?>, order: SortOrder)] = [
            .aggregateLap: (\.totalLaps, .highest),
            .fastestLap: (\.fastestLap, .lowest),
            .fastest2Laps: (\.fastest2Laps, .lowest),
            .fastest3Laps: (\.fastest3Laps, .lowest)
        ]

        guard let format = formatMapping[scoringFormat] else { return nil }

        let unique = entries.reduce(into: [ObjectId: ResultEntry]()) { dict, entry in
            guard let newValue = Double(entry[keyPath: format.key] ?? "") else { return }
            guard newValue > 0 && newValue < 1500 else { return } // a value can't be over 15 minutes, else it's considered invalid

            if let oldEntry = dict[entry.pilotId],
               let oldValue = Double(oldEntry[keyPath: format.key] ?? "") {
                if format.order == .lowest, oldValue < newValue { return }
                if format.order == .highest, oldValue > newValue { return }
            }

            dict[entry.pilotId] = entry
        }

        guard unique.count > 0 else { return nil }

        return unique.values.sorted {
            let value1 = Double($0[keyPath: format.key] ?? "") ?? .greatestFiniteMagnitude
            let value2 = Double($1[keyPath: format.key] ?? "") ?? .greatestFiniteMagnitude

            return format.order == .lowest ? value1 < value2 : value1 > value2
        }
    }
}

fileprivate extension ResultEntryViewModel {

    static func resultLabel(for entry: ResultEntry, for race: Race) -> String? {

        let format = race.trueScoringFormat
        var resultLabel: String = ""

        // Needs at least 1 lap
        let laps = resultLapCount(for: entry)

        if format == .aggregateLap, laps > 0 {
            resultLabel += " \(laps) Laps"
        } else {
            var time: String?

            if format == .fastestLap {
                time = entry.fastestLap
            } else if format == .fastest2Laps {
                time = entry.fastest2Laps
            } else if format == .fastest3Laps {
                time = entry.fastest3Laps
            }

            if let time = time {
                resultLabel += TimeUtil.lapTimeFormat(seconds: time)
            }
        }

        if resultLabel.count > 0, let roundLabel = Self.roundLabel(for: entry, for: race) {
            resultLabel += " \(roundLabel)"
        }

        return resultLabel.count > 0 ? resultLabel : nil
    }

    static func roundLabel(for raceEntry: ResultEntry, for race: Race) -> String? {
        guard let schedule = race.schedule else { return "" }
        for round in schedule.rounds {
            for heat in round.heats {
                if heat.entries.contains(where: { $0.id == raceEntry.id }) {
                    if let number = round.number {
                        return "(Best Round: \(number))"
                    }
                }
            }
        }
        return  nil
    }

    static func resultLapCount(for raceEntry: ResultEntry) -> Int {
        guard let laps = Int(raceEntry.totalLaps ?? "0") else { return 0 }
        return laps
    }
}
