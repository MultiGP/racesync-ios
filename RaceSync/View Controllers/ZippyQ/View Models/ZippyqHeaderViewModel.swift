//
//  ZippyqHeaderViewModel.swift
//  RaceSync
//
//  Created by Ignacio Romero on 2026-08-21.
//  Copyright © 2026 MultiGP Inc. All rights reserved.
//

import UIKit
import RaceSyncAPI

class ZippyqHeaderViewModel {

    let frequencyViewModels: [ZippyqHeaderFrequencyViewModel]
    let preferenceLabel: String
    let statsLabel: String
    let isJoinEnabled: Bool

    init(frequencyViewModels: [ZippyqHeaderFrequencyViewModel],
         preferenceLabel: String,
         currentUserStats: ZippyqPilotStats?,
         maximumPackCount: Int32,
         isCurrentUserUpNext: Bool,
         isJoinEnabled: Bool) {
        self.frequencyViewModels = frequencyViewModels
        self.preferenceLabel = preferenceLabel
        self.statsLabel = Self.statsLabel(
            for: currentUserStats,
            maximumPackCount: maximumPackCount,
            isUpNext: isCurrentUserUpNext
        )
        self.isJoinEnabled = isJoinEnabled
    }
}

private extension ZippyqHeaderViewModel {

    static func statsLabel(for stats: ZippyqPilotStats?,
                           maximumPackCount: Int32,
                           isUpNext: Bool) -> String {
        let usedCount = stats?.usedCount ?? 0
        let queuedCount = max((stats?.queuedCount ?? 0) - usedCount, 0)

        let packText: String
        if maximumPackCount > 0 {
            packText = usedCount == 0 ? "No packs flown yet" : "\(usedCount)/\(maximumPackCount) packs used"
        } else {
            packText = usedCount == 0
                ? "No packs flown yet"
                : "\(usedCount) pack\(usedCount == 1 ? "" : "s") flown"
        }

        guard queuedCount > 0 else {
            let queueText = maximumPackCount > 0 && usedCount >= maximumPackCount
                ? "No more queues"
                : "Not queued"
            return "\(packText) • \(queueText)"
        }

        let queueText = "\(queuedCount) queued"
        guard !isUpNext else { return "\(packText) • \(queueText) • Up next" }

        let rounds = stats?.nextRounds
            .compactMap { $0.components(separatedBy: ":").first }
            .reduce(into: [String]()) { values, round in
                if !values.contains(round) { values.append(round) }
            } ?? []
        guard !rounds.isEmpty else { return "\(packText) • \(queueText)" }

        let roundLabel = rounds.count == 1 ? "Round" : "Rounds"
        return "\(packText) • \(queueText) • My Next \(roundLabel): \(formattedList(rounds))"
    }

    static func formattedList(_ values: [String]) -> String {
        guard values.count > 1, let lastValue = values.last else { return values.first ?? "" }
        return "\(values.dropLast().joined(separator: ", ")) & \(lastValue)"
    }
}
