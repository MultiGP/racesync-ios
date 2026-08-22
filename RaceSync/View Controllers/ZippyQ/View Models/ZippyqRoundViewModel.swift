//
//  ZippyqRoundViewModel.swift
//  RaceSync
//
//  Created by Ignacio Romero on 2026-08-21.
//  Copyright © 2026 MultiGP Inc. All rights reserved.
//

import UIKit
import RaceSyncAPI

class ZippyqRoundViewModel: Descriptable {

    let id: String
    let titleLabel: String
    let heatLabel: String?
    let scoringFormatLabel: String?
    let contextualLabel: String
    let badge: ZippyqRoundBadge
    let isExpandable: Bool
    let frequencyViewModels: [ZippyqFrequencyViewModel]
    let avatarImageUrls: [String?]
    
    static let showsSpotsLeft: Bool = false
    static let showsSpotsFull: Bool = false
    static let showsScoringFormatLabel: Bool = false

    init(with queue: ZippyQueue,
         frequencies: [Frequency],
         pilotStats: ZippyqPilotCollection,
         maximumPackCount: Int32,
         scoringFormat: ScoringFormat,
         isUpNext: Bool) {

        id = "\(queue.cycle):\(queue.heat)"
        titleLabel = "Round \(queue.cycle)"
        heatLabel = queue.heat > 1 ? "Heat \(queue.heat)" : nil

        let hasResults = queue.entries.contains { $0.hasResults }
        scoringFormatLabel = Self.showsScoringFormatLabel && hasResults ? "Results" : nil // Just a legend

        let viewModels = frequencies.map {
            ZippyqFrequencyViewModel(
                with: $0,
                queue: queue,
                pilotStats: pilotStats,
                maximumPackCount: maximumPackCount,
                scoringFormat: scoringFormat
            )
        }
        let assignedViewModels = viewModels.filter { $0.isAssigned }
        frequencyViewModels = queue.status == .queued ? viewModels : assignedViewModels
        isExpandable = queue.status == .queued || !assignedViewModels.isEmpty
        avatarImageUrls = assignedViewModels.map { $0.imageUrl }

        let pilotCount = assignedViewModels.count
        let availableSpotCount = frequencies.count - pilotCount
        let availabilityBadge: ZippyqRoundBadge

        if Self.showsSpotsFull, !frequencies.isEmpty, availableSpotCount == 0 {
            availabilityBadge = .full
        } else if Self.showsSpotsLeft, availableSpotCount > 0 {
            availabilityBadge = .spotsLeft(availableSpotCount)
        } else {
            availabilityBadge = .none
        }

        switch queue.status {
        case .running:
            badge = .running
            contextualLabel = "\(pilotCount) Racing"
        case .queued:
            badge = isUpNext ? .upNext : availabilityBadge
            contextualLabel = "\(pilotCount) Waiting"
        case .previous:
            badge = .past
            contextualLabel = "\(pilotCount) Raced"
        }
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
