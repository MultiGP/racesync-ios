//
//  PushMessagesStore.swift
//  RaceSync
//
//  Created by Ignacio Romero Zurbuchen on 2025-05-26.
//  Copyright © 2025 MultiGP Inc. All rights reserved.
//

import Foundation

class PushMessagesStore {

    // MARK: - Public

    init() {
        loadMessages()
    }

    func getAllMessages() -> [PushMessage] {
        return messages.sorted { $0.timestamp > $1.timestamp }
    }

    func remove(_ message: PushMessage) {
        messages.removeAll { $0.timestamp == message.timestamp } // TODO: Make PushMessage Equatable
        saveMessages()
    }

    func removeAll() {
        messages.removeAll()
        saveMessages()
    }

    // MARK: - Parsing

    @discardableResult
    func addEphemeralMessage(with title: String, body: String, type: String, broadcast: Bool = false) -> PushMessage? {
        let object: [String: Any] = [
            "aps": [
                "alert": ["title": title, "body": body]
            ],
            "customData": [
                "type": type
            ]
        ]
        return parseNotification(object, broadcast: broadcast)
    }

    @discardableResult
    func parseNotification(_ userInfo: [AnyHashable : Any], broadcast: Bool = false) -> PushMessage? {
        guard let aps = userInfo["aps"] as? [String: Any], let alert = aps["alert"] as? [String: Any] else {
            return nil
        }

        let title = alert["title"] as? String ?? ""
        let body = alert["body"] as? String ?? ""

        let data = userInfo["customData"] as? [String: Any]
        let timestamp = data?["timestamp"] as? Double ?? 0
        let raceId = data?["raceId"] as? String ?? ""
        let type = data?["type"] as? String ?? "" // ie: "zippyq_next_round"

        let message = PushMessage(
            title: title,
            detail: body,
            timestamp: timestamp,
            raceId: raceId,
            type: type
        )

        // Avoid dupes
        if let existing = messages.first(where: { $0.timestamp == message.timestamp }) {
            return existing
        }

        messages.append(message)
        saveMessages()

        if broadcast {
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .newPushMessageReceived, object: message)
            }
        }

        return message
    }

    // MARK: - Private

    fileprivate var messages: [PushMessage] = []
    fileprivate let syncQueue = DispatchQueue(label: "PushMessagesStore.syncQueue")

    private var fileURL: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return docs.appendingPathComponent("pushMessages.json")
    }

    fileprivate func saveMessages() {
        // Take a thread-safe snapshot
        let snapshot = syncQueue.sync { self.messages }

        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(snapshot)
            try data.write(to: fileURL)
        } catch {
            print("Failed to save messages: \(error)")
        }
    }

    fileprivate func loadMessages() {
        let decoder = JSONDecoder()
        if let data = try? Data(contentsOf: fileURL),
           let loaded = try? decoder.decode([PushMessage].self, from: data) {
            messages = loaded
        }
    }
}
