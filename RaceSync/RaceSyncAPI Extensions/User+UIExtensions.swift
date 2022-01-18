//
//  User+UIExtensions.swift
//  RaceSync
//
//  Created by Ignacio Romero Zurbuchen on 2020-12-29.
//  Copyright © 2020 MultiGP Inc. All rights reserved.
//

import UIKit
import RaceSyncAPI

extension User {

    var miniProfilePictureUrl: String? {
        guard let url = APIServices.shared.myUser?.profilePictureUrl else { return nil }
        return ImageUtil.getImageUrl(for: url)
    }
}
