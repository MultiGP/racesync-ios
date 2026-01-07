//
//  UserViewModel.swift
//  RaceSync
//
//  Created by Ignacio Romero Zurbuchen on 2019-12-10.
//  Copyright © 2019 MultiGP Inc. All rights reserved.
//

import RaceSyncAPI

class UserViewModel: Descriptable {

    let userId: ObjectId

    let user: User?
    let raceEntry: RaceEntry?
    let resultEntry: ResultEntry?

    let username: String
    let displayName: String
    let fullName: String
    let fullPilotName: String
    let pictureUrl: String?
    let channelLabel: String?

    var score: Int32? = nil
    var isJoined: Bool = false

    init(with user: User) {
        self.userId = user.id
        self.user = user
        self.raceEntry = nil
        self.resultEntry = nil

        self.username = user.userName
        self.displayName = ViewModelHelper.titleLabel(for: user.userName, country: user.country)
        self.fullName = Self.fullName(user.firstName, lastName: user.lastName)
        self.fullPilotName = Self.fullName(user.firstName, userName: user.userName, lastName: user.lastName)
        self.pictureUrl = user.profilePictureUrl
        self.channelLabel = nil
    }

    static func viewModels(with objects:[User]) -> [UserViewModel] {
        var viewModels = [UserViewModel]()
        for object in objects {
            viewModels.append(UserViewModel(with: object))
        }
        return viewModels
    }

    init(with entry: RaceEntry) {
        self.userId = entry.pilotId
        self.user = nil
        self.raceEntry = entry
        self.resultEntry = nil

        self.username = entry.userName
        self.displayName = entry.displayName
        self.fullName = Self.fullName(entry.firstName, lastName: entry.lastName)
        self.fullPilotName = Self.fullName(entry.firstName, userName: entry.userName, lastName: entry.lastName)
        self.pictureUrl = entry.profilePictureUrl
        self.isJoined = true
        self.score = entry.score

        if let band = entry.band, let channel = entry.channel {
            channelLabel = "\(band)\(channel)"
        } else {
            channelLabel = nil
        }
    }

    init(with entry: ResultEntry) {
        self.userId = entry.pilotId
        self.user = nil
        self.raceEntry = nil
        self.resultEntry = entry

        self.username = entry.userName
        self.displayName = entry.displayName
        self.fullName = Self.fullName(entry.firstName, lastName: entry.lastName)
        self.fullPilotName = Self.fullName(entry.firstName, userName: entry.userName, lastName: entry.lastName)
        self.pictureUrl = entry.profilePictureUrl
        self.isJoined = true

        if let score = entry.score {
            self.score = Int32(score)
        }

        if let band = entry.band, let channel = entry.channel {
            channelLabel = "\(band)\(channel)"
        } else {
            channelLabel = nil
        }
    }

    static func viewModelsFromEntries(_ entries: [RaceEntry]) -> [UserViewModel] {
        var viewModels = [UserViewModel]()
        for object in entries {
            viewModels.append(UserViewModel(with: object))
        }
        return viewModels
    }

    static func viewModelsFromResults(_ results: [ResultEntry]) -> [UserViewModel] {
        var viewModels = [UserViewModel]()
        for object in results {
            viewModels.append(UserViewModel(with: object))
        }
        return viewModels
    }

    static func viewModels(_ viewModels: [UserViewModel], withoutResults entries: [RaceEntry]) -> [UserViewModel] {
        var seenIds = Set(viewModels.map { $0.userId })

        let uniqueRaceEntries = entries.filter { entry in
            guard !seenIds.contains(entry.pilotId) else { return false }
            seenIds.insert(entry.pilotId)
            return true
        }.sorted { ($0.dateAdded ?? Date.distantPast) < ($1.dateAdded ?? Date.distantPast) }

        return viewModelsFromEntries(uniqueRaceEntries)
    }
}

extension UserViewModel {

    static func fullName(_ firstName: String, userName: String? = nil, lastName: String) -> String {
        if let userName = userName, !userName.isEmpty {
            return "\(firstName.capitalized) '\(userName)' \(lastName.capitalized)"
        } else {
            return "\(firstName.capitalized) \(lastName.capitalized)"
        }
    }
}

extension UserViewModel: Comparable {
    static func == (lhs: UserViewModel, rhs: UserViewModel) -> Bool {
        return lhs.username == rhs.username
    }

    static func < (lhs: UserViewModel, rhs: UserViewModel) -> Bool {
        return lhs.username < rhs.username
    }
}
