//
//  ZippyqFrequencyViewModel.swift
//  RaceSync
//
//  Created by Ignacio Romero on 2026-08-21.
//  Copyright © 2026 MultiGP Inc. All rights reserved.
//

import UIKit
import RaceSyncAPI

class ZippyqFrequencyViewModel: Descriptable {

    let user: User?

    let frequency: Frequency
    let slot: Int
    let cycle: Int
    let heat: Int
    let channelLabel: String
    let frequencyColor: UIColor
    let titleLabel: String?
    let isAssigned: Bool
    let isCurrentUser: Bool
    let subtitleLabel: String?
    let imageUrl: String?
    let resultLabel: String?
    let action: ZippyqFrequencyAction?
    let isActionEnabled: Bool

    init(with frequency: Frequency,
         queue: ZippyQueue,
         pilotStats: ZippyqPilotCollection,
         maximumPackCount: Int32,
         scoringFormat: ScoringFormat) {

        let entry = queue.entries.first { $0.frequency?.frequency == frequency.frequency }
        user = entry?.user
        isCurrentUser = APIServices.shared.isCurrentUser(entry?.user)

        self.frequency = frequency
        slot = Int(frequency.slot)
        cycle = Int(queue.cycle)
        heat = Int(queue.heat)
        channelLabel = frequency.channelLabel
        frequencyColor = FrequencyColor.color(for: frequency.frequency)

        if queue.status == .running, entry?.hasResults != true {
            resultLabel = nil
        } else if queue.status != .queued {
            resultLabel = ResultEntryViewModel.formattedResult(
                for: scoringFormat,
                totalLaps: entry?.totalLaps,
                fastestLap: entry?.fastestLap,
                fastest2Laps: entry?.fastest2Laps,
                fastest3Laps: entry?.fastest3Laps
            )
        } else {
            resultLabel = nil
        }

        if let user = entry?.user, let stats = pilotStats[user.id] {
            let userViewModel = UserViewModel(with: user)
            let usedCount = stats.usedCount
            let packUnitText = "pack\(usedCount == 1 ? "" : "s")"
            let noPackText = "No packs used yet"
            var packText = ""

            if maximumPackCount > 0 {
                packText = usedCount == 0 ? noPackText : "\(usedCount)/\(maximumPackCount) \(packUnitText) used"
            } else {
                packText = usedCount == 0 ? noPackText : "\(usedCount) \(packUnitText) used"
            }
            if isCurrentUser {
                packText += " | \(stats.queuedCount - usedCount) queued"
            }

            titleLabel = userViewModel.username
            isAssigned = true
            subtitleLabel = packText
            imageUrl = userViewModel.pictureUrl
        } else {
            titleLabel = "[Empty]"
            isAssigned = false
            subtitleLabel = nil
            imageUrl = nil
        }

        guard queue.status == .queued, let myUserId = APIServices.shared.myUser?.id else {
            action = nil
            isActionEnabled = false
            return
        }

        let myEntry = queue.entries.first { $0.user?.id == myUserId }
        let isMyFrequency = entry?.user?.id == myUserId
        let isEmpty = entry == nil

        if isMyFrequency {
            action = .remove
            isActionEnabled = true
        } else if myEntry != nil, isEmpty {
            action = .switch
            isActionEnabled = true
        } else if myEntry == nil, isEmpty {
            action = .addMe
            isActionEnabled = true
        } else {
            action = nil
            isActionEnabled = false
        }
    }
}
