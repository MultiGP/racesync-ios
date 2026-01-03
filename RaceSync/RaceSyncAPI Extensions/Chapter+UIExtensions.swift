//
//  Chapter+UIExtensions.swift
//  RaceSync
//
//  Created by Ignacio Romero Zurbuchen on 2020-09-18.
//  Copyright © 2020 MultiGP Inc. All rights reserved.
//

import UIKit
import RaceSyncAPI

extension Chapter {

    var miniProfilePictureUrl: String? {
        guard let url = APIServices.shared.myChapter?.mainImageUrl else { return nil }
        return ImageUtil.getImageUrl(for: url)
    }

    func socialActivities() -> [SocialActivity] {

        let items = [websiteUrl, facebookUrl, twitterUrl, youtubeUrl, instagramUrl, meetupUrl]
        var activities = [SocialActivity]()

        for item in items {
            if let url = item, let _URL = URL(string: url) {
                let activity = SocialActivity(with: _URL)

                // Make sure there are no duplicated platforms
                guard activities.filter ({ return $0.platform == activity.platform }).first == nil else { continue }

                activities += [activity]
            }
        }

        return activities
    }
}
