//
//  ZippyQueue.swift
//  RaceSync
//
//  Created by Ignacio Romero on 2026-07-27.
//  Copyright © 2026 MultiGP Inc. All rights reserved.
//

import Foundation
import ObjectMapper

public class ZippyqResponse: Mappable {
    public var queues: [ZippyQueue] = []
    public var pilotStats: [ObjectId: ZippyqPilotStats] = [:]

    public required init?(map: Map) {}

    public func mapping(map: Map) {
        queues <- map[ParamKey.data]
        pilotStats <- map["pilotStats"]
    }
}

public class ZippyQueue: Mappable {
    public var cycle: Int32 = 0
    public var heat: Int32 = 0
    public var status: String = ""
    public var entries: [ZippyqEntry] = []

    public required init?(map: Map) {}

    public func mapping(map: Map) {
        cycle <- (map[ParamKey.cycle], IntegerTransform())
        heat <- (map[ParamKey.heat], IntegerTransform())
        status <- map[ParamKey.status]
        entries <- map[ParamKey.entries]
    }
}

public class ZippyqEntry: Mappable {
    
    public var id: ObjectId = ""
    public var raceEntryId: ObjectId = ""
    public var cycle: Int32 = 0
    public var heat: Int32 = 0
    public var slot: Int32 = 0
    public var score: Double?
    public var frequency: String?
    public var band: String?
    public var channel: String?
    public var user: User?

    public required init?(map: Map) {}

    public func mapping(map: Map) {
        id <- (map[ParamKey.id], MapperUtil.anyStringTransform)
        raceEntryId <- (map[ParamKey.raceEntryId], MapperUtil.anyStringTransform)
        cycle <- (map[ParamKey.cycle], IntegerTransform())
        heat <- (map[ParamKey.heat], IntegerTransform())
        slot <- (map[ParamKey.slot], IntegerTransform())
        score <- (map[ParamKey.score], MapperUtil.doubleTransform)
        frequency <- map[ParamKey.frequency]
        band <- map[ParamKey.band]
        channel <- map[ParamKey.channel]
        user <- map["user"]
    }
}

public class ZippyqPilotStats: Mappable {
    public var usedCount: Int32 = 0
    public var queuedCount: Int32 = 0
    public var nextRounds: [String] = []

    public required init?(map: Map) {}

    public func mapping(map: Map) {
        usedCount <- (map["usedCount"], IntegerTransform())
        queuedCount <- (map["queuedCount"], IntegerTransform())
        nextRounds <- map["nextRounds"]
    }
}

public class ZippyqRevision: Mappable {
    public var value: String = ""

    public required init?(map: Map) {}

    public func mapping(map: Map) {
        value <- map["revision"]
    }
}
