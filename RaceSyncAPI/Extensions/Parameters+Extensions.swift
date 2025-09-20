//
//  Params+Extensions.swift
//  RaceSyncAPI
//
//  Created by Ignacio Romero Zurbuchen on 2023-01-15.
//  Copyright © 2023 MultiGP Inc. All rights reserved.
//

import Foundation

public typealias Params = [String: AnyHashable]

public extension Params {

    func diff(with p2: Params) -> Params {
        return Params.diff(between: self, and: p2)
    }

    // Returns a new dict with only the difference between the new and the old dict,
    // giving priority to the newer one (p2)
    static func diff(between p1: Params, and p2: Params) -> Params {
        var result: Params = [:]

        for (key, value2) in p2 {
            if let value1 = p1[key] {
                if value1 != value2 {
                    // Different values → take p2’s version
                    result[key] = value2
                }
            } else {
                // New key in p2 → take it
                result[key] = value2
            }
        }

        return result
    }
}
