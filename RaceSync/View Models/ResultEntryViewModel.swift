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
    let resultLabel: String?
    let lapCount: Int

    init(with entry: ResultEntry, from race: Race) {
        self.entry = entry
        self.resultLabel = Self.resultLabel(for: entry, for: race)
        self.lapCount = Self.resultLapCount(for: entry)
    }
}

extension ResultEntryViewModel {

    static let noResultPlaceholder: String = "Did not complete laps"
    static let noTimesPlaceholder: String = "Race times unavailable"

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

        var resultLabel: String = ""

        if let formattedResult = formattedResult(for: race.trueScoringFormat,
                                                 totalLaps: entry.totalLaps,
                                                 fastestLap: entry.fastestLap,
                                                 fastest2Laps: entry.fastest2Laps,
                                                 fastest3Laps: entry.fastest3Laps) {
            resultLabel += formattedResult
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
        return resultLapCount(for: raceEntry.totalLaps)
    }

    static func resultLapCount(for totalLaps: String?) -> Int {
        guard let laps = Int(totalLaps ?? "0") else { return 0 }
        return laps
    }
}

extension ResultEntryViewModel {

    static func formattedResult(for scoringFormat: ScoringFormat,
                                totalLaps: String?,
                                fastestLap: String?,
                                fastest2Laps: String?,
                                fastest3Laps: String?,
                                bestAvailable: Bool = false) -> String? {

        if scoringFormat == .aggregateLap {
            let laps = resultLapCount(for: totalLaps)
            guard laps > 0 else { return "No Laps" }
            return "\(laps) \(laps == 1 ? "Lap" : "Laps")"
        }

        if bestAvailable {
            let results = [
                (lapCount: 3, time: fastest3Laps),
                (lapCount: 2, time: fastest2Laps),
                (lapCount: 1, time: fastestLap)
            ]

            for result in results {
                guard let time = result.time, let seconds = Double(time), seconds > 0 else { continue }
                return "\(result.lapCount) / \(TimeUtil.lapTimeFormat(seconds: time))"
            }
            return "DNF"
        } else {
            let time: String?
            switch scoringFormat {
            case .fastestLap:
                time = fastestLap
            case .fastest2Laps:
                time = fastest2Laps
            case .fastest3Laps:
                time = fastest3Laps
            case .aggregateLap:
                time = nil // returned earlier
            }
            guard let time, let seconds = Double(time), seconds > 0 else { return "DNF" }
            return TimeUtil.lapTimeFormat(seconds: time)
        }
    }
}
