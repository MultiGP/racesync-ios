//
//  ImageConstants.swift
//  RaceSync
//
//  Created by Ignacio Romero Zurbuchen on 2020-02-23.
//  Copyright © 2020 MultiGP Inc. All rights reserved.
//

import UIKit

enum LogoImg {
    static let header = UIImage(named: "racesync_logo_header")
    static let app_icon = UIImage(named: "AppIcon60x60")
    static let watermark = UIImage(named: "icn_mgp_watermark")

    static let photos = UIImage(named: "icn_apple_photos")
    static let share = UIImage(named: "icn_apple_share")
    static let insta = UIImage(named: "icn_meta_instagram")
    static let livefpv = UIImage(named: "logo_livefpv")
    static let fpvscores = UIImage(named: "logo_fpvscores")

    static let activity_calendar = UIImage(named: "icn_activity_calendar")
    static let activity_safari = UIImage(named: "icn_activity_safari")
    static let activity_mgp = UIImage(named: "icn_activity_mgp")
    static let activity_copylink = UIImage(named: "icn_activity_copylink")

    static let activity_livefpv = UIImage(named: "icn_activity_livefpv")
    static let activity_facebook = UIImage(named: "icn_activity_facebook")
    static let activity_twitter = UIImage(named: "icn_activity_twitter")
    static let activity_youtube = UIImage(named: "icn_activity_youtube")
    static let activity_instagram = UIImage(named: "icn_activity_instagram")
    static let activity_meetup = UIImage(named: "icn_activity_meetup")
    static let activity_paypal = UIImage(named: "icn_activity_paypal")
}

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
    static let safari = UIImage(named: "icn_navbar_safari")
    static let empty = UIImage(named: "icn_navbar_empty")
    static let qrcode = UIImage(named: "icn_navbar_qrcode")
    static let directions = UIImage(named: "icn_navbar_directions")
    static let camera = UIImage(named: "icn_navbar_camera")
    static let member = UIImage(named: "icn_member")

    static let join_check = UIImage(named: "icn_join_check")
    static let join_cross = UIImage(named: "icn_join_cross")

    static let radius = UIImage(named: "icn_settings_radius")

    static let checkmark = UIImage(named: "icn_cell_checkmark")

//    static let pin_small = UIImage(named: "icn_pin_small")
    static let cal_small = UIImage(named: "icn_calendar_small")
    static let race_small = UIImage(named: "icn_race_small")
    static let chapter_small = UIImage(named: "icn_chapter_small")
    static let member_small = UIImage(named: "icn_member_small")
    static let badge_small = UIImage(named: "icn_badge_small")
    static let date_path2 = UIImage(named: "icn_date_path_progress")
    static let date_path1 = UIImage(named: "icn_date_path_continuous")
    static let map_annotation = UIImage(named: "icn_map_annotation")
    static let trophy = UIImage(named: "icn_trophy_qualifier")
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
    static let stack = UIImage(systemName:"rectangle.stack") // iOS 13.0+
    static let stackFill = UIImage(systemName:"rectangle.stack.fill") // iOS 13.0+

    static let pin_small = UIImage(systemName:"mappin.and.ellipse") // iOS 13.0+
    static let globe = UIImage(systemName:"globe") // iOS 13.0+

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
