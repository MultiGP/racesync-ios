//
//  ImageConstants.swift
//  RaceSync
//
//  Created by Ignacio Romero Zurbuchen on 2020-02-23.
//  Copyright © 2020 MultiGP Inc. All rights reserved.
//

import UIKit

enum PlaceholderImg {
    static let small = UIImage(named: "placeholder_small")
    static let medium = UIImage(named: "placeholder_medium")
    static let large = UIImage(named: "placeholder_large")
    static let profileAvatar = UIImage(named: "placeholder_profile_avatar")
    static let profileBkgd = UIImage(named: "placeholder_profile_background")
    static let shimmerList = UIImage(named: "placeholder_shimmer_list")
}

enum ButtonImg {
    static let back = UIImage(named: "icn_navbar_back")
    static let close = UIImage(named: "icn_navbar_close")
    static let add = UIImage(named: "icn_navbar_add")
    static let share = UIImage(named: "icn_navbar_share")
    static let edit = UIImage(named: "icn_navbar_edit")
    static let calendar = UIImage(named: "icn_navbar_calendar")
    static let settings = UIImage(named: "icn_navbar_settings")
    static let notifications = UIImage(named: "icn_navbar_notifications")
    static let search = UIImage(named: "icn_navbar_search")
    static let filter = UIImage(named: "icn_navbar_filter")
    static let map = UIImage(named: "icn_navbar_map")
    static let radius = UIImage(named: "icn_settings_radius")
    static let empty = UIImage(named: "icn_navbar_empty")
}

enum SystemImg {

    static let calendarCclock = UIImage(systemName:"calendar.badge.clock") // iOS 14.0+
    static let person = UIImage(systemName:"person.2") // iOS 13.0+
    static let personFill = UIImage(systemName:"person.2.fill") // iOS 13.0+
    static let safari = UIImage(systemName:"safari") // iOS 13.0+
    static let banknote = UIImage(systemName:"banknote") // iOS 14.0+
    static let banknoteFill = UIImage(systemName:"banknote.fill") // iOS 14.0+
    static let gearshape = UIImage(systemName:"gearshape") // iOS 14.0+
    static let gearshapeFill = UIImage(systemName:"gearshape.fill") // iOS 14.0+

    static var flagCheckeredCrossed: UIImage? {
        if #available(iOS 18.0, *) {
            return UIImage(systemName:"flag.pattern.checkered.2.crossed") // iOS 18.0+
        } else if #available(iOS 16.0, *) {
            return UIImage(systemName:"flag.checkered.2.crossed") // iOS 16.0+
        } else {
            return UIImage(systemName:"flag.2.crossed") // iOS 15.0+
        }
    }

    static var flagCheckered: UIImage? {
        if #available(iOS 18.0, *) {
            return UIImage(systemName:"flag.pattern.checkered") // iOS 18.0+
        } else if #available(iOS 16.0, *) {
            return UIImage(systemName:"flag.checkered") // iOS 16.0+
        } else {
            return UIImage(systemName:"checkerboard.rectangle") // iOS 14.0+
        }
    }

    static var medal: UIImage? {
        if #available(iOS 16.0, *) {
            return UIImage(systemName:"medal") // iOS 16.0+
        } else {
            return UIImage(named: "icn_tab_medal")
        }
    }

    static var medalFill: UIImage? {
        if #available(iOS 16.0, *) {
            return UIImage(systemName:"medal.fill") // iOS 16.0+
        } else {
            return UIImage(systemName:"")
        }
    }

    static var trophy: UIImage? {
        if #available(iOS 16.0, *) {
            return UIImage(systemName:"trophy") // iOS 16.0+
        } else {
            return UIImage(systemName:"")
        }
    }

    static var trophyFill: UIImage? {
        if #available(iOS 16.0, *) {
            return UIImage(systemName:"trophy.fill") // iOS 16.0+
        } else {
            return UIImage(systemName:"")
        }
    }
}
