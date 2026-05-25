//
//  AppPreferences.swift
//  RaceSync
//
//  Created by Ignacio Romero Zurbuchen on 2025-08-12.
//  Copyright © 2025 MultiGP Inc. All rights reserved.
//

import RaceSyncAPI

typealias AppPrefs = AppplicationPreferences

class AppplicationPreferences {

    private enum LastSelected {
        static let homeTab = "com.multigp.RaceSync.preferences.last_selected.home_tab"
        static let raceFilter = "com.multigp.RaceSync.preferences.last_selected.races_filters"
        static let seriesFilter = "com.multigp.RaceSync.preferences.last_selected.series_filters"
    }
    
    private enum Prefs {
        static let schedulerAlerts = "com.multigp.RaceSync.preferences.hide_notification_scheduler_alerts"
    }
    
    static var lastSelectedHomeTab: HomeTabs {
        get {
            let string = UserDefaults.standard.string(forKey: LastSelected.homeTab)
            return string.flatMap { Int($0) }.flatMap { HomeTabs(rawValue: $0) } ?? HomeTabs.default
        }
        set {
            UserDefaults.standard.set("\(newValue.rawValue)", forKey: LastSelected.homeTab)
            UserDefaults.standard.synchronize()
        }
    }

    static var lastSelectedRaceFilter: RaceFilter {
        get {
            let string = UserDefaults.standard.string(forKey: LastSelected.raceFilter)
            return string.flatMap { RaceFilter(title: $0) } ?? RaceFilter.joined
        }
        set {
            UserDefaults.standard.set(newValue.title, forKey: LastSelected.raceFilter)
            UserDefaults.standard.synchronize()
        }
    }

    static var lastSelectedSeriesFilter: SeriesFilter {
        get {
            let string = UserDefaults.standard.string(forKey: LastSelected.seriesFilter)
            return string.flatMap { SeriesFilter(title: $0) } ?? SeriesFilter.default
        }
        set {
            UserDefaults.standard.set(newValue.title, forKey: LastSelected.seriesFilter)
            UserDefaults.standard.synchronize()
        }
    }
    
    static var hideNotificationSchedulerAlerts: Bool {
        get {
            return UserDefaults.standard.bool(forKey: Prefs.schedulerAlerts)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Prefs.schedulerAlerts)
            UserDefaults.standard.synchronize()
        }
    }
}
