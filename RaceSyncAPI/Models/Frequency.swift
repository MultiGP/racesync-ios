//
//  Frequency.swift
//  RaceSyncAPI
//
//  Created by Ignacio Romero on 2026-07-28.
//  Copyright © 2026 MultiGP Inc. All rights reserved.
//

import Foundation
import ObjectMapper

public class Frequency: Mappable {
    public var slot: Int32 = 0
    public var frequency: String = ""
    public var band: String = ""
    public var channel: String = ""
    public var channelLabel: String = ""

    public required init?(map: Map) {}

    public func mapping(map: Map) {
        slot <- (map[ParamKey.slot], IntegerTransform())
        frequency <- (map[ParamKey.frequency], MapperUtil.anyStringTransform)
        band <- map[ParamKey.band]
        channel <- (map[ParamKey.channel], MapperUtil.anyStringTransform)
        channelLabel <- map[ParamKey.channelLabel]
    }
}
