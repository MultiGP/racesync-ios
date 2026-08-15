//
//  ZippyqSmartJoiner.swift
//  RaceSync
//
//  Created by Ignacio Romero on 2026-08-15.
//  Copyright © 2026 MultiGP Inc. All rights reserved.
//

/// Recommends one available frequency in the next eligible ZippyQ round.
///
/// Rules, in priority order:
/// 1. Do not recommend a slot when the user cannot join another round or has no selected frequencies.
/// 2. Consider queued rounds only, excluding rounds that already contain the current user.
/// 3. Always choose the earliest round that has an available slot on a selected frequency.
/// 4. Within that round, prefer the most recently flown frequency when it is selected and available.
/// 5. Otherwise, prefer the selected and available frequency flown most often in current and past rounds.
/// 6. Resolve remaining ties by the race's frequency slot order.
///
/// Selection order is intentionally not tracked or considered.
final class ZippyqSmartJoiner: ZippyqSmartJoinable {

    func recommendation(for input: ZippyqSmartJoinInput) -> ZippyqSmartJoinRecommendation? {
        guard input.canJoinAnotherRound, !input.selectedFrequencies.isEmpty else { return nil }

        let eligibleRounds = input.queuedRounds
            .filter { !$0.containsCurrentUser }
            .sorted {
                if $0.cycle == $1.cycle { return $0.heat < $1.heat }
                return $0.cycle < $1.cycle
            }

        for round in eligibleRounds {
            let slots = round.slots
                .filter { $0.isAvailable && input.selectedFrequencies.contains($0.frequency) }
                .sorted { $0.slot < $1.slot }

            guard !slots.isEmpty else { continue }

            let selection = selectSlot(from: slots, input: input)
            return ZippyqSmartJoinRecommendation(
                cycle: round.cycle,
                heat: round.heat,
                frequency: selection.slot.frequency,
                slot: selection.slot.slot,
                reason: selection.reason
            )
        }

        return nil
    }
}

private extension ZippyqSmartJoiner {

    typealias Selection = (slot: ZippyqSmartJoinSlot, reason: ZippyqSmartJoinReason)

    func selectSlot(from slots: [ZippyqSmartJoinSlot], input: ZippyqSmartJoinInput) -> Selection {
        if let recentFrequency = input.mostRecentlyFlownFrequency,
           let slot = slots.first(where: { $0.frequency == recentFrequency }) {
            return (slot, .mostRecently)
        }

        let highestUsageCount = slots
            .map { input.flownFrequencyCounts[$0.frequency, default: 0] }
            .max() ?? 0

        if highestUsageCount > 0,
           let slot = slots.first(where: {
               input.flownFrequencyCounts[$0.frequency, default: 0] == highestUsageCount
           }) {
            return (slot, .mostFrequently)
        }

        return (slots[0], .firstAvailable)
    }
}
