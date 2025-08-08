//
//  RacePayment.swift
//  RaceSyncAPI
//
//  Created by Ignacio Romero Zurbuchen on 2025-08-07.
//  Copyright © 2025 MultiGP Inc. All rights reserved.
//

import Foundation
import ObjectMapper

public class RacePayment: Mappable, Descriptable {

    public var id: ObjectId = ""
    public var raceId: ObjectId = ""
    public var pilotId: ObjectId = ""
    public var status: String = ""

    public var datePaid: Date?
    public var amountPaid: Float = 0
    public var amountDue: Float = 0
    public var netAmount: Float = 0
    public var paypalFee: Float = 0
    public var platformFee: Float = 0

    // MARK: - Initialization

    fileprivate static let requiredProperties = [ParamKey.id]

    public required convenience init?(map: Map) {
        for requiredProperty in Self.requiredProperties {
            if map.JSON[requiredProperty] == nil {
                return nil
            }
        }

        self.init()
        self.mapping(map: map)
    }

    public func mapping(map: Map) {
        id <- map[ParamKey.id]
        raceId <- map[ParamKey.raceId]
        pilotId <- map[ParamKey.pilotId]
        status <- map[ParamKey.status]

        datePaid <- (map[ParamKey.datePaid], MapperUtil.dateTransform)
        amountPaid <- map[ParamKey.amountPaid]
        amountDue <- map[ParamKey.amountDue]
        netAmount <- map[ParamKey.netAmount]
        paypalFee <- map[ParamKey.paypalFee]
        platformFee <- map[ParamKey.platformFee]
    }
}

