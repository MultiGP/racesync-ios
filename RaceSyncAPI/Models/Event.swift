//
//  Event.swift
//  RaceSyncAPI
//
//  Created by Ignacio Romero on 2026-05-18.
//  Copyright © 2026 MultiGP Inc. All rights reserved.
//

import Foundation
import ObjectMapper

public let MGPEventTimeZone: TimeZone? = TimeZone(identifier: "America/Indiana/Indianapolis")

public class Event: Mappable, Descriptable {
    
    public var name: String = ""
    public var venue: String = ""
    public var lastUpdated: Date?
    
    public var tracks: [EventTrack]? = nil
    public var sessions: [EventSession]? = nil
    
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

public class EventTrack: Mappable, Descriptable {
    
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

public class EventSession: Mappable, Descriptable {
    
    public var id: ObjectId = ""

    public var date: Date? = nil
    public var startTime: Date? = nil
    public var endTime: Date? = nil
    public var dayName: String = ""

    public var trackId: ObjectId = ""
    public var activity: String = ""
    public var status: EventStatus = .closed

    public var raceId: ObjectId? = nil

    // MARK: - Initialization

    public required convenience init?(map: Map) {
        self.init()
        self.mapping(map: map)
    }

    public func mapping(map: Map) {
        id       <- map[ParamKey.id]
        dayName  <- map["day"]
        activity <- map["activity"]
        trackId  <- map["trackId"]
        status   <- (map[ParamKey.status], EnumTransform<EventStatus>())
        raceId   <- map[ParamKey.raceId]
        
        _rawDate      <- map["date"]
        _rawStartTime <- map["startTime"]
        _rawEndTime   <- map["endTime"]

        // Only parse dates when deserializing
        if map.mappingType == .fromJSON {
            date      = Self.parseDate(_rawDate)
            startTime = Self.parseDateTime(date: _rawDate, time: _rawStartTime)
            endTime   = Self.parseDateTime(date: _rawDate, time: _rawEndTime)
        }
    }
    
    fileprivate var _rawDate: String?
    fileprivate var _rawStartTime: String?
    fileprivate var _rawEndTime: String?
}

public enum EventStatus: String, EnumTitle {
    
    public var title: String {
        return self.rawValue.capitalized
    }
    
    case closed = "closed"
    case scheduled = "scheduled"
}

extension EventSession {
    
    public static func io26Dates(from start: String, to end: String) -> [Date] {
        guard let startDate = dateFormatter.date(from: start),
              let endDate   = dateFormatter.date(from: end),
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

    public static func io26Date(from string: String) -> Date {
        return dateFormatter.date(from: string)!
    }
    
    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = MGPEventTimeZone
        f.locale = Locale(identifier: USLocale)
        return f
    }()

    private static let dateTimeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm"
        f.timeZone = MGPEventTimeZone
        f.locale = Locale(identifier: USLocale)
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

extension EventSession: Hashable {
    public static func == (lhs: EventSession, rhs: EventSession) -> Bool {
        lhs.id == rhs.id
    }
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension EventSession {
    
    public func copy() -> EventSession {
        let copy = EventSession()
        copy.id        = id
        copy.dayName   = dayName
        copy.trackId   = trackId
        copy.activity  = activity
        copy.status    = status
        copy.raceId    = raceId
        copy.date      = date
        copy.startTime = startTime
        copy.endTime   = endTime
        copy._rawDate = _rawDate
        copy._rawStartTime = _rawStartTime
        copy._rawEndTime = _rawEndTime
        return copy
    }
}
