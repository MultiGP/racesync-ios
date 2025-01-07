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
    let pictureUrl: String?
    let channelLabel: String?

    init(with user: User) {
        self.userId = user.id
        self.user = user
        self.raceEntry = nil
        self.resultEntry = nil

        self.username = user.userName
        self.displayName = ViewModelHelper.titleLabel(for: user.userName, country: user.country)
        self.fullName = "\(user.firstName.capitalized) \(user.lastName.capitalized)"
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
        self.fullName = "\(entry.firstName.capitalized) \(entry.lastName.capitalized)"
        self.pictureUrl = entry.profilePictureUrl

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
        self.fullName = "\(entry.firstName.capitalized) \(entry.lastName.capitalized)"
        self.pictureUrl = entry.profilePictureUrl

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

extension UserViewModel: Comparable {
    static func == (lhs: UserViewModel, rhs: UserViewModel) -> Bool {
        return lhs.username == rhs.username
    }

    static func < (lhs: UserViewModel, rhs: UserViewModel) -> Bool {
        return lhs.username < rhs.username
    }
}
