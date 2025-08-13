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
        get { UserDefaults.standard.integer(forKey: Key.lastSelectedTab) }
        set { UserDefaults.standard.set(newValue, forKey: Key.lastSelectedTab) }
    }
}
