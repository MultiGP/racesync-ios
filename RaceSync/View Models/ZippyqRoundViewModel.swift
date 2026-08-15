//
//  ZippyqRoundViewModel.swift
//  RaceSync
//
//  Created by Ignacio Romero on 2026-07-29.
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
    let frequencyViewModels: [ZippyqFrequencyViewModel]
    let avatarImageUrls: [String?]

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
        scoringFormatLabel = queue.status != .queued && hasResults ? scoringFormat.title : nil
        
        let viewModels = frequencies.map {
            ZippyqFrequencyViewModel(
                with: $0,
                queue: queue,
                pilotStats: pilotStats,
                maximumPackCount: maximumPackCount,
                scoringFormat: scoringFormat
            )
        }
        frequencyViewModels = queue.status == .queued ? viewModels : viewModels.filter { $0.isAssigned }
        avatarImageUrls = viewModels.filter { $0.isAssigned }.map { $0.imageUrl }

        let pilotCount = queue.entries.count
        let availableSpotCount = frequencies.count - pilotCount
        let availabilityBadge: ZippyqRoundBadge
        
        if !frequencies.isEmpty, availableSpotCount == 0 {
            availabilityBadge = .full
        } else if availableSpotCount > 0 {
            availabilityBadge = .spotsLeft(availableSpotCount)
        } else {
            availabilityBadge = .none
        }

        switch queue.status {
        case .running:
            badge = .live
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

enum ZippyqRoundBadge: Equatable {
    case none
    case live
    case upNext
    case past
    case full
    case spotsLeft(Int)

    var title: String? {
        switch self {
        case .none:                return nil
        case .live:                return "Live".uppercased()
        case .upNext:              return "Up Next".uppercased()
        case .past:                return "Past".uppercased()
        case .full:                return "Full".uppercased()
        case .spotsLeft(let count):
            return "\(count) Spot\(count == 1 ? "" : "s")".uppercased()
        }
    }

    var backgroundColor: UIColor {
        switch self {
        case .none:                 return Color.clear
        case .live:                 return Color.green
        case .upNext:               return Color.yellow
        case .past:                 return Color.gray50
        case .full:                 return Color.orange.withAlphaComponent(0.8)
        case .spotsLeft:            return Color.gray50
        }
    }

    var titleColor: UIColor {
        switch self {
        case .none:                 return Color.clear
        case .live:                 return Color.light
        case .upNext:               return Color.blue
        case .past:                 return Color.dynamic(light: Color.black, dark: Color.gray400)
        case .full:                 return Color.blue
        case .spotsLeft:            return Color.gray300
        }
    }
}
