//
//  ZippyqHeaderViewModel.swift
//  RaceSync
//
//  Created by Ignacio Romero on 2026-08-15.
//  Copyright © 2026 MultiGP Inc. All rights reserved.
//

import UIKit

class ZippyqHeaderViewModel {

    let frequencyViewModels: [ZippyqHeaderFrequencyViewModel]
    let preferenceLabel: String
    let statsLabel: String
    let isJoinEnabled: Bool

    init(frequencyViewModels: [ZippyqHeaderFrequencyViewModel],
         preferenceLabel: String,
         statsLabel: String,
         isJoinEnabled: Bool) {
        self.frequencyViewModels = frequencyViewModels
        self.preferenceLabel = preferenceLabel
        self.statsLabel = statsLabel
        self.isJoinEnabled = isJoinEnabled
    }
}

class ZippyqHeaderFrequencyViewModel {

    let frequency: String?
    let channelLabel: String?
    let queuedPilotCount: Int?
    let color: UIColor?
    let isSelected: Bool
    let isEnabled: Bool

    init(frequency: String? = nil,
         channelLabel: String? = nil,
         queuedPilotCount: Int? = nil,
         color: UIColor? = nil,
         isSelected: Bool = false,
         isEnabled: Bool = false) {
        self.frequency = frequency
        self.channelLabel = channelLabel
        self.queuedPilotCount = queuedPilotCount
        self.color = color
        self.isSelected = isSelected
        self.isEnabled = isEnabled
    }
}
