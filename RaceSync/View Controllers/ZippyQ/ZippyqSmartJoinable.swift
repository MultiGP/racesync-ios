//
//  ZippyqSmartJoinable.swift
//  RaceSync
//
//  Created by Ignacio Romero on 2026-08-15.
//  Copyright © 2026 MultiGP Inc. All rights reserved.
//

import Foundation

protocol ZippyqSmartJoinable {
    func recommendation(for input: ZippyqSmartJoinInput) -> ZippyqSmartJoinRecommendation?
}

struct ZippyqSmartJoinInput {
    let queuedRounds: [ZippyqSmartJoinRound]
    let roundSequence: [ZippyqSmartJoinRoundPosition]
    let currentUserRounds: [ZippyqSmartJoinRoundPosition]
    let selectedFrequencies: Set<String>
    let mostRecentlyAssignedFrequency: String?
    let flownFrequencyCounts: [String: Int]
    let canJoinAnotherRound: Bool
    let maximumQueueDepth: Int32
    let requiredRestRounds: Int32
}

struct ZippyqSmartJoinRoundPosition: Equatable {
    let cycle: Int32
    let heat: Int32
}

struct ZippyqSmartJoinRound {
    let cycle: Int32
    let heat: Int32
    let containsCurrentUser: Bool
    let slots: [ZippyqSmartJoinSlot]
}

struct ZippyqSmartJoinSlot {
    let frequency: String
    let slot: Int32
    let isAvailable: Bool
}

struct ZippyqSmartJoinRecommendation: Equatable {
    let cycle: Int32
    let heat: Int32
    let frequency: String
    let slot: Int32
    let reason: ZippyqSmartJoinReason
}

enum ZippyqSmartJoinReason: Equatable {
    case mostRecently
    case mostFrequently
    case firstAvailable
}
