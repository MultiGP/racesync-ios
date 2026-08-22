//
//  ZippyqViewModels.swift
//  RaceSync
//
//  Created by Ignacio Romero on 2026-08-15.
//  Copyright © 2026 MultiGP Inc. All rights reserved.
//

import UIKit
import RaceSyncAPI

enum ZippyqFrequencyAction {
    case addMe
    case `switch`
    case remove
}

enum ZippyqRoundBadge: Equatable {
    case none
    case running
    case upNext
    case past
    case full
    case spotsLeft(Int)

    var title: String? {
        switch self {
        case .none:                return nil
        case .running:             return "Running".uppercased()
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
        case .running:              return Color.green
        case .upNext:               return Color.yellow
        case .past:                 return Color.gray50
        case .full:                 return Color.orange.withAlphaComponent(0.8)
        case .spotsLeft:            return Color.gray50
        }
    }

    var titleColor: UIColor {
        switch self {
        case .none:                 return Color.clear
        case .running:              return Color.light.withAlphaComponent(0.9)
        case .upNext:               return Color.blue.withAlphaComponent(0.8)
        case .past:                 return Color.blue.withAlphaComponent(0.8)
        case .full:                 return Color.blue.withAlphaComponent(0.8)
        case .spotsLeft:            return Color.gray300
        }
    }
}
