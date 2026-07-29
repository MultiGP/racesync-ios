//
//  StandingEnum.swift
//  RaceSyncAPI
//
//  Created by Ignacio Romero Zurbuchen on 2026-04-01.
//  Copyright © 2026 MultiGP Inc. All rights reserved.
//

import Foundation

public enum StandingSeason: String, CaseIterable {
    case y2026 = "2026"
    case y2025 = "2025"
    case y2024 = "2024"
    case y2023 = "2023"
    case y2022 = "2022"
    case y2021 = "2021"
    case y2020 = "2020"
    case y2019 = "2019"
}

public extension StandingSeason {

    var title: String {
        return "\(year) MultiGP Global Qualifier"
    }

    var shortTitle: String {
        return "MultiGP GQ \(year)"
    }

    var year: String {
        self.rawValue
    }

    var pilotCount: String {
        switch self {
        case .y2026:    return ""
        case .y2025:    return "1113"
        case .y2024:    return "932"
        case .y2023:    return "824"
        case .y2022:    return "712"
        case .y2021:    return "685"
        case .y2020:    return "604"
        case .y2019:    return "1011"
        }
    }
}
