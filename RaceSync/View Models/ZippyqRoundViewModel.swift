//
//  ZippyqRoundViewModel.swift
//  RaceSync
//
//  Created by Ignacio Romero on 2026-07-29.
//  Copyright © 2026 MultiGP Inc. All rights reserved.
//

import RaceSyncAPI

class ZippyqRoundViewModel {

    let id: String
    let titleLabel: String
    let contextualLabel: String
    let badge: ZippyqRoundBadge
    let frequencyViewModels: [ZippyqFrequencyViewModel]
    let avatarImageUrls: [String?]

    init(with queue: ZippyQueue,
         frequencies: [Frequency],
         pilotStats: ZippyqPilotCollection,
         maximumPackCount: Int32,
         isUpNext: Bool) {
        
        id = "\(queue.cycle):\(queue.heat)"
        titleLabel = "Round \(queue.cycle)"
        
        let viewModels = frequencies.map {
            ZippyqFrequencyViewModel(
                with: $0,
                queue: queue,
                pilotStats: pilotStats,
                maximumPackCount: maximumPackCount
            )
        }
        frequencyViewModels = queue.status == .queued ? viewModels : viewModels.filter { $0.isAssigned }
        avatarImageUrls = viewModels.filter { $0.isAssigned }.map { $0.imageUrl }

        let pilotCount = queue.entries.count
        switch queue.status {
        case .running:
            badge = .live
            contextualLabel = "\(pilotCount) Racing"
        case .queued:
            badge = isUpNext ? .upNext : .none
            contextualLabel = "\(pilotCount) Waiting"
        case .previous:
            badge = .none
            contextualLabel = "\(pilotCount) Raced"
        }
    }
}

enum ZippyqRoundBadge: Equatable {
    case none
    case live
    case upNext

    var title: String? {
        switch self {
        case .none: return nil
        case .live: return "Live".uppercased()
        case .upNext: return "Up Next".uppercased()
        }
    }
}
