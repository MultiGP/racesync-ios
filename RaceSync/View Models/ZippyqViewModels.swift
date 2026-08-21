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
        self.statsLabel = Self.statsLabel(
            for: currentUserStats,
            maximumPackCount: maximumPackCount,
            isUpNext: isCurrentUserUpNext
        )
        self.isJoinEnabled = isJoinEnabled
    }
}

private extension ZippyqHeaderViewModel {

    static func statsLabel(for stats: ZippyqPilotStats?,
                           maximumPackCount: Int32,
                           isUpNext: Bool) -> String {
        let usedCount = stats?.usedCount ?? 0
        let queuedCount = stats?.queuedCount ?? 0

        let packText: String
        if maximumPackCount > 0 {
            packText = usedCount == 0 ? "No packs flown" : "\(usedCount)/\(maximumPackCount) packs used"
        } else {
            packText = usedCount == 0
                ? "No packs flown"
                : "\(usedCount) pack\(usedCount == 1 ? "" : "s") flown"
        }

        guard queuedCount > 0 else {
            let queueText = maximumPackCount > 0 && usedCount >= maximumPackCount
                ? "No more queues"
                : "Not queued"
            return "\(packText) • \(queueText)"
        }

        let queueText = "\(queuedCount) queued"
        guard !isUpNext else { return "\(packText) • \(queueText) • Up next" }

        let rounds = stats?.nextRounds
            .compactMap { $0.components(separatedBy: ":").first }
            .reduce(into: [String]()) { values, round in
                if !values.contains(round) { values.append(round) }
            } ?? []
        guard !rounds.isEmpty else { return "\(packText) • \(queueText)" }

        let roundLabel = rounds.count == 1 ? "Round" : "Rounds"
        return "\(packText) • \(queueText) • My Next \(roundLabel): \(formattedList(rounds))"
    }

    static func formattedList(_ values: [String]) -> String {
        guard values.count > 1, let lastValue = values.last else { return values.first ?? "" }
        return "\(values.dropLast().joined(separator: ", ")) & \(lastValue)"
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

class ZippyqFrequencyViewModel: Descriptable {

    let user: User?

    let frequency: Frequency
    let slot: Int
    let cycle: Int
    let heat: Int
    let channelLabel: String
    let frequencyColor: UIColor
    let titleLabel: String?
    let isAssigned: Bool
    let isCurrentUser: Bool
    let subtitleLabel: String?
    let imageUrl: String?
    let resultLabel: String?
    let action: ZippyqFrequencyAction?
    let isActionEnabled: Bool

    init(with frequency: Frequency,
         queue: ZippyQueue,
         pilotStats: ZippyqPilotCollection,
         maximumPackCount: Int32,
         scoringFormat: ScoringFormat) {

        let entry = queue.entries.first { $0.frequency?.frequency == frequency.frequency }
        user = entry?.user
        isCurrentUser = APIServices.shared.isCurrentUser(entry?.user)

        self.frequency = frequency
        slot = Int(frequency.slot)
        cycle = Int(queue.cycle)
        heat = Int(queue.heat)
        channelLabel = frequency.channelLabel
        frequencyColor = FrequencyColor.color(for: frequency.frequency)

        if queue.status == .running, entry?.hasResults != true {
            resultLabel = nil
        } else if queue.status != .queued {
            resultLabel = ResultEntryViewModel.formattedResult(
                for: scoringFormat,
                totalLaps: entry?.totalLaps,
                fastestLap: entry?.fastestLap,
                fastest2Laps: entry?.fastest2Laps,
                fastest3Laps: entry?.fastest3Laps
            )
        } else {
            resultLabel = nil
        }

        if let user = entry?.user, let stats = pilotStats[user.id] {
            let userViewModel = UserViewModel(with: user)
            titleLabel = userViewModel.username
            isAssigned = true
            subtitleLabel = maximumPackCount > 0 ? "Pack \(stats.queuedCount) of \(maximumPackCount)" : "Pack \(stats.queuedCount)"
            imageUrl = userViewModel.pictureUrl
        } else {
            titleLabel = "[Empty]"
            isAssigned = false
            subtitleLabel = nil
            imageUrl = nil
        }

        guard queue.status == .queued, let myUserId = APIServices.shared.myUser?.id else {
            action = nil
            isActionEnabled = false
            return
        }

        let myEntry = queue.entries.first { $0.user?.id == myUserId }
        let isMyFrequency = entry?.user?.id == myUserId
        let isEmpty = entry == nil

        if isMyFrequency {
            action = .remove
            isActionEnabled = true
        } else if myEntry != nil, isEmpty {
            action = .switch
            isActionEnabled = true
        } else if myEntry == nil, isEmpty {
            action = .addMe
            isActionEnabled = true
        } else {
            action = nil
            isActionEnabled = false
        }
    }
}

class ZippyqRoundViewModel: Descriptable {

    let id: String
    let titleLabel: String
    let heatLabel: String?
    let scoringFormatLabel: String?
    let contextualLabel: String
    let badge: ZippyqRoundBadge
    let frequencyViewModels: [ZippyqFrequencyViewModel]
    let avatarImageUrls: [String?]
    
    static let showsSpotsLeft: Bool = false
    static let showsSpotsFull: Bool = false

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
        let assignedViewModels = viewModels.filter { $0.isAssigned }
        frequencyViewModels = queue.status == .queued ? viewModels : assignedViewModels
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
