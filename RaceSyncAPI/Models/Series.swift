//
//  Series.swift
//  RaceSyncAPI
//
//  Created by Ignacio Romero Zurbuchen on 2025-09-21.
//  Copyright © 2025 MultiGP Inc. All rights reserved.
//

import Foundation
import ObjectMapper

public class Series: Mappable, Descriptable {

    public var id: ObjectId = ""
    public var name: String = ""
    public var description: String = ""
    public var startDate: Date?
    public var endDate: Date?
    public var type: SeriesType = .overall
    public var typeString: String = ""
    public var isApproved: Bool = false
    public var ownerId: ObjectId = ""
    public var mainImageUrl: String?

    public var pilotCount: Int32 = 0
    public var chapterCount: Int32 = 0
    public var chapterApprovedCount: Int32 = 0
    public var raceCount: Int32 = 0
    public var raceApprovedCount: Int32 = 0

    public var races: [Race]? = nil
    public var chapters: [Chapter]? = nil
    public var pilotResults: [SeriesResult]? = nil
    public var chapterResults: [SeriesResult]? = nil

    // MARK: - Initialization

    fileprivate static let requiredProperties = [ParamKey.id, ParamKey.name, ParamKey.ownerId]

    public required convenience init?(map: Map) {
        for requiredProperty in Self.requiredProperties {
            if map.JSON[requiredProperty] == nil { return nil }
        }

        self.init()
        self.mapping(map: map)
    }

    public func mapping(map: Map) {
        id <- map[ParamKey.id]
        name <- (map[ParamKey.name], MapperUtil.stringTransform)
        description <- map[ParamKey.description]
        startDate <- (map[ParamKey.startDate], MapperUtil.dateTransform)
        endDate <- (map[ParamKey.endDate], MapperUtil.dateTransform)
        type <- (map[ParamKey.type], EnumTransform<SeriesType>())
        typeString <- map[ParamKey.typeString]
        isApproved <- map[ParamKey.approved]
        ownerId <- map[ParamKey.ownerId]
        mainImageUrl <- map[ParamKey.mainImageUrl]

        pilotCount <- map[ParamKey.pilotCount]
        chapterCount <- map[ParamKey.chapterCount]
        chapterApprovedCount <- map[ParamKey.chapterApprovedCount]
        raceCount <- map[ParamKey.raceCount]
        raceApprovedCount <- map[ParamKey.raceApprovedCount]

        races <- map[ParamKey.races]
        chapters <- map[ParamKey.chapters]

        pilotResults <- map["pilot-results"]
        chapterResults <- map["chapter-results"]
    }
}
