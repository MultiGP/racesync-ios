//
//  DateUtil.swift
//  RaceSyncAPI
//
//  Created by Ignacio Romero Zurbuchen on 2019-11-19.
//  Copyright © 2019 MultiGP Inc. All rights reserved.
//

import Foundation

public class DateUtil {

    public static var standardDateFormatter: DateFormatter = {
        return DateFormatter(withFormat: StandardDateTimeFormat, locale: USLocale)
    }()

    public static var oldDateFormatter: DateFormatter = {
        return DateFormatter(withFormat: OldDateTimeFormat, locale: USLocale)
    }()

    public static var utcDateFormatter: DateFormatter = {
        let formatter = DateFormatter(withFormat: StandardDateTimeFormat, locale: USLocale)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()

    public static func deserializeJSONDate(_ jsonDate: String) -> Date? {
        if let date = standardDateFormatter.date(from: jsonDate) {
            return date
        }
        if let date = oldDateFormatter.date(from: jsonDate) {
            return date
        }
        return nil
    }

    public static func deserializeUTCJSONDate(_ jsonDate: String) -> Date? {
        return utcDateFormatter.date(from: jsonDate)
    }

    public static func localizedString(from date: Date?, full: Bool = false) -> String? {
        guard let date = date else { return nil }

        if full {
            if date.isInThisYear {
                return displayFullDateTimeFormatter.string(from: date)
            } else {
                return displayFullDateTimeYearFormatter.string(from: date)
            }
        }
        else if date.isInThisYear || date.timeIntervalSinceNow.sign == .plus {
            return displayDateTimeFormatter.string(from: date)
        } else {
            return displayDateFormatter.string(from: date)
        }
    }
}

public extension DateUtil {

    static let displayFullDateTime2LineFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d\n@ h:mm a"
        formatter.amSymbol = "AM"
        formatter.pmSymbol = "PM"
        return formatter
    }()

    static let displayFullDateTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d @ h:mm a"
        formatter.amSymbol = "AM"
        formatter.pmSymbol = "PM"
        return formatter
    }()

    static let displayFullDateTimeYearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy @ h:mm a"
        formatter.amSymbol = "AM"
        formatter.pmSymbol = "PM"
        return formatter
    }()

    static let displayDateTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EE, MMM d @ h:mm a"
        formatter.amSymbol = "AM"
        formatter.pmSymbol = "PM"
        return formatter
    }()

    static let displayDayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EE, MMM d"
        return formatter
    }()

    static let displayDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter
    }()
    
    static let displayDateFormatter2: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }()

    static let displayTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "@ h:mm a"
        return formatter
    }()

    static let displayTimeFormatter2: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }()

    static let isoDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter
    }()
}
