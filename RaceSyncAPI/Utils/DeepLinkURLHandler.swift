//
//  DeepLinkURLHandler.swift
//  RaceSync
//
//  Created by Ignacio Romero Zurbuchen on 2025-08-31.
//  Copyright © 2025 MultiGP Inc. All rights reserved.
//

import Foundation

public extension Notification.Name {
    static let joinedRaceViaDeeplink = Notification.Name("com.racecync.joinedRaceViaDeeplink")
}

public class DeepLinkURLHandler: Descriptable {

    // MARK: - Public

    public static let shared = DeepLinkURLHandler()

    public func handle(url: URL) -> Bool {
        guard let link = DeepLink.create(from: url) else { return false }
        return handleDeepLink(link)
    }

    // MARK: - Private

    fileprivate let raceApi = RaceApi()

    fileprivate init() {}
}

extension DeepLinkURLHandler {

    // racesync://race/join?id=29941&pilotId=20676

    func handleDeepLink(_ deepLink: DeepLink) -> Bool {
        if (deepLink.domain == .race || deepLink.domain == .races) {
            if deepLink.action == .join {
                return handleJoiningRace(with: deepLink)
            } else {
                return false
            }
        }
        return false
    }

    func handleJoiningRace(with deepLink: DeepLink) -> Bool {
        guard let myUser = APIServices.shared.myUser else { return false }
        guard let raceId = deepLink.parameters[ParamKey.id], let pilotId = deepLink.parameters[ParamKey.pilotId] else { return false }
        guard pilotId == myUser.id else { return false }

        raceApi.join(race: raceId) { (status, error) in
            // Broadcast regardless if joined successful or not
            // since this may be called, even if the race has already been joined
            // in cases like paying fees after joining a race.
            NotificationCenter.default.post(
                name: .joinedRaceViaDeeplink,
                object: deepLink
            )
        }
        return true
    }
}
