//
//  ProfileViewModel.swift
//  RaceSync
//
//  Created by Ignacio Romero Zurbuchen on 2019-11-20.
//  Copyright © 2019 MultiGP Inc. All rights reserved.
//

import UIKit
import RaceSyncAPI

class ProfileViewModel: Descriptable {

    let type: ProfileViewModelType
    let id: ObjectId

    let title: String
    let displayName: String
    let locationName: String
    let backgroundUrl: String?
    let pictureUrl: String?

    let topBadgeLabel: String?
    let topBadgeImage: UIImage?

    let leftBadgeLabel: String
    let leftBadgeImage: UIImage?
    let leftSegmentLabel: String

    var rightBadgeLabel: String
    let rightBadgeImage: UIImage?
    let rightSegmentLabel: String

    let color: UIColor?

    init(with user: User) {
        self.type = .user
        self.id = user.id

        self.title = ViewModelHelper.titleLabel(for: user.userName, country: user.country)
        self.displayName = user.displayName.uppercased()
        self.locationName = ViewModelHelper.locationLabel(for: user.city, state: user.state)
        self.backgroundUrl = user.profileBackgroundUrl
        self.pictureUrl = user.profilePictureUrl

        self.topBadgeLabel = nil
        self.topBadgeImage = nil

        self.leftBadgeImage = ButtonImg.race_small
        self.leftSegmentLabel = "Races"
        self.leftBadgeLabel = "\(user.raceCount) \(user.raceCount == 1 ? "Race" : "Races")"

        self.rightBadgeImage = ButtonImg.chapter_small
        self.rightSegmentLabel = "Chapters"
        self.rightBadgeLabel = "\(user.chapterCount) \(user.chapterCount == 1 ? "Chapter" : "Chapters")"

        self.color = nil
    }

    init(with chapter: Chapter) {
        self.type = .chapter
        self.id = chapter.id

        self.title = chapter.name
        self.displayName = chapter.description.isEmpty ? chapter.name : chapter.description
        self.locationName = ViewModelHelper.locationLabel(for: chapter.city, state: chapter.state)
        self.pictureUrl = chapter.mainImageUrl
        self.backgroundUrl = chapter.backgroundUrl

        if let stringTier = chapter.tier, let tier = Int(stringTier) {
            let chapterTier = ChapterTier(rawValue: tier)

            if chapter.isApproved {
                self.topBadgeLabel = chapterTier?.title
                self.topBadgeImage = ButtonImg.badge_small
            } else {
                self.topBadgeLabel = "Disabled"
                self.topBadgeImage = SystemImg.badge_cross_small
            }

        } else {
            self.topBadgeLabel = nil
            self.topBadgeImage = nil
        }

        self.leftBadgeImage = ButtonImg.race_small
        self.leftSegmentLabel = "Races"
        self.leftBadgeLabel = "\(chapter.raceCount) \(chapter.raceCount == 1 ? "Race" : "Races")"

        self.rightBadgeImage = ButtonImg.member_small
        self.rightSegmentLabel = "Members"
        self.rightBadgeLabel = "\(chapter.memberCount) \(chapter.memberCount == 1 ? "Member" : "Members")"

        self.color = nil
    }

    init(with series: Series) {
        self.type = .series
        self.id = series.id

        self.title = series.name
        self.pictureUrl = nil
        self.backgroundUrl = series.mainImageUrl

        self.displayName = series.name.uppercased()
        self.locationName = series.scoreTypeString // a bit hacky but whatever

        self.leftBadgeImage = ButtonImg.race_small
        self.leftBadgeLabel = "\(series.raceApprovedCount) Approved \(series.raceApprovedCount == 1 ? "Race" : "Races")"

        self.rightBadgeImage = ButtonImg.member_small
        self.rightBadgeLabel = "\(series.pilotCount) \(series.pilotCount == 1 ? "Pilot" : "Pilots")"

        self.rightSegmentLabel = ""
        self.leftSegmentLabel = ""
        self.topBadgeLabel = nil
        self.topBadgeImage = nil

        self.color = UIColor(hex: series.color)
    }
}

public enum ProfileViewModelType: String {
    case user = "user"
    case chapter = "chapter"
    case series = "series"

    var placeholder: UIImage? {
        switch self {
        case .user:     return PlaceholderImg.profileAvatar
        case .chapter:  return PlaceholderImg.profileAvatar
        default:        return nil
        }
    }
}
