//
//  SocialActivity.swift
//  RaceSync
//
//  Created by Ignacio Romero Zurbuchen on 2020-09-15.
//  Copyright © 2020 MultiGP Inc. All rights reserved.
//

import UIKit

enum SocialPlatform: String {
    case livefpv = "livefpv.com"
    case facebook = "facebook.com"
    case twitter = "twitter.com"
    case youtube = "youtube.com"
    case instagram = "instagram.com"
    case meetup = "meetup.com"
    case website = ""

    init(from url: URL) {
        let host = url.SLD
        if host == SocialPlatform.livefpv.rawValue {
            self = .livefpv
        } else if host == SocialPlatform.facebook.rawValue {
            self = .facebook
        } else if host == SocialPlatform.twitter.rawValue {
            self = .twitter
        } else if host == SocialPlatform.youtube.rawValue {
            self = .youtube
        } else if host == SocialPlatform.instagram.rawValue {
            self = .instagram
        } else if host == SocialPlatform.meetup.rawValue {
            self = .meetup
        } else {
            self = .website
        }
    }

    var title: String {
        switch self {
            case .livefpv:      return "View on livefpv.com"
            case .facebook:     return "View on facebook"
            case .twitter:      return "View on X"
            case .youtube:      return "View on youtube"
            case .instagram:    return "View on instagram"
            case .meetup:       return "View on meetup.com"
            case .website:      return "Visit homepage"
        }
    }
}

class SocialActivity: UIActivity {

    let url: URL
    let platform: SocialPlatform

    init(with url: URL) {
        self.url = url
        self.platform = SocialPlatform(from: url)
        super.init()
    }

    override var activityTitle: String? {
        return platform.title
    }

    override var activityImage: UIImage? {
        switch platform {
            case .livefpv:      return  UIImage(named: "icn_activity_livefpv")
            case .facebook:     return  UIImage(named: "icn_activity_facebook")
            case .twitter:      return  UIImage(named: "icn_activity_twitter")
            case .youtube:      return  UIImage(named: "icn_activity_youtube")
            case .instagram:    return  UIImage(named: "icn_activity_instagram")
            case .meetup:       return  UIImage(named: "icn_activity_meetup")
            case .website:      return  UIImage(named: "icn_activity_safari")
        }
    }

    override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        return UIApplication.shared.canOpenURL(url)
    }

    override func prepare(withActivityItems activityItems: [Any]) {
        //
    }

    override func perform() {
        UIApplication.shared.open(url , options: [:]) { [weak self] (completed) in
            self?.activityDidFinish(completed)
        }
    }
}
