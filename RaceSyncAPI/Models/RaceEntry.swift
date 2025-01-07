//
//  RaceEntry.swift
//  RaceSyncAPI
//
//  Created by Ignacio Romero Zurbuchen on 2019-12-11.
//  Copyright © 2019 MultiGP Inc. All rights reserved.
//

import Foundation
import ObjectMapper

public class RaceEntry: Mappable, Descriptable {

    public var id: ObjectId = ""
    public var pilotId: ObjectId = ""
    public var pilotUserName: String = ""
    public var pilotName: String = ""
    public var userName: String = ""
    public var displayName: String = ""
    public var firstName: String = ""
    public var lastName: String = ""
    public var score: Int32?
    public var profilePictureUrl: String?

    public var frequency: String?
    public var band: String?
    public var channel: String?

    public var dateAdded: Date?
    public var dateModified: Date?

    // MARK: - Initialization

    fileprivate static let requiredProperties = [ParamKey.id, ParamKey.pilotId]

    public required convenience init?(map: Map) {
        for requiredProperty in Self.requiredProperties {
            if map.JSON[requiredProperty] == nil { return nil }
        }

        self.init()
        self.mapping(map: map)
    }

    public func mapping(map: Map) {
        id <- map[ParamKey.id]
        pilotId <- map[ParamKey.pilotId]
        pilotUserName <- (map[ParamKey.pilotUserName], MapperUtil.stringTransform)
        pilotName <- (map[ParamKey.pilotName], MapperUtil.stringTransform)
        userName <- (map[ParamKey.userName], MapperUtil.stringTransform)
        displayName <- (map[ParamKey.displayName], MapperUtil.stringTransform)
        firstName <- (map[ParamKey.firstName], MapperUtil.stringTransform)
        lastName <- (map[ParamKey.lastName], MapperUtil.stringTransform)
        score <- (map[ParamKey.score], IntegerTransform())
        profilePictureUrl <- map[ParamKey.profilePictureUrl]

        frequency <- map[ParamKey.frequency]
        band <- map[ParamKey.band]
        channel <- map[ParamKey.channel]

        dateAdded <- (map[ParamKey.dateAdded], MapperUtil.dateTransform)
        dateModified <- (map[ParamKey.dateModified], MapperUtil.dateTransform)
    }
}
