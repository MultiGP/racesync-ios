//
//  RSAPIConstants.swift
//  RaceSyncAPI
//
//  Created by Ignacio Romero Zurbuchen on 2019-11-10.
//  Copyright © 2019 MultiGP Inc. All rights reserved.
//

import Foundation

public typealias ObjectId = String

public let StandardPageSize: Int = 100
public let StandardDateFormat: String = "yyyy-MM-dd"
public let StandardDateTimeFormat: String = "yyyy-MM-dd HH:mm:ss"
public let OldDateTimeFormat: String = "yyyy-MM-dd h:mm a"
public let USLocale: String = "en_US_POSIX"

enum EndPoint {
    static let userLogin = "user/login"
    static let userLogout = "user/logout"
    static let userProfile = "user/profile"
    static let userSearch = "user/search"
    static let userUpdateProfile = "user/updateProfile"

    static let race = "race/"
    static let raceList = "race/list"
    static let raceListForChapter = "race/listForChapter"
    static let raceFindLocal = "race/findLocal"
    static let raceView = "race/view"
    static let raceViewSimple = "race/viewSimple"
    static let raceJoin = "race/join"
    static let raceResign = "race/resign"
    static let raceForceJoin = "race/forceJoinPilot"
    static let raceOpen = "race/open"
    static let raceClose = "race/close"
    static let raceCheckIn = "race/checkIn"
    static let raceCheckOut = "race/checkOut"
    static let raceCreate = "race/create"
    static let raceUpdate = "race/update"
    static let raceDelete = "race/delete"
    static let raceFinalize = "race/finalize"

    static let chapterList = "chapter/list"
    static let chapterFindLocal = "chapter/findLocal"
    static let chapterUsers = "chapter/users"
    static let chapterListManaged = "chapter/listManaged"
    static let chapterSearch = "chapter/search"
    static let chapterJoin = "chapter/join"
    static let chapterResign = "chapter/resign"

    static let seasonList = "season/list"
    static let seasonSearch = "season/search"
    static let seasonCreate = "season/create"
    static let seasonUpdate = "season/update"
    static let seasonDelete = "season/delete"

    static let courseList = "course/list"
    static let courseSearch = "course/search"
    static let courseCreate = "course/create"
    static let courseUpdate = "course/update"
    static let courseDelete = "course/delete"

    static let aircraftList = "aircraft/list"
    static let aircraftCreate = "aircraft/create"
    static let aircraftUpdate = "aircraft/update"
    static let aircraftRetire = "aircraft/retire"
    static let aircraftUploadMainImage = "aircraft/uploadMainImage"
    static let aircraftUploadBackground = "aircraft/uploadBackground"
}

enum ParamKey {
    // API keywords
    static let apiKey = "apiKey"
    static let authType = "authType"

    // ids
    static let id = "id"
    static let sessionId = "sessionId"
    static let pilotId = "pilotId"
    static let chapterId = "chapterId"
    static let aircraftId = "aircraftId"
    static let seasonId = "seasonId"
    static let locationId = "locationId"
    static let ownerId = "ownerId"
    static let courseId = "courseId"
    static let parentCourseId = "parentCourseId"
    static let parentRaceId = "parentRaceId"
    static let homeChapterId = "homeChapterId"
    static let chapterIds = "chapterIds"
    static let raceEntryId = "raceEntryId"

    // Network keywords
    static let url = "url"
    static let httpStatus = "httpStatus"
    static let contentType = "Content-type"
    static let authorization = "Authorization"
    static let data = "data"
    static let errors = "errors"
    static let description = "description"
    static let statusDescription = "statusDescription"
    static let currentPage = "currentPage"
    static let pageSize = "pageSize"
    static let limit = "limit"
    static let password = "password"

    // Names
    static let name = "name"
    static let firstName = "firstName"
    static let lastName = "lastName"
    static let displayName = "displayName"
    static let username = "username"
    static let userName = "userName"
    static let ownerUserName = "ownerUserName"
    static let chapterName = "chapterName"
    static let seasonName = "seasonName"
    static let courseName = "courseName"
    static let pilotUserName = "pilotUserName"
    static let pilotName = "pilotName"
    static let aircraftName = "aircraftName"
    static let urlName = "urlName"

