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
/// 1. Do not recommend a slot when the user cannot join another round, has no selected frequencies,
///    or has already reached the race's ZippyQ depth.
/// 2. Consider queued rounds and prospective empty cycles that the API can create on demand,
///    excluding rounds that already contain the current user.
/// 3. Treat each ordered round/heat pair as one queue position. Exclude candidates that do not
///    leave the configured number of queue positions between the candidate and any of the user's
///    existing past, live, or queued assignments.
/// 4. Always choose the earliest remaining round that has an available slot on a selected frequency.
/// 5. Within that round, prefer the user's most recently assigned frequency from past, live, or
///    queued rounds when it is selected and available. This minimizes VTX channel changes.
/// 6. Otherwise, prefer the selected and available frequency flown most often in current and past rounds.
/// 7. Resolve remaining ties by the race's frequency slot order.
///
/// Selection order is intentionally not tracked or considered.
final class ZippyqSmartJoiner: ZippyqSmartJoinable {

    func recommendation(for input: ZippyqSmartJoinInput) -> ZippyqSmartJoinRecommendation? {
        guard input.canJoinAnotherRound, !input.selectedFrequencies.isEmpty else { return nil }

        let queuedRoundCount = input.queuedRounds.filter(\.containsCurrentUser).count
        guard input.maximumQueueDepth <= 0 || Int32(queuedRoundCount) < input.maximumQueueDepth else { return nil }

        let eligibleRounds = input.queuedRounds
            .filter {
                !$0.containsCurrentUser && satisfiesRestRequirement($0, input: input)
            }
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

    func satisfiesRestRequirement(_ round: ZippyqSmartJoinRound,
                                  input: ZippyqSmartJoinInput) -> Bool {
        guard input.requiredRestRounds > 0 else { return true }

        let candidate = ZippyqSmartJoinRoundPosition(cycle: round.cycle, heat: round.heat)
        guard let candidateIndex = input.roundSequence.firstIndex(of: candidate) else { return false }

        return input.currentUserRounds.allSatisfy { userRound in
            guard let userIndex = input.roundSequence.firstIndex(of: userRound) else { return false }
            return abs(candidateIndex - userIndex) > Int(input.requiredRestRounds)
        }
    }

    func selectSlot(from slots: [ZippyqSmartJoinSlot], input: ZippyqSmartJoinInput) -> Selection {
        if let recentFrequency = input.mostRecentlyAssignedFrequency,
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
