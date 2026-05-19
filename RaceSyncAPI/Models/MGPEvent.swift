//
//  Event.swift
//  RaceSyncAPI
//
//  Created by Ignacio Romero on 2026-05-18.
//  Copyright © 2026 MultiGP Inc. All rights reserved.
//

import Foundation
import ObjectMapper

public class MGPEvent: Mappable, Descriptable {
    
    public var name: String = ""
    public var venue: String = ""
    public var lastUpdated: Date?
    
    public var tracks: [MGPEventTrack]? = nil
    public var sessions: [MGPEventSession]? = nil
    
    // MARK: - Initialization

    public required convenience init?(map: Map) {
        self.init()
        self.mapping(map: map)
    }

    public func mapping(map: Map) {
        name <- map["event"]
        venue <- map["venue"]
        lastUpdated <- (map["lastUpdated"], MapperUtil.dateTransform)
        
        tracks <- map["tracks"]
        sessions <- map["sessions"]
    }
}

public class MGPEventTrack: Mappable, Descriptable {
    
    public var id: ObjectId = ""
    public var name: String = ""
    public var location: String = ""
    
    // MARK: - Initialization

    public required convenience init?(map: Map) {
        self.init()
        self.mapping(map: map)
    }

    public func mapping(map: Map) {
        id <- map["id"]
        name <- map["name"]
        location <- map["location"]
    }
}

public class MGPEventSession: Mappable, Descriptable {
    
    public var id: ObjectId = ""

    public var date: Date?
    public var startTime: Date?
    public var endTime: Date?
    public var dayName: String = ""

    public var trackId: ObjectId = ""
    public var activity: String = ""
    public var status: MGPEventStatus = .closed

    // MARK: - Initialization

    public required convenience init?(map: Map) {
        self.init()
        self.mapping(map: map)
    }

    public func mapping(map: Map) {
        id       <- map["id"]
        dayName  <- map["day"]
        activity <- map["activity"]
        trackId  <- map["trackId"]
        status   <- (map["status"], EnumTransform<MGPEventStatus>())

        // Local vars — never stored on self
        var rawDate:      String?
        var rawStartTime: String?
        var rawEndTime:   String?

        rawDate      <- map["date"]
        rawStartTime <- map["startTime"]
        rawEndTime   <- map["endTime"]

        date      = Self.parseDate(rawDate)
        startTime = Self.parseDateTime(date: rawDate, time: rawStartTime)
        endTime   = Self.parseDateTime(date: rawDate, time: rawEndTime)
    }
}

public enum MGPEventStatus: String, EnumTitle {
    
    public var title: String {
        return self.rawValue.capitalized
    }
    
    case closed = "closed"
    case scheduled = "scheduled"
}

extension MGPEventSession {
    
    public static func io26Dates(from start: String, to end: String) -> [Date] {
        guard let startDate = io26Date(from: start),
              let endDate   = io26Date(from: end),
              startDate <= endDate else { return [] }

        var dates: [Date] = []
        var current = startDate
        let calendar = Calendar.current

        while current <= endDate {
            dates.append(current)
            guard let next = calendar.date(byAdding: .day, value: 1, to: current) else { break }
            current = next
        }

        return dates
    }

    public static func io26Date(from string: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "America/Indiana/Indianapolis")

        return formatter.date(from: string)
    }
    
    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = TimeZone(identifier: "UTC")
        return f
    }()

    private static let dateTimeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm"
        f.timeZone = TimeZone(identifier: "UTC")
        return f
    }()

    private static func parseDate(_ dateString: String?) -> Date? {
        guard let dateString else { return nil }
        return dateFormatter.date(from: dateString)
    }

    private static func parseDateTime(date dateString: String?, time timeString: String?) -> Date? {
        guard let dateString, let timeString else { return nil }
        return dateTimeFormatter.date(from: "\(dateString) \(timeString)")
    }
}
