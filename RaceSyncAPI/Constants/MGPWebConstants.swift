//
//  MGPWebPath.swift
//  RaceSync
//
//  Created by Ignacio Romero Zurbuchen on 2019-11-11.
//  Copyright © 2019 MultiGP Inc. All rights reserved.
//

import Foundation

public enum MGPWebPath: String {
    case apiBase = "/mgp/multigpwebservice/"
    case raceView = "/races/view/?race"
    case chapterView = "/chapters/view/?chapter"
    case userView = "/pilots/view/?pilot"
    case seriesView = "/multigp-series/?seriesId"
    case zippyqView = "/MultiGP/views/zippyq.php?raceId"
    case chapterLeaderboard = "https://www.multigp.com/chapters/leaderboard/view/?chapter"

    case viewZipperSeasonResults = "/MultiGP/views/viewZipperSeasonResults.php" //?season1=2025Summer&season2=2025Spring&exportcsv=true
    case processPayment = "/MultiGP/views/processPayment.php" //?raceId=zzzzzz&pilotId=yyyy&user-agent=ios
}

public class MGPWeb {

    public static func baseURL() -> URL {
        let host = APIServices.shared.settings.isDev ? "dev.multigp.com" : "www.multigp.com"
        return URL(string: "https://\(host)/")!
    }

    public static func getURL(for path: MGPWebPath? = nil, value: String? = nil) -> URL {
        // Always recompute base URL dynamically
        let base = baseURL()

        // If no path, return base directly
        guard let path = path else { return base }

        // Remove only the first leading slash (not all slashes)
        let raw = path.rawValue
        let trimmedPath = raw.hasPrefix("/") ? String(raw.dropFirst()) : raw

        guard let url = URL(string: trimmedPath, relativeTo: base)?.absoluteURL else {
            return base
        }

        if let value = value, !value.isEmpty {
            let safeValue = value
                .replacingOccurrences(of: " ", with: "-")
                .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? value

            let combined = "\(url.absoluteString)=\(safeValue)"
            return URL(string: combined) ?? url
        }

        return url
    }

    /// Convenience string version
    public static func getUrl(for path: MGPWebPath, value: String? = nil) -> String {
        return getURL(for: path, value: value).absoluteString
    }
}

