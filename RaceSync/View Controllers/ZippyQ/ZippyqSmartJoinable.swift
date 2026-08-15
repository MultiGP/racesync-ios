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
    let selectedFrequencies: Set<String>
    let mostRecentlyFlownFrequency: String?
    let flownFrequencyCounts: [String: Int]
    let canJoinAnotherRound: Bool
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
