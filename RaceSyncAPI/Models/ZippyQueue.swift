//
//  ZippyQueue.swift
//  RaceSync
//
//  Created by Ignacio Romero on 2026-07-27.
//  Copyright © 2026 MultiGP Inc. All rights reserved.
//

import Foundation
import ObjectMapper

public typealias ZippyqPilotCollection = [ObjectId: ZippyqPilotStats]

public class ZippyqResponse: Mappable, Descriptable {
    public var queues: [ZippyQueue] = []
    public var pilotStats: ZippyqPilotCollection = [:]
    public var frequencies: [Frequency] = []

    public required init?(map: Map) {}

    public func mapping(map: Map) {
        queues <- map[ParamKey.data]
        pilotStats <- map["pilotStats"]
        frequencies <- map[ParamKey.frequencies]
    }
}

public class ZippyQueue: Mappable, Descriptable {
    public var cycle: Int32 = 0
    public var heat: Int32 = 0
    public var status: ZippyqStatus = .previous
    public var projected: Bool = false
    public var startTime: Date?
    public var entries: [ZippyqEntry] = []

    public required init?(map: Map) {}

    public func mapping(map: Map) {
        cycle <- (map[ParamKey.cycle], IntegerTransform())
        heat <- (map[ParamKey.heat], IntegerTransform())
        status <- (map[ParamKey.status], EnumTransform<ZippyqStatus>())
        projected <- map[ParamKey.projected]
        startTime <- (map[ParamKey.startTime], MapperUtil.utcDateTransform)
        entries <- map[ParamKey.entries]
    }
}

public class ZippyqEntry: Mappable, Descriptable {
    
    public var id: ObjectId = ""
    public var raceEntryId: ObjectId = ""
    public var cycle: Int32 = 0
    public var heat: Int32 = 0
    public var slot: Int32 = 0
    public var score: String?
    public var totalLaps: String?
    public var totalTime: String?
    public var fastest3Laps: String?
    public var fastest2Laps: String?
    public var fastestLap: String?
    public var frequency: Frequency?
    public var user: User?

    public required init?(map: Map) {}

    public func mapping(map: Map) {
        id <- (map[ParamKey.id], MapperUtil.anyStringTransform)
        raceEntryId <- (map[ParamKey.raceEntryId], MapperUtil.anyStringTransform)
        cycle <- (map[ParamKey.cycle], IntegerTransform())
        heat <- (map[ParamKey.heat], IntegerTransform())
        slot <- (map[ParamKey.slot], IntegerTransform())
        score <- map[ParamKey.score]
        totalLaps <- map[ParamKey.totalLaps]
        totalTime <- map[ParamKey.totalTime]
        fastest3Laps <- map[ParamKey.fastest3Laps]
        fastest2Laps <- map[ParamKey.fastest2Laps]
        fastestLap <- map[ParamKey.fastestLap]
        frequency <- map[ParamKey.frequency]
        user <- map["user"]
    }
}

public class ZippyqPilotStats: Mappable, Descriptable {
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

public class ZippyqRevision: Mappable, Descriptable {
    public var value: String = ""

    public required init?(map: Map) {}

    public func mapping(map: Map) {
        value <- map["revision"]
    }
}
