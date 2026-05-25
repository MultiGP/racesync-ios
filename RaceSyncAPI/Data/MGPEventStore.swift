//
//  MGPEventStore.swift
//  RaceSyncAPI
//
//  Created by Ignacio Romero on 2026-05-24.
//  Copyright © 2026 MultiGP Inc. All rights reserved.
//

import Foundation
import ObjectMapper

class MGPEventStore {

    static let shared = MGPEventStore()

    func save(_ event: MGPEvent) {
        guard let json = Mapper<MGPEvent>().toJSONString(event, prettyPrint: true),
              let data = json.data(using: .utf8) else {
            print("[MGPEventStore] Serialization failed")
            return
        }
        do {
            try data.write(to: fileURL)
        } catch {
            print("[MGPEventStore] Write failed: \(error)")
        }
    }

    func load() -> MGPEvent? {
        guard let data = try? Data(contentsOf: fileURL),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        return Mapper<MGPEvent>().map(JSONObject: json)
    }
    
    private let fileURL = FileStore.url(for: "io26_event.json")
}
