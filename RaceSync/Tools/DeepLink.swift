//
//  DeepLink.swift
//  RaceSync
//
//  Created by Ignacio Romero Zurbuchen on 2025-08-31.
//  Copyright © 2025 MultiGP Inc. All rights reserved.
//

import Foundation

struct DeepLink {
    let domain: Domain
    let action: Action
    let parameters: [String: String]

    enum Domain: String {
        case race
        case user // unsupported
        case chapter // unsupported
        case settings // unsupported
        case unknown
    }

    enum Action: String {
        case join
        case view // unsupported
        case unknown // unsupported
    }
}
