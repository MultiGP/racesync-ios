//
//  StandingViewModel.swift
//  RaceSync
//
//  Created by Ignacio Romero Zurbuchen on 2025-05-31.
//  Copyright © 2025 MultiGP Inc. All rights reserved.
//

import UIKit
import RaceSyncAPI
import CoreLocation

class StandingViewModel: Descriptable {

    let standing: Standing

    let titleLabel: String
    let subtitleLabel: String
    let rank: Int32

    // MARK: - Initialization

    init(with standing: Standing) {

        self.standing = standing

        let flag = FlagEmojiGenerator.flag(country: standing.country)
        self.titleLabel = "\(flag) \(standing.firstName) \'\(standing.userName)\' \(standing.lastName)"

        let spring = "Spring: \(Self.timeLabel(for: standing.season1Score))"
        let summer = "Summer: \(Self.timeLabel(for: standing.season2Score))"
        self.subtitleLabel = [spring, summer].joined(separator: "  |  ")

        self.rank = Int32(standing.position) ?? 0
    }

    static func viewModels(with objects:[Standing]) -> [StandingViewModel] {
        var viewModels = [StandingViewModel]()
        for object in objects {
            viewModels.append(StandingViewModel(with: object))
        }
        return viewModels
    }

    static func timeLabel(for value: Double) -> String {
        guard value > 0 && value < 2000000 else { return "N/A" }

        if value < 60 {
            return String(format: "%.3f", value)
        } else {
            let minutes = Int(value) / 60
            let seconds = value.truncatingRemainder(dividingBy: 60)
            return String(format: "%d:%06.3f", minutes, seconds)
        }
    }
}
