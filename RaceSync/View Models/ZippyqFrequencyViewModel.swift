//
//  ZippyqFrequencyViewModel.swift
//  RaceSync
//
//  Created by Ignacio Romero on 2026-07-29.
//  Copyright © 2026 MultiGP Inc. All rights reserved.
//

import UIKit
import RaceSyncAPI

class ZippyqFrequencyViewModel {

    let frequency: Frequency
    let channelLabel: String
    let frequencyColor: UIColor
    let titleLabel: String?
    let isAssigned: Bool
    let subtitleLabel: String?
    let imageUrl: String?
    let resultLabel: String?
    let action: ZippyqFrequencyAction?
    let isActionEnabled: Bool

    init(with frequency: Frequency,
         queue: ZippyQueue,
         pilotStats: ZippyqPilotCollection,
         maximumPackCount: Int32) {
        self.frequency = frequency
        channelLabel = frequency.channelLabel
        frequencyColor = FrequencyColor.color(for: frequency.frequency)

        let entry = queue.entries.first { $0.frequency?.frequency == frequency.frequency }
        resultLabel = queue.status == .running ? entry?.fastest3Laps : nil

        if let user = entry?.user, let stats = pilotStats[user.id] {
            let userViewModel = UserViewModel(with: user)
            titleLabel = userViewModel.username
            isAssigned = true
            subtitleLabel = "Pack \(stats.usedCount) of \(maximumPackCount)"
            imageUrl = userViewModel.pictureUrl
        } else {
            titleLabel = "Empty"
            isAssigned = false
            subtitleLabel = nil
            imageUrl = nil
        }

        guard queue.status != .running, let myUserId = APIServices.shared.myUser?.id else {
            action = nil
            isActionEnabled = false
            return
        }

        let myEntry = queue.entries.first { $0.user?.id == myUserId }
        let isMyFrequency = entry?.user?.id == myUserId
        let isEmpty = entry == nil
        let queuedCount = pilotStats[myUserId]?.queuedCount ?? 0
        let canQueueAnotherPack = queuedCount < maximumPackCount

        if isMyFrequency {
            action = .remove
            isActionEnabled = true
        } else if myEntry != nil, isEmpty {
            action = .switch
            isActionEnabled = true
        } else if myEntry == nil, isEmpty {
            action = .addMe
            isActionEnabled = canQueueAnotherPack
        } else {
            action = nil
            isActionEnabled = false
        }

    }

}

enum ZippyqFrequencyAction {
    case addMe
    case `switch`
    case remove
}
