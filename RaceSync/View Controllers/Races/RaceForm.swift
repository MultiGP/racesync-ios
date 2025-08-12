//
//  NewRaceForm.swift
//  RaceSync
//
//  Created by Ignacio Romero Zurbuchen on 2022-12-27.
//  Copyright © 2022 MultiGP Inc. All rights reserved.
//

import UIKit
import RaceSyncAPI

enum RaceFormMode: Int {
    case new, update
}

enum RaceFormSection: Int {
    case general, specific

    public var header: String {
        switch self {
        case .general:      return "General Details "
        case .specific:     return "Specific Details"
        }
    }

    public var footer: String? {
        switch self {
        case .general:      return "* Required fields"
        case .specific:     return "** Broadcasts a notification to all chapter members."
        }
    }
}

enum RaceFormRow: Int, EnumTitle {
    case name, startDate, endDate, chapter, `class`, format, privacy, fee, feeRequired, status,
         scoring, schedule, rounds, season, location, content, notify

    public var title: String {
        switch self {
        case .name:         return "Name"
        case .startDate:    return "Start Date"
        case .endDate:      return "End Date"
        case .chapter:      return "Chapter"
        case .class:        return "Race Class"
        case .format:       return "Race Format"
        case .privacy:      return "Event Privacy"
        case .fee:          return "Race Fee"
        case .feeRequired:  return "Payment Required to Join"
        case .status:       return "Status"
        case .scoring:      return "Fun Fly"
        case .schedule:     return "Schedule"
        case .rounds:       return "Pack Limit"
        case .season:       return "Season"
        case .location:     return "Location"
        case .content:      return "Description"
        case .notify:       return "Notify Pilots **"
        }
    }

    public var tooltip: String? {
        switch self {
        case .name:         return "Name of this event"
        case .fee:          return "Race Fee (USD)"
        case .content:      return "Enter the details of this event"
        default: return nil
        }
    }
}

extension RaceFormRow {

    func value(from raceData: RaceData) -> String? {
        switch self {
        case .name:
            return raceData.name
        case .startDate:
            if let date = raceData.startDate {
                return DateUtil.localizedString(from: date)
            }
            return nil
        case .endDate:
            if let date = raceData.endDate {
                return DateUtil.localizedString(from: date)
            }
            return nil
        case .chapter:
            return raceData.chapterName
        case .class:
            return RaceClass(rawValue: raceData.raceClass)?.title
        case .format:
            return ScoringFormat(rawValue: raceData.format)?.title
        case .schedule:
            return QualifyingType(rawValue: raceData.qualifying)?.title
        case .privacy:
            return EventType(rawValue: raceData.privacy)?.title
        case .fee:
            return String(format: "$%.2f USD", raceData.fee)
        case .feeRequired:
            return raceData.feeRequired ? "" : nil // will be converted to Bool
        case .status:
            return RaceStatus(rawValue: raceData.status)?.title
        case .scoring:
            return raceData.funfly ? "" : nil // will be converted to Bool
        case .rounds:
            return "\(raceData.rounds)"
        case .season:
            return raceData.seasonName
        case .location:
            return raceData.courseName
        case .content:
            if let text = raceData.content, text.count > 0 {
                return text.stripHTML(true).safeSubstring(to: 20).capitalized + "…"
            }
            return nil
        case .notify:
            return raceData.sendNotification ? "" : nil // will be converted to Bool
        }
    }

    var isRowRequired: Bool {
        switch self {
        case .name, .startDate, .chapter:
            return true
        default:
            return false
        }
    }

    func requiredValue(from data: RaceData) -> String? {
        switch self {
        case .name:         return data.name
        case .startDate:    return data.startDateString
        default:            return nil
        }
    }

    var formType: FormType {
        switch self {
        case .name, .fee:
            return .textfield
        case .startDate, .endDate:
            return .datePicker
        case .scoring, .feeRequired, .notify:
            return .switch
        case .content:
            return .textEditor
        default:
            return .textPicker
        }
    }

    var keyboardType: UIKeyboardType {
        switch self {
        case .fee:
            return UIKeyboardType.decimalPad
        default:
            return UIKeyboardType.default
        }
    }
}
