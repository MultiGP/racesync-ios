//
//  DeepLinkURLHandler.swift
//  RaceSync
//
//  Created by Ignacio Romero Zurbuchen on 2025-08-31.
//  Copyright © 2025 MultiGP Inc. All rights reserved.
//

import Foundation
import RaceSyncAPI

class DeepLinkURLHandler {

    static let shared = DeepLinkURLHandler()

    // MARK: - Private Variables

    fileprivate let raceApi = RaceApi()

    fileprivate static var scheme: String? {
            if let urlTypes = Bundle.main.object(forInfoDictionaryKey: "CFBundleURLTypes") as? [[String: Any]],
               let urlSchemes = urlTypes.first?["CFBundleURLSchemes"] as? [String] {
                return urlSchemes.first
            }
            return nil
        }

    fileprivate init() {}

    // MARK: - Actions

    func handle(url: URL) -> Bool {
        guard url.scheme == Self.scheme else { return false }

        guard let host = url.host, let domain = DeepLink.Domain(rawValue: host) else {
            return false
        }

        let action = url.pathComponents.dropFirst().first.flatMap {
            DeepLink.Action(rawValue: $0)
        } ?? .unknown

        // Extract query items into dictionary
        var params: [String: String] = [:]
        if let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems {
            queryItems.forEach { item in
                params[item.name] = item.value ?? ""
            }
        }

        let deepLink = DeepLink(domain: domain, action: action, parameters: params)

        return handleDeepLink(deepLink)
    }
}

fileprivate extension DeepLinkURLHandler {

    // sync://race/join?id=29941&pilotId=20676

    func handleDeepLink(_ deepLink: DeepLink) -> Bool {
        if deepLink.domain == .race, deepLink.action == .join {
            return handleJoiningRace(with: deepLink)
        }
        return false
    }

    func handleJoiningRace(with deepLink: DeepLink) -> Bool {
        guard let myUser = APIServices.shared.myUser else { return false }
        guard let raceId = deepLink.parameters[ParamKey.id], let pilotId = deepLink.parameters[ParamKey.pilotId] else { return false }

        if pilotId == myUser.id {
            AppControl.shared.join(race: raceId, raceApi: raceApi) { _ in
                NotificationCenter.default.post(
                    name: .joinedRaceViaDeeplink,
                    object: deepLink
                )
            }
            return true
        }
        return false
    }
}

extension Notification.Name {
    static let joinedRaceViaDeeplink = Notification.Name("com.racecync.joinedRaceViaDeeplink")
}
