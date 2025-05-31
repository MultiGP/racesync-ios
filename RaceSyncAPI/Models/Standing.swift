//
//  Standing.swift
//  RaceSyncAPI
//
//  Created by Ignacio Romero Zurbuchen on 2025-05-30.
//  Copyright © 2025 MultiGP Inc. All rights reserved.
//

import Foundation
import ObjectMapper

public class Standing: Mappable, Descriptable {

    public var position: String = ""
    public var firstName: String = ""
    public var userName: String = ""
    public var lastName: String = ""
    public var userId: ObjectId = ""
    public var chapterName: String = ""
    public var email: String = ""
    public var country: String = ""

    public var season1: String = ""
    public var season1Score: String = ""

    public var season2: String = ""
    public var season2Score: String = ""

    // MARK: - Initialization

    public required convenience init?(map: Map) {
        self.init()
        self.mapping(map: map)
    }

    public func mapping(map: Map) {
        position <- (map["position"], MapperUtil.stringTransform)
        firstName <- (map[ParamKey.firstName], MapperUtil.stringTransform)
        lastName <- (map[ParamKey.lastName], MapperUtil.stringTransform)
        userName <- (map[ParamKey.userName], MapperUtil.stringTransform)
        userId <- map["userId"]
        chapterName <- (map[ParamKey.chapterName], MapperUtil.stringTransform)
        email <- (map["email"], MapperUtil.stringTransform)
        country <- map[ParamKey.country]

        season1 <- map["season1"]
        season1Score <- map["season1Score"]
        season2 <- map["season2"]
        season2Score <- map["season2Score"]
    }
}
