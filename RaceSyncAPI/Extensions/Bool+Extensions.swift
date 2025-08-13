//
//  Bool+Extensions.swift
//  RaceSyncAPI
//
//  Created by Ignacio Romero Zurbuchen on 2025-08-12.
//  Copyright © 2025 MultiGP Inc. All rights reserved.
//

import Foundation

public extension Bool {

    var intValue: Int { self ? 1 : 0 }

    var stringValue : String { self ? "true" : "false" }

    var localizedString : String { self ? "Yes" : "No" }
}
