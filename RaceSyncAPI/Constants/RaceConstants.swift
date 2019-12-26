//
//  RaceConstants.swift
//  RaceSyncAPI
//
//  Created by Ignacio Romero Zurbuchen on 2019-12-22.
//  Copyright © 2019 MultiGP Inc. All rights reserved.
//

import Foundation

public enum RaceType: Int, enumTitle {
    case normal = 1
    case qualifier = 2
    case final = 3

    public var title: String {
        switch self {
        case .qualifier:    return "Regional Qualifier"
        case .final:        return "Regional Final"
        default:            return "Normal"
        }
    }
}

public enum RaceStatus: String {
    case open = "Open"
    case closed = "Closed"
}