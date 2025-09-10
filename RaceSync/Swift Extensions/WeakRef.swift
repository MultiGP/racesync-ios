//
//  WeakRef.swift
//  RaceSync
//
//  Created by Ignacio Romero Zurbuchen on 2025-09-09.
//  Copyright © 2025 MultiGP Inc. All rights reserved.
//

import Foundation

final class WeakRef<T: AnyObject> {
    weak var value: T?
    init(_ value: T) {
        self.value = value
    }
}
