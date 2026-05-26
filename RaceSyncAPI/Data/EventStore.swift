//
//  EventStore.swift
//  RaceSyncAPI
//
//  Created by Ignacio Romero on 2026-05-24.
//  Copyright © 2026 MultiGP Inc. All rights reserved.
//

import Foundation
import ObjectMapper

class EventStore {

    static let shared = EventStore()

    func save(_ event: Event) {
        guard let json = Mapper<Event>().toJSONString(event, prettyPrint: true),
              let data = json.data(using: .utf8) else {
            print("[EventStore] Serialization failed")
            return
        }
        do {
            try data.write(to: fileURL)
        } catch {
            print("[EventStore] Write failed: \(error)")
        }
    }

    func load() -> Event? {
        guard let data = try? Data(contentsOf: fileURL),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        return Mapper<Event>().map(JSONObject: json)
    }
    
    private let fileURL = FileStore.url(for: "io26_event.json")
}
