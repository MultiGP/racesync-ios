//
//  RaceData.swift
//  RaceSyncAPI
//
//  Created by Ignacio Romero Zurbuchen on 2022-12-27.
//  Copyright © 2022 MultiGP Inc. All rights reserved.
//

import Foundation
import Alamofire

public struct RaceData: Descriptable {

    public var raceId: String? = nil
    public var name: String? = nil
    public var startDateString: String? = nil
    public var endDateString: String? = nil
    public var chapterId: String
    public var chapterName: String
    public var seasonId: String? = nil
    public var seasonName: String? = nil
    public var courseId: String? = nil
    public var courseName: String? = nil
    public var content: String? = nil

    // Default race values, useful for new race creation
    public var fee: Float32 = 0.0
    public var feeRequired: Bool = false
    public var format: String = ScoringFormat.fastest3Laps.rawValue
    public var funfly: Bool = false
    public var privacy: String = EventType.public.rawValue
    public var qualifying: String = QualifyingType.open.rawValue
    public var raceClass: String = RaceClass.open.rawValue
    public var rounds: Int32 = 5
    public var status: String = RaceStatus.open.rawValue
    public var timing: Bool = true
    public var zippyqDepth: Int32 = 5
    public var zippyqIterator: Int32 = 1
    public var zippyqNoKiosk: Bool = true

    // To be used to broadcast email and/or APNS after saving
    // See php code base that needs to be implemented on the API side
    // https://github.com/MultiGP/multigp-com/blob/09841623ae274fa8f62a3a4df1393cf1cf986b74/public_html/mgp/protected/modules/multigp/models/Race.php#L311
    public var sendNotification: Bool = false

    // These properties don't belong on the Race table
    fileprivate static let nonDiffableProperties = [ParamKey.fee, ParamKey.paymentRequiredToJoin]

    public init(with chapterId: ObjectId, chapterName: String) {
        self.chapterId = chapterId
        self.chapterName = chapterName
    }

    public init(with race: Race) {
        self.raceId = race.id
        self.name = race.name
        self.chapterId = race.chapterId
        self.chapterName = race.chapterName

        if let date = race.startDate {
            self.startDateString = DateUtil.standardDateFormatter.string(from: date)
        }
        if let date = race.endDate {
            self.endDateString = DateUtil.standardDateFormatter.string(from: date)
        }

        self.raceClass = race.raceClass.rawValue
        self.format = race.scoringFormat.rawValue
        self.qualifying = race.disableSlotAutoPopulation.rawValue
        self.privacy = race.type.rawValue
        self.status = race.status.rawValue
        self.fee = race.fee
        self.feeRequired = race.isPaymentRequiredToJoin
        self.funfly = race.scoringDisabled
        self.timing = race.captureTimeEnabled
        self.seasonId = race.seasonId
        self.seasonName = race.seasonName
        self.courseId = race.courseId
        self.courseName = race.courseName
        self.content = race.content
        self.rounds = race.cycleCount
        self.zippyqDepth = race.maxZippyqDepth
        self.zippyqIterator = race.zippyqIterator
        self.zippyqNoKiosk = race.zippyNoKiosk
    }

    public func toParams() -> Params {
        var params: Params = [:]

        // These can't be overriden
        if name != nil { params[ParamKey.name] = name }
        if startDateString != nil { params[ParamKey.startDate] = startDateString }

        params[ParamKey.endDate] = endDateString // TODO: This attribute is being ignored by the API
        params[ParamKey.chapterId] = chapterId
        params[ParamKey.chapterName] = chapterName

        params[ParamKey.raceClass] = raceClass
        params[ParamKey.scoringFormat] = format
        params[ParamKey.disableSlotAutoPopulation] = qualifying
        params[ParamKey.type] = privacy
        params[ParamKey.status] = status
        params[ParamKey.fee] = fee
        params[ParamKey.paymentRequiredToJoin] = feeRequired.intValue
        params[ParamKey.scoringDisabled] = funfly
        params[ParamKey.captureTimeEnabled] = timing

        params[ParamKey.seasonId] = seasonId
        params[ParamKey.courseId] = courseId
        params[ParamKey.content] = content
        params[ParamKey.sendNotification] = sendNotification

        params[ParamKey.cycleCount] = rounds
        params[ParamKey.maxZippyqDepth] = zippyqDepth
        params[ParamKey.zippyqIterator] = zippyqIterator
        params[ParamKey.zippyNoKiosk] = zippyqNoKiosk.intValue

        return params
    }

    public func toDiffParams(_ beforeData: RaceData) -> Params {
        let before = beforeData.toParams()
        let after = toParams()
        var diff = before.diff(with: after)

        // reinsert "nonDiffableProperties" keys from `after`
        Self.nonDiffableProperties.forEach { key in
            if let value = after[key] {
                diff[key] = value
            }
        }

        return diff
    }
}

extension RaceData {

    public var startDate: Date? {
        get {
            guard let str = startDateString else { return nil }
            return DateUtil.standardDateFormatter.date(from: str)
        }
        set { }
    }

    public var endDate: Date? {
        get {
            guard let str = endDateString else { return nil }
            return DateUtil.standardDateFormatter.date(from: str)
        }
        set { }
    }
}
