//
//  SeriesResult.swift
//  RaceSyncAPI
//
//  Created by Ignacio Romero Zurbuchen on 2025-10-02.
//  Copyright © 2025 MultiGP Inc. All rights reserved.
//

import Foundation
import ObjectMapper

public enum SeriesResultType {
    case pilot
    case chapter
}

public class SeriesResult: Mappable, Descriptable {

    public var type: SeriesResultType = .pilot
    public var displayName: String = ""
    public var country: String = ""
    public var score: String = ""
    public var eloScore: String = ""
    public var bestScores: [String]? = nil
    public var time: String? = nil
    public var imageUrl: String? = nil
    public var raceCount: Int = 0
    public var pilotId: String? = nil
    public var chapterId: String? = nil

    // MARK: - Init
    public required init?(map: Map) {
        // No hard "required properties", just return nil if totally empty
        if map.JSON.isEmpty { return nil }
    }

    public init() {}

    // MARK: - Mapping
    public func mapping(map: Map) {
        // Pilot or chapter id
        pilotId   <- map[ParamKey.pilotId]
        chapterId <- map[ParamKey.chapterId]

        raceCount <- map[ParamKey.raceCount]

        // Determine type from what exists
        if pilotId != nil { type = .pilot }
        else if chapterId != nil { type = .chapter }

        // Display name: may come under several keys
        displayName <- map[ParamKey.userName]

        if displayName.isEmpty {
            var userName: String?
            userName <- map[ParamKey.displayName] // 3 con

            if let un = userName, !un.isEmpty {
                displayName = un
            } else {
                displayName <- map[ParamKey.chapterName]
            }
        }

        // Country (only present for pilots usually)
        country <- map[ParamKey.country]

        if let value = map.JSON[ParamKey.score] {
            let str = String(describing: value)
            let decimals = str.components(separatedBy: ".").last?.count ?? 0
            score = decimals > 3 ? String(format: "%.3f", Double(str) ?? 0).replacingOccurrences(of: #"\.?0+$"#, with: "", options: .regularExpression) : str
        }
        
        if let value = map.JSON[ParamKey.fastest3Laps] {
            time = String(describing: value)
        }

        if let value = map.JSON[ParamKey.eloScore] {
            eloScore = String(describing: value)
        }

        bestScores = map.JSON[ParamKey.bestRaces] as? [String]

        // Image / profile picture
        imageUrl <- (map[ParamKey.profilePictureUrl], MapperUtil.stringTransform)
        if imageUrl == nil {
            imageUrl <- (map[ParamKey.mainImageFileName], MapperUtil.stringTransform)
        }
    }
}
