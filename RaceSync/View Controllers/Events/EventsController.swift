//
//  EventsController.swift
//  RaceSync
//
//  Created by Ignacio Romero on 2026-05-18.
//  Copyright © 2026 MultiGP Inc. All rights reserved.
//

import UIKit
import RaceSyncAPI

enum EventSessionFilter: EnumTitle, Hashable {
    case all, mySchedule, spec, openFly
    
    public var title: String {
        switch self {
        case .all:          return "All"
        case .mySchedule:   return "My Schedule"
        case .spec:         return "Spec"
        case .openFly:      return "Open Fly"
        }
    }
    
    public var image: UIImage? {
        switch self {
        case .mySchedule:   return SystemImg.star
        default:            return nil
        }
    }

}

class EventsController {

    // MARK: - Public Variables

    let eventApi = EventApi()
    var io26Event: Event?
    var ios26Dates: [Date] = EventSession.io26Dates(from: "2026-06-10", to: "2026-06-14")
    var bucketlist = EventSessionBucketlist(eventName: "mgp_io26", timezone: MGPEventTimeZone!)

    var selectedDate: Date?
    var selectedFilter: EventSessionFilter = AppplicationPreferences.lastSelectedEventFilter

    // MARK: - Public Functions

    func didFetchEvents() -> Bool {
        io26Event != nil
    }

    func fetchIO26Event(_ forced: Bool = false, _ completion: @escaping ObjectCompletionBlock<Event>) {
        
        eventApi.getIO26Event(forced: forced) { [weak self] event, error in
            if let event {
                self?.io26Event = event
                completion(event, nil)
            } else {
                completion(nil, error)
            }
        }
    }

    func reloadSessions() -> [EventSession] {
        if selectedDate == nil {
            selectedDate = ios26Dates.initialDate(timezone: MGPEventTimeZone!)
        }

        guard let date = selectedDate else { return [] }
        return mergedSessions(for: date, with: .scheduled, filter: selectedFilter)
    }

    func track(for session: EventSession) -> EventTrack? {
        io26Event?.tracks?.first { $0.id == session.trackId }
    }

    func color(for track: EventTrack?) -> UIColor {
        guard let id = track?.id else { return Color.gray300 }
        return trackColors[id] ?? Color.gray300
    }

    // MARK: - Private

    private let trackColors: [String: UIColor] = [
        "main_stage":    UIColor(hex: "4a6cf7"),
        "world_cup_1":   UIColor(hex: "e8384f"),
        "all_skills":    UIColor(hex: "ca8a04"),
        "whoopville":    UIColor(hex: "9b59b6"),
        "world_cup_2":   UIColor(hex: "f06070"),
        "spec":          UIColor(hex: "22c55e"),
        "gq_rookie":     UIColor(hex: "06b6d4"),
        "tiny_trainier": UIColor(hex: "2dd4bf")
    ]

    func sessions(for date: Date, with status: EventStatus? = nil, id trackId: ObjectId? = nil) -> [EventSession] {
        guard let sessions = io26Event?.sessions else { return [] }

        let calendar = Calendar.current
        return sessions.filter { session in
            guard let sessionDate = session.date,
                  calendar.isDate(sessionDate, inSameDayAs: date) else { return false }
            if let status, session.status != status { return false }
            if let trackId, session.trackId != trackId { return false }
            return true
        }
    }

    func mergedSessions(for date: Date, with status: EventStatus? = nil, id trackId: ObjectId? = nil, filter: EventSessionFilter = .all) -> [EventSession] {
        let sessions = sessions(for: date, with: status, id: trackId)
            .sorted { ($0.startTime ?? .distantPast) < ($1.startTime ?? .distantPast) }

        var merged: [EventSession] = []

        for session in sessions {
            let match = merged.last(where: {
                $0.activity == session.activity &&
                $0.trackId  == session.trackId &&
                isConsecutive($0, session)
            })

            if let match {
                match.startTime = min(match.startTime ?? .distantFuture, session.startTime ?? .distantFuture)
                match.endTime = session.endTime
            } else {
                merged.append(session.copy())
            }
        }

        return apply(filter: filter, to: merged, for: date)
    }

    private func apply(filter: EventSessionFilter, to sessions: [EventSession], for date: Date) -> [EventSession] {
        switch filter {
        case .all:
            return sessions
        case .mySchedule:
            return sessions.filter { bucketlist.contains($0, for: date) }
        case .spec:
            return sessions.filter { $0.activity.containsAny(["spec", "AER"], caseInsensitive: true) }
        case .openFly:
            return sessions.filter { $0.activity.containsAny(["open fly", "openfly"], caseInsensitive: true) }
        }
    }

    private func isConsecutive(_ a: EventSession, _ b: EventSession) -> Bool {
        guard let endA = a.endTime, let startB = b.startTime else { return false }
        return startB.timeIntervalSince(endA) <= 300
    }
}
