//
//  MapError.swift
//  RaceSyncAPI
//
//  Created by Ignacio Romero Zurbuchen on 2026-02-17.
//  Copyright © 2026 MultiGP Inc. All rights reserved.
//

import Foundation

enum MapError: LocalizedError {
    case apiKeyMissing

    var errorDescription: String? {
        switch self {
        case .apiKeyMissing:
            return "API key missing from credentials.plist"
        }
    }
}
