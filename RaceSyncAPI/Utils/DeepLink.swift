//
//  DeepLink.swift
//  RaceSync
//
//  Created by Ignacio Romero Zurbuchen on 2025-08-31.
//  Copyright © 2025 MultiGP Inc. All rights reserved.
//

import Foundation

public struct DeepLink {
    public let domain: Domain
    public let action: Action
    public let parameters: [String: String]

    public enum Domain: String {
        case race
        case races
        case pilot
        case pilots
        case chapters
    }

    public enum Action: String {
        case join
        case view
    }
}

public extension DeepLink {

    static let scheme: String = "racesync"

    // there are 2 types of race domains, so a convience getter is needed
    var isRace: Bool {
        return [.race, .races].contains(domain)
    }

    var absoluteString: String {
        var urlString = "\(DeepLink.scheme)://\(domain.rawValue)/\(action.rawValue)"

        // Add query string if parameters exist
        if !parameters.isEmpty {
            // Map parameters to key=value pairs and join with &
            let query = parameters.map { key, value -> String in
                let encodedKey = key.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? key
                let encodedValue = value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? value
                return "\(encodedKey)=\(encodedValue)"
            }.joined(separator: "&")

            urlString.append("?\(query)")
        }
        return urlString
    }

    static func create(from url: URL) -> DeepLink? {

        if url.scheme == DeepLink.scheme {
            return link(fromAppUrl: url)
        } else if let host = url.host, let mgpHost = MGPWeb.baseURL().host, host == mgpHost {
            return link(fromWebUrl: url)
        } else {
            return nil
        }
    }

    fileprivate static func link(fromAppUrl url: URL) -> DeepLink? {
        guard url.scheme == DeepLink.scheme else { return nil }

        guard let host = url.host, let domain = DeepLink.Domain(rawValue: host) else {
            return nil
        }

        guard
            let component = url.pathComponents.dropFirst().first,
            let action = DeepLink.Action(rawValue: component)
        else {
            return nil
        }

        let params = queryParams(from: url)

        return DeepLink(domain: domain, action: action, parameters: params)
    }

    fileprivate static func link(fromWebUrl url: URL) -> DeepLink? {
        guard let baseHost = MGPWeb.baseURL().host else { return nil }

        // Only handle multigp.com domain (dev or prod)
        guard let host = url.host, host == baseHost else {
            return nil
        }

        // Break down path components (drop leading slash)
        let pathComponents = url.pathComponents.filter { $0 != "/" }
        guard pathComponents.count >= 2 else {
            return nil
        }

        // Map first path component to DeepLink.Domain
        let domainComponent = pathComponents[0].lowercased()
        let actionComponent = pathComponents[1].lowercased()
        guard let domain = DeepLink.Domain(rawValue: domainComponent) else { return nil }
        guard let action = DeepLink.Action(rawValue: actionComponent) else { return nil }

        let params = queryParams(from: url)

        return DeepLink(domain: domain, action: action, parameters: params)
    }

    fileprivate static func queryParams(from url: URL) -> [String: String] {
        var params: [String: String] = [:]
        if let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems {
            queryItems.forEach { item in
                let value = item.value?.trimmingCharacters(in: CharacterSet(charactersIn: "/")) ?? ""
                if item.name == ParamKey.race {
                    params[ParamKey.id] = value
                } else {
                    params[item.name] = value
                }
            }
        }
        return params
    }
}
