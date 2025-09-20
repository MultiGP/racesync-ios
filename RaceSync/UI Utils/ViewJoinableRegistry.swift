//
//  ViewJoinableRegistry.swift
//  RaceSync
//
//  Created by Ignacio Romero Zurbuchen on 2025-09-09.
//  Copyright © 2025 MultiGP Inc. All rights reserved.
//

import Foundation
import UIKit
import RaceSyncAPI

final class ViewJoinableRegistry {
    static let shared = ViewJoinableRegistry()
    private init() {}

    private var items: [WeakRef<UIViewController>] = []

    func register(_ joinable: ViewJoinable) {
        cleanup()
        items.append(WeakRef(joinable))

        Clog.log("Registering ViewJoinable : \(joinable.description)")
    }

    func unregister(_ joinable: ViewJoinable) {
        cleanup()
        items.removeAll { $0.value === joinable }

        Clog.log("Unregistering ViewJoinable : \(joinable.description)")
    }

    func all() -> [ViewJoinable] {
        cleanup()
        return items.compactMap { $0.value as? ViewJoinable }
    }

    func unregisterAll() {
        items.removeAll()
    }

    private func cleanup() {
        items.removeAll { $0.value == nil }
    }
}
