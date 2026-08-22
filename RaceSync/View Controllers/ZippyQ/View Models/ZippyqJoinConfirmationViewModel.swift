//
//  ZippyqJoinConfirmationViewModel.swift
//  RaceSync
//
//  Created by Ignacio Romero on 2026-08-21.
//  Copyright © 2026 MultiGP Inc. All rights reserved.
//

import UIKit
import RaceSyncAPI

class ZippyqJoinConfirmationViewModel {

    let title: String
    let message: String

    init(recommendation: ZippyqSmartJoinRecommendation,
         channel: String,
         previousFrequency: String?,
         projectedStartTime: Date?) {
        let heat = recommendation.heat > 1 ? ", Heat \(recommendation.heat)" : ""
        title = "Joined Round \(recommendation.cycle)\(heat)!"
        message = Self.makeMessage(
            cycle: recommendation.cycle,
            heat: heat,
            channel: channel,
            frequency: recommendation.frequency,
            previousFrequency: previousFrequency,
            projectedStartTime: projectedStartTime
        )
    }

    fileprivate static func makeMessage(cycle: Int32,
                            heat: String,
                            channel: String,
                            frequency: String,
                            previousFrequency: String?,
                            projectedStartTime: Date?) -> String {

        let channelDescription = "\(channel) (\(frequency))"
        var message: String
        if let previousFrequency {
            message = previousFrequency == frequency
                ? "Your channel is \(channelDescription). No channel changes."
                : "Your new channel will be \(channelDescription)."
        } else {
            message = "Your channel is \(channelDescription)."
        }
        guard let projectedStartTime else { return message }

        let time = DateUtil.displayTimeFormatter2.string(from: projectedStartTime)
        let relativeFormatter = RelativeDateTimeFormatter()
        relativeFormatter.unitsStyle = .full
        let relativeTime = relativeFormatter.localizedString(for: projectedStartTime, relativeTo: Date())
        message += "\nRound \(cycle)\(heat) is predicted to start at \(time) (\(relativeTime))."
        return message
    }
}
