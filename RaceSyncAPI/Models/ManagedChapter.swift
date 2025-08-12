//
//  ManagedChapter.swift
//  RaceSyncAPI
//
//  Created by Ignacio Romero Zurbuchen on 2020-02-28.
//  Copyright © 2020 MultiGP Inc. All rights reserved.
//

import Foundation
import ObjectMapper

public class ManagedChapter: Mappable, Descriptable {

    public var id: ObjectId = ""
    public var name: String = ""
    public var paymentsEnabled: Bool = false

    // MARK: - Initialization

    fileprivate static let requiredProperties = [ParamKey.id, ParamKey.name]

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
        paymentsEnabled <- (map[ParamKey.paymentsEnabled], BooleanTransform()) // returns as String from API
    }
}
