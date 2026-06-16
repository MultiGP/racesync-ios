//
//  TimeInterval+Extensions.swift
//  RaceSync
//
//  Created by Ignacio Romero on 2026-06-15.
//  Copyright © 2026 MultiGP Inc. All rights reserved.
//

import Foundation

extension TimeInterval {
    
    var isMilliseconds: Bool {
        self > 10_000_000_000
    }
    
    var normalized: TimeInterval {
        return isMilliseconds ? self / 1000 : self
    }
}
