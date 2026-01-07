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
    public var imageUrl: String?

    public var pilotId: String?
    public var chapterId: String?

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

        // Determine type from what exists
        if pilotId != nil { type = .pilot }
        else if chapterId != nil { type = .chapter }

        // Display name: may come under several keys
        displayName <- (map[ParamKey.displayName], MapperUtil.stringTransform)
        if displayName.isEmpty {
            // fallback options
            var firstName: String?
            var lastName: String?
            var userName: String?

            firstName <- (map[ParamKey.firstName], MapperUtil.stringTransform)
            lastName  <- (map[ParamKey.lastName],  MapperUtil.stringTransform)
            userName  <- (map[ParamKey.userName],  MapperUtil.stringTransform)

            if let fn = firstName, let ln = lastName, !fn.isEmpty || !ln.isEmpty {
                displayName = [fn, ln].compactMap { $0 }.joined(separator: " ")
            } else if let un = userName, !un.isEmpty {
                displayName = un
            } else {
                // fallback for chapter
                displayName <- (map[ParamKey.chapterName], MapperUtil.stringTransform)
            }
        }

        // Country (only present for pilots usually)
        country <- (map[ParamKey.country], MapperUtil.stringTransform)

        // Score (numeric sometimes, string sometimes)
        if let numericScore = map.JSON[ParamKey.score] {
            score = String(describing: numericScore)
        } else if let timingScore = map.JSON[ParamKey.fastest3Laps] {
            score = String(describing: timingScore)
        }

        eloScore <- (map[ParamKey.eloScore], MapperUtil.stringTransform)

        // Image / profile picture
        imageUrl <- (map[ParamKey.profilePictureUrl], MapperUtil.stringTransform)
        if imageUrl == nil {
            imageUrl <- (map[ParamKey.mainImageFileName], MapperUtil.stringTransform)
        }
    }
}
