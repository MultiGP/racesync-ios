//
//  PushMessage.swift
//  RaceSync
//
//  Created by Ignacio Romero Zurbuchen on 2025-05-20.
//  Copyright © 2025 MultiGP Inc. All rights reserved.
//

import Foundation

struct PushMessage: Codable {

    let apnsId: String?
    let title: String
    let detail: String
    let timestamp: TimeInterval
}
