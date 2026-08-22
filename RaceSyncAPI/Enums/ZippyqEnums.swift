//
//  ZippyqEnums.swift
//  RaceSyncAPI
//
//  Created by Ignacio Romero on 2026-07-28.
//  Copyright © 2026 MultiGP Inc. All rights reserved.
//

import Foundation

public enum ZippyqStatus: String, EnumTitle {
    case running = "running"
    case queued = "queued"
    case previous = "previous"

    public var title: String {
        switch self {
        case .running:      return "Running"
        case .queued:       return "Queued"
        case .previous:     return "Previous"
        }
    }
}
