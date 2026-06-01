//
//  EventSessionBucketlist.swift
//  RaceSync
//
//  Created by Ignacio Romero Zurbuchen on 2026-05-23.
//  Copyright © 2026 MultiGP Inc. All rights reserved.
//

import Foundation
import RaceSyncAPI
import ObjectMapper

/// Persists favorited EventSession objects per day, scoped to a specific event.
class EventSessionBucketlist {

    // MARK: - Init

    init(eventName: String, timezone: TimeZone) {
        let filename = FileStore.sanitizedFileName(from: eventName)
        self.fileURL = FileStore.url(for: filename)
        self.timezone = timezone
        load()
    }

    // MARK: - Public API

    /// Saves a single session for the given day. Skips duplicates by id.
    func save(_ session: EventSession, for day: Date) {
        let key = dayKey(for: day)
        var bucket = buckets[key] ?? []
        guard !bucket.contains(where: { $0.id == session.id }) else { return }
        bucket.append(session)
        buckets[key] = bucket
        persist()
    }

    /// Saves an array of sessions for the given day. Skips duplicates by id.
    func save(_ sessions: [EventSession], for day: Date) {
        let key = dayKey(for: day)
        var bucket = buckets[key] ?? []
        for session in sessions {
            guard !bucket.contains(where: { $0.id == session.id }) else { continue }
            bucket.append(session)
        }
        buckets[key] = bucket
        persist()
    }

    /// Returns all saved sessions for the given day
    func load(for day: Date) -> [EventSession] {
        return buckets[dayKey(for: day)] ?? []
    }

    /// Deletes a single session from the given day's bucket.
    func delete(_ session: EventSession, for day: Date) {
        let key = dayKey(for: day)
        buckets[key]?.removeAll { $0.id == session.id }
        if buckets[key]?.isEmpty == true { buckets.removeValue(forKey: key) }
        persist()
    }

    /// Deletes all sessions across all days.
    func deleteAll() {
        buckets.removeAll()
        persist()
    }

    /// Returns the number of saved sessions for the given day.
    func count(for day: Date) -> Int {
        return buckets[dayKey(for: day)]?.count ?? 0
    }

    // MARK: - Private

    fileprivate var buckets: [String: [EventSession]] = [:]
    fileprivate let fileURL: URL
    fileprivate let timezone: TimeZone

    fileprivate lazy var dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "dd-MM-yyyy"
        f.timeZone = timezone
        return f
    }()

    fileprivate func dayKey(for date: Date) -> String {
        return dayFormatter.string(from: date)
    }

    fileprivate func persist() {
        // Serialize: [String: [[String: Any]]] using ObjectMapper
        var raw: [String: [[String: Any]]] = [:]
        for (key, sessions) in buckets {
            raw[key] = sessions.map { $0.toJSON() }
        }

        guard let data = try? JSONSerialization.data(withJSONObject: raw, options: .prettyPrinted) else {
            print("[EventSessionBucketlist] Serialization failed")
            return
        }
        do {
            try data.write(to: fileURL)
        } catch {
            print("[EventSessionBucketlist] Write failed: \(error)")
        }
    }

    fileprivate func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let raw = try? JSONSerialization.jsonObject(with: data) as? [String: [[String: Any]]] else {
            return
        }
        for (key, jsonArray) in raw {
            buckets[key] = jsonArray.compactMap { EventSession(JSON: $0) }
        }
    }
}

extension EventSessionBucketlist {
    
    func contains(_ session: EventSession, for day: Date?) -> Bool {
        guard let day = day else { return false }
        return buckets[dayKey(for: day)]?.contains(where: { $0.id == session.id }) ?? false
    }
}
