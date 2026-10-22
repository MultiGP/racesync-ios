//
//  ZippyqResultsCalculator.swift
//  RaceSync
//
//  Created by Ignacio Romero on 2026-10-16.
//  Copyright © 2026 MultiGP Inc. All rights reserved.
//

import Foundation
import RaceSyncAPI

enum ZippyqLeaderboardMovement {
    case up
    case down
}

struct ZippyqResultChange {
    let hasImproved: Bool
    let leaderboardMovement: ZippyqLeaderboardMovement?
}

final class ZippyqResultsCalculator {

    func changes(in queues: [ZippyQueue],
                 scoringFormat: ScoringFormat) -> [ObjectId: ZippyqResultChange] {
        let orderedQueues = queues.sorted {
            if $0.cycle == $1.cycle { return $0.heat < $1.heat }
            return $0.cycle < $1.cycle
        }
        var bestResultByPilot = [ObjectId: Double]()
        var changes = [ObjectId: ZippyqResultChange]()

        for queue in orderedQueues where queue.status != .queued {
            let previousRanks = leaderboardRanks(
                from: bestResultByPilot,
                scoringFormat: scoringFormat
            )

            for entry in queue.entries {
                guard let pilotId = entry.user?.id,
                      let result = resultValue(for: entry, scoringFormat: scoringFormat) else {
                    continue
                }

                if let bestResult = bestResultByPilot[pilotId] {
                    let improved = scoringFormat == .aggregateLap
                        ? result > bestResult
                        : result < bestResult
                    guard improved else { continue }
                    changes[entry.id] = ZippyqResultChange(
                        hasImproved: true,
                        leaderboardMovement: nil
                    )
                }
                bestResultByPilot[pilotId] = bestResultByPilot[pilotId].map {
                    scoringFormat == .aggregateLap ? max($0, result) : min($0, result)
                } ?? result
            }

            let currentRanks = leaderboardRanks(
                from: bestResultByPilot,
                scoringFormat: scoringFormat
            )
            for entry in queue.entries {
                guard let pilotId = entry.user?.id,
                      let previousRank = previousRanks[pilotId],
                      let currentRank = currentRanks[pilotId],
                      previousRank != currentRank else { continue }
                changes[entry.id] = ZippyqResultChange(
                    hasImproved: changes[entry.id]?.hasImproved ?? false,
                    leaderboardMovement: currentRank < previousRank ? .up : .down
                )
            }
        }

        return changes
    }

    private func leaderboardRanks(from results: [ObjectId: Double],
                                  scoringFormat: ScoringFormat) -> [ObjectId: Int] {
        let orderedResults = results.sorted {
            scoringFormat == .aggregateLap ? $0.value > $1.value : $0.value < $1.value
        }
        var ranks = [ObjectId: Int]()
        var previousResult: Double?
        var previousRank = 0

        for (index, result) in orderedResults.enumerated() {
            let rank = result.value == previousResult ? previousRank : index + 1
            ranks[result.key] = rank
            previousResult = result.value
            previousRank = rank
        }
        return ranks
    }

    private func resultValue(for entry: ZippyqEntry,
                             scoringFormat: ScoringFormat) -> Double? {
        let value: String?
        switch scoringFormat {
        case .aggregateLap:
            value = entry.totalLaps
        case .fastestLap:
            value = entry.fastestLap
        case .fastest2Laps:
            value = entry.fastest2Laps
        case .fastest3Laps:
            value = entry.fastest3Laps
        }

        guard let value,
              let result = Double(value),
              result > 0,
              result < MaximumValidRaceResultTime else {
            return nil
        }
        return result
    }
}
