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
    public var score: Double = 0
    public var eloScore: Int32 = 0
    public var bestPilots: [String]? = nil
    public var bestResults: [Double]? = nil
    public var time: String? = nil
    public var imageUrl: String? = nil
    public var raceCount: Int = 0
    public var pilotId: String? = nil
    public var chapterId: String? = nil

    public var mainImageUrl: String? //profilePictureUrl
    public var profileImageUrl: String? //mainImageFileName

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

        if let value = map.JSON[ParamKey.score], let number = Double(String(describing: value)) {
            score = number
        }

        if let value = map.JSON[ParamKey.fastest3Laps] {
            let str = String(describing: value)
            if let number = Double(str), number < 600 { // no drone flies more than 10 mins
                time = String(describing: value)
            }
        }

        eloScore <- (map[ParamKey.eloScore], IntegerTransform())
        bestPilots = map.JSON[ParamKey.bestPilots] as? [String]
        bestResults <- (map[ParamKey.bestResults], MapperUtil.doubleArrayTransform)
        
        mainImageUrl <- (map[ParamKey.mainImageFileName], MapperUtil.stringTransform)
        profileImageUrl <- (map[ParamKey.profilePictureUrl], MapperUtil.stringTransform)
    }
}
