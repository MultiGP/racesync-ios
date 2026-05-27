//
//  AppWebConstants.swift
//  RaceSync
//
//  Created by Ignacio Romero Zurbuchen on 2023-01-18.
//  Copyright © 2023 MultiGP Inc. All rights reserved.
//

import Foundation
import RaceSyncAPI
import UIKit

public class AppWebConstants {
    static let homepage = "https://www.multigp.com/"
    static let passwordReset = "https://www.multigp.com/initiatepasswordreset"
    static let accountRegistration = "https://www.multigp.com/register"
    static let termsOfUse = "https://www.multigp.com/terms-of-use/"
    static let shop = "https://shop.multigp.com/"
    static let tracks = "https://www.multigp.com/multigp-tracks/"
    static let obstaclesDoc = "https://www.multigp.com/multigp-drone-race-course-obstacles/"
    static let seasonRulesDoc = "https://www.multigp.com/organizer-resources/rule-book/"
    static let io26RaceFormats = "https://www.multigp.com/io26/race-formats/"

    static let livefpv = "https://livefpv.com/"
    static let fpvscores = "https://fpvscores.com/"

    static let testflight = "https://testflight.apple.com/join/BRXIQJLb"
    static let github = "https://github.com/MultiGP/racesync-ios"
}

enum AppWeb: Int {
    case multigp, livefpv, fpvscores

    init?(url: String) {
        guard let aURL = URL(string: url) else { return nil }

        let mappings: [AppWeb: String] = [
            .multigp: AppWebConstants.homepage,
            .livefpv: AppWebConstants.livefpv,
            .fpvscores: AppWebConstants.fpvscores
        ]

        for (appWebCase, caseURLString) in mappings {
            if let caseURL = URL(string: caseURLString),
               caseURL.rootDomain == aURL.rootDomain {
                self = appWebCase
                return
            }
        }

        return nil
    }

    var image: UIImage? {
        if self == .livefpv {
            return LogoImg.livefpv
        } else if self == .fpvscores {
            return LogoImg.fpvscores
        } else {
            return nil
        }
    }
}
