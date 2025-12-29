//
//  StringConstants.swift
//  RaceSync
//
//  Created by Ignacio Romero Zurbuchen on 2020-01-21.
//  Copyright © 2020 MultiGP Inc. All rights reserved.
//

import Foundation
import RaceSyncAPI

public class StringConstants {
    public static let applicationID = "1491110680"
    public static let appstoreUrl = "https://apps.apple.com/app/\(applicationID)"
    public static let appstoreReviewUrl = "\(RateMe.appstoreUrl(with: applicationID))"

    public static let copyright = "Copyright © 2015 - \(Date().thisYear()) MultiGP, Inc."
    public static let developedBy = "Developed by Ignacio 'Zenith' Romero"
    public static let supportEmail = "mobile@multigp.com"
}
