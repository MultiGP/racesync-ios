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
        self.statsLabel = ZippyqPilotStatsViewModel(
            stats: currentUserStats,
            maximumPackCount: maximumPackCount,
            detailLevel: .currentUserDetailed,
            isUpNext: isCurrentUserUpNext
        ).label
        self.isJoinEnabled = isJoinEnabled
    }
}
