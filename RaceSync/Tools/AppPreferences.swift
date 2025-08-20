//
//  AppPreferences.swift
//  RaceSync
//
//  Created by Ignacio Romero Zurbuchen on 2025-08-12.
//  Copyright © 2025 MultiGP Inc. All rights reserved.
//

import Foundation

class AppPreferences {

    private enum Key {
        static let lastSelectedTab = "com.multigp.RaceSync.preferences.last_selected_tab"
    }

    static var lastSelectedTab: Int {
        get {
            if let value = UserDefaults.standard.string(forKey: Key.lastSelectedTab) {
                return Int(value) ?? HomeTabs.default.rawValue
            } else {
                return HomeTabs.default.rawValue
            }
        }
        set { UserDefaults.standard.set("\(newValue)", forKey: Key.lastSelectedTab) }
    }
}
