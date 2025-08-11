//
//  Collection+Extensions.swift
//  RaceSync
//
//  Created by Ignacio Romero Zurbuchen on 2025-08-10.
//  Copyright © 2025 MultiGP Inc. All rights reserved.
//

import Foundation

extension Collection {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
