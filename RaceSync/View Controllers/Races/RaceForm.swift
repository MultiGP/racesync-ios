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
        case .specific:     return "Race Details"
        }
    }

    public var footer: String? {
        switch self {
        default:            return nil
        }
    }
}

enum RaceFormRow: Int, EnumTitle {
    case chapter, `class`, content, endDate, limit, fee, feeRequired, format, location, name,
         notify, privacy, rounds, schedule, scoring, season, startDate, zDepth, zIterator, zNoKiosk, zPrediction

    public var title: String {
        switch self {
        case .chapter:      return "Chapter"
        case .class:        return "Race Class"
        case .content:      return "Description"
        case .endDate:      return "End Date"
        case .limit:        return "Pilot Limit"
        case .fee:          return "Race Fee"
        case .feeRequired:  return "Payment Required to Join"
        case .format:       return "Race Format"
        case .location:     return "Location"
        case .name:         return "Name"
        case .notify:       return "Notify Pilots"
        case .privacy:      return "Event Privacy"
        case .rounds:       return "Pack Limit"
        case .schedule:     return "Schedule"
        case .scoring:      return "Fun Fly"
        case .season:       return "Season"
        case .startDate:    return "Start Date"
        case .zDepth:       return "Pilot Queue Limit"
        case .zIterator:    return "Rest Rounds"
        case .zNoKiosk:     return "Allow Pilot Devices to Q"
        case .zPrediction:  return "Predict Round Times"
        }
    }

    public var tooltip: String? {
        switch self {
        case .chapter:      return nil
        case .class:        return nil
        case .content:      return "Enter the details of this event"
        case .endDate:      return nil
        case .limit:        return "Leave blank for no limit"
        case .fee:          return "Race Fee (USD)"
        case .feeRequired:  return nil
        case .format:       return nil
        case .location:     return nil
        case .name:         return "Name of this event"
        case .notify:       return nil
        case .privacy:      return "Allow everyone or only chapter members to see this event"
        case .rounds:       return "Sets the maximum number of packs (rounds) that a pilot can join"
        case .schedule:     return nil
        case .scoring:      return "Fun Fly disables scoring"
        case .season:       return nil
        case .startDate:    return nil
        case .zDepth:       return "How many times a pilot can be in the line"
        case .zIterator:    return "How many rounds to wait between runs"
        case .zNoKiosk:     return "Allows ZippyQ sign up from your phone"
        case .zPrediction:  return "Displays actual and predicted round start times"
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
        case .limit:
            return (raceData.pilotLimit > 0) ? "\(raceData.pilotLimit)" : "No limit"
        case .fee:
            return String(format: "$%.2f USD", raceData.fee)
        case .feeRequired:
            return raceData.feeRequired ? "" : nil // will be converted to Bool
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
        case .zDepth:
            return "\(raceData.zippyqDepth)"
        case .zIterator:
            return "\(raceData.zippyqIterator)"
        case .zNoKiosk:
            return raceData.zippyqNoKiosk ? "" : nil // will be converted to Bool
        case .zPrediction:
            return raceData.zippyqPredictTimes ? "" : nil // will be converted to Bool
        }
    }

    var isRequired: Bool {
        switch self {
        case .name, .startDate, .chapter, .class, .format, .schedule:
            return true
        default:
            return false
        }
    }

    var formType: FormType {
        switch self {
        case .name, .limit, .fee, .rounds, .zDepth, .zIterator:
            return .textfield
        case .startDate, .endDate:
            return .datePicker
        case .scoring, .feeRequired, .notify, .zNoKiosk, .zPrediction:
            return .switch
        case .content:
            return .textEditor
        default:
            return .textPicker
        }
    }

    var keyboardType: UIKeyboardType {
        switch self {
        case .limit, .fee:
            return UIKeyboardType.decimalPad
        case .rounds, .zDepth, .zIterator:
            return UIKeyboardType.numberPad
        default:
            return UIKeyboardType.default
        }
    }

    var canQuickForm: Bool {
        switch self.formType {
        case .textEditor:
            return false
        default:
            return true
        }
    }
}