    // Model attributes
    static let joined = "joined"
    static let isJoined = "isJoined"
    static let upcoming = "upcoming"
    static let past = "past"
    static let status = "status"
    static let orderByDistance = "orderByDistance"
    static let nearBy = "nearBy"
    static let isQualifier = "isQualifier"
    static let retired = "retired"
    static let type = "type"
    static let count = "count"
    static let size = "size"
    static let battery = "battery"
    static let propellerSize = "propellerSize"
    static let antenna = "antenna"
    static let managedChapters = "managedChapters"
    static let races = "races"
    static let entries = "entries"
    static let schedule = "schedule"
    static let raceType = "raceType"
    static let startDate = "startDate"
    static let endDate = "endDate"
    static let entryCount = "entryCount"
    static let childRaceCount = "childRaceCount"
    static let raceEntryCount = "raceEntryCount"
    static let participantCount = "participantCount"
    static let officialStatus = "officialStatus"
    static let captureTimeEnabled = "captureTimeEnabled"
    static let finalized = "finalized"
    static let scoringDisabled = "scoringDisabled"
    static let scoringFormat = "scoringFormat"
    static let score = "score"
    static let totalLaps = "totalLaps"
    static let totalTime = "totalTime"
    static let fastest3Laps = "fastest3Laps"
    static let fastest2Laps = "fastest2Laps"
    static let fastestLap = "fastestLap"
    static let cycleCount = "cycleCount"
    static let zippyqIterator = "zippyqIterator"
    static let maxZippyqDepth = "maxZippyqDepth"
    static let disableSlotAutoPopulation = "disableSlotAutoPopulation"
    static let maxBatteriesForQualifying = "maxBatteriesForQualifying"
    static let content = "content"
    static let itineraryContent = "itineraryContent"
    static let typeRestriction = "typeRestriction"
    static let sizeRestriction = "sizeRestriction"
    static let batteryRestriction = "batteryRestriction"
    static let propellerSizeRestriction = "propellerSizeRestriction"
    static let videoTransmitter = "videoTransmitter"
    static let videoTransmitterPower = "videoTransmitterPower"
    static let videoTransmitterChannels = "videoTransmitterChannels"
    static let videoReceiverChannels = "videoReceiverChannels"
    static let frequency = "frequency"
    static let group = "group"
    static let groupSlot = "groupSlot"
    static let band = "band"
    static let channel = "channel"
    static let chapterCount = "chapterCount"
    static let raceCount = "raceCount"
    static let memberCount = "memberCount"
    static let title = "title"
    static let phone = "phone"
    static let tier = "tier"
    static let elements = "elements"
    static let raceClass = "raceClass"
    static let raceClassString = "raceClassString"
    static let sendNotification = "sendNotification"
    static let isPublic = "isPublic"
    static let query = "query"

    // Geo-location
    static let address = "address"
    static let city = "city"
    static let state = "state"
    static let zip = "zip"
    static let country = "country"
    static let latitude = "latitude"
    static let longitude = "longitude"
    static let radius = "radius"

    // url
    static let liveTimeEventUrl = "liveTimeEventUrl"
    static let facebookUrl = "facebookUrl"
    static let googleUrl = "googleUrl"
    static let twitterUrl = "twitterUrl"
    static let youtubeUrl = "youtubeUrl"
    static let instagramUrl = "instagramUrl"
    static let meetupUrl = "meetupUrl"
    static let videoUrl = "videoUrl"
    static let leaderboardUrl = "leaderboardUrl"
    static let validationFeetUrl = "validationFeetUrl"
    static let validationMetersUrl = "validationMetersUrl"

    // Images
    static let profilePictureUrl = "profilePictureUrl"
    static let profileBackgroundUrl = "profileBackgroundUrl"
    static let mainImageFileName = "mainImageFileName"
    static let mainImageUrl = "mainImageUrl"
    static let mainImage = "mainImage"
    static let backgroundFileName = "backgroundFileName"
    static let backgroundUrl = "backgroundUrl"
    static let chapterImageFileName = "chapterImageFileName"

    // System
    static let dateAdded = "dateAdded"
    static let dateModified = "dateModified"
}
