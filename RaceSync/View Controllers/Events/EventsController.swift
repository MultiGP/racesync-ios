//
//  EventsController.swift
//  RaceSync
//
//  Created by Ignacio Romero on 2026-05-18.
//  Copyright © 2026 MultiGP Inc. All rights reserved.
//

import UIKit
import RaceSyncAPI

class EventsController {
    
    // MARK: - Public Variables

    let eventApi = MGPEventApi()
    var io26Event: MGPEvent?
    var ios26Dates: [Date] = MGPEventSession.io26Dates(from: "2026-06-10", to: "2026-06-14")
    
    // MARK: - Private Variables
    

    // MARK: - Public Functions
    
    public func track(for session: MGPEventSession) -> MGPEventTrack? {
        guard let tracks = io26Event?.tracks else { return nil }
        
        let trackId = session.trackId
        return tracks.first(where: { $0.id == trackId })
    }
    
    public func fetchIO26Event(_ completion: @escaping ObjectCompletionBlock<MGPEvent>) {
        eventApi.getIO26Event { event, error in
            if let event = event {
                self.io26Event = event
                completion(event, nil)
            } else if error != nil {
                completion(nil, error)
            }
        }
    }
    
    public func didFetchEvents() -> Bool {
        return io26Event != nil
    }
    
    public func io26Sessions(for date: Date, with status: MGPEventStatus? = nil, id trackId: ObjectId? = nil) -> [MGPEventSession] {
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
    
    public func io26MergedSessions(for date: Date, with status: MGPEventStatus? = nil, id trackId: ObjectId? = nil) -> [MGPEventSession] {
        let sessions = io26Sessions(for: date, with: status, id: trackId)
            .sorted { ($0.startTime ?? .distantPast) < ($1.startTime ?? .distantPast) }

        var merged: [MGPEventSession] = []

        for session in sessions {
            let match = merged.last(where: {
                $0.activity == session.activity &&
                $0.trackId  == session.trackId &&
                isConsecutive($0, session)
            })

            if let match {
                match.endTime = session.endTime
            } else {
                merged.append(session.copy())
            }
        }

        return merged
    }
    
    public func color(for track: MGPEventTrack?) -> UIColor {
        guard let id = track?.id else { return Color.gray300 }
        
        if id == "main_stage" {
            return UIColor(hex: "4a6cf7")
        } else if id == "world_cup_1" {
            return UIColor(hex: "e8384f")
        } else if id == "all_skills" {
            return UIColor(hex: "ca8a04")
        } else if id == "whoopville" {
            return UIColor(hex: "9b59b6")
        } else if id == "world_cup_2" {
            return UIColor(hex: "f06070")
        } else if id == "spec" {
            return UIColor(hex: "22c55e")
        } else if id == "gq_rookie" {
            return UIColor(hex: "06b6d4")
        } else if id == "tiny_trainier" {
            return UIColor(hex: "2dd4bf")
        }
        
        return Color.gray300
    }
    
    private func isConsecutive(_ a: MGPEventSession, _ b: MGPEventSession) -> Bool {
        guard let endA = a.endTime, let startB = b.startTime else { return false }
        // Allow up to 5 min gap to account for any scheduling slack
        return startB.timeIntervalSince(endA) <= 300
    }
    
    
}
