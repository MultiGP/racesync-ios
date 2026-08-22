//
//  ZippyqPilotStatsViewModel.swift
//  RaceSync
//
//  Created by Ignacio Romero on 2026-08-22.
//  Copyright © 2026 MultiGP Inc. All rights reserved.
//

import UIKit
import RaceSyncAPI

class ZippyqPilotStatsViewModel {

    enum ZippyqPilotStatsDetailLevel {
        case packUsage
        case currentUserCompact
        case currentUserDetailed
    }

    let label: String

    init(stats: ZippyqPilotStats?,
         maximumPackCount: Int32,
         detailLevel: ZippyqPilotStatsDetailLevel,
         isUpNext: Bool = false) {
        let usedCount = stats?.usedCount ?? 0
        let queuedCount = max((stats?.queuedCount ?? 0) - usedCount, 0)
        let packUsage = Self.packUsageLabel(
            usedCount: usedCount,
            maximumPackCount: maximumPackCount
        )

        switch detailLevel {
        case .packUsage:
            label = packUsage

        case .currentUserCompact:
            label = "\(packUsage) • \(queuedCount) queued"

        case .currentUserDetailed:
            let queueLabel: String
            if queuedCount > 0 {
                queueLabel = "\(queuedCount) queued"
            } else if maximumPackCount > 0, usedCount >= maximumPackCount {
                queueLabel = "No more queues"
            } else {
                queueLabel = "Not queued"
            }

            var components = [packUsage, queueLabel]
            if queuedCount > 0 {
                if isUpNext {
                    components.append("Up next")
                } else if let nextRoundsLabel = Self.nextRoundsLabel(for: stats?.nextRounds) {
                    components.append(nextRoundsLabel)
                }
            }
            label = components.joined(separator: " • ")
        }
    }
}

private extension ZippyqPilotStatsViewModel {

    static let maximumDisplayedRoundCount = 5

    static func packUsageLabel(usedCount: Int32, maximumPackCount: Int32) -> String {
        guard usedCount > 0 else { return "No used packs" }

        if maximumPackCount > 0 {
            return "\(usedCount) of \(maximumPackCount) packs used"
        }

        return "\(usedCount) pack\(usedCount == 1 ? "" : "s") used"
    }

    static func nextRoundsLabel(for nextRounds: [String]?) -> String? {
        let rounds = nextRounds?
            .compactMap { $0.components(separatedBy: ":").first }
            .reduce(into: [String]()) { rounds, round in
                if !rounds.contains(round) { rounds.append(round) }
            }
            .prefix(maximumDisplayedRoundCount) ?? []

        guard !rounds.isEmpty else { return nil }

        let roundLabel = rounds.count == 1 ? "Round" : "Rounds"
        return "My Next \(roundLabel): \(formattedList(Array(rounds)))"
    }

    static func formattedList(_ values: [String]) -> String {
        guard values.count > 1, let lastValue = values.last else { return values.first ?? "" }
        return "\(values.dropLast().joined(separator: ", ")) & \(lastValue)"
    }
}
