//
//  PushMessage.swift
//  RaceSync
//
//  Created by Ignacio Romero Zurbuchen on 2025-05-20.
//  Copyright © 2025 MultiGP Inc. All rights reserved.
//

import Foundation
import RaceSyncAPI

struct PushMessage: Codable, Descriptable {

    let title: String
    let detail: String
    let timestamp: TimeInterval

    let raceId: String?
    let type: String?
}
