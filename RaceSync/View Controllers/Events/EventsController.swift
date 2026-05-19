//
//  EventsController.swift
//  RaceSync
//
//  Created by Ignacio Romero on 2026-05-18.
//  Copyright © 2026 MultiGP Inc. All rights reserved.
//

import Foundation
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
}
