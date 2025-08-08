//
//  MGPWebConstant.swift
//  RaceSync
//
//  Created by Ignacio Romero Zurbuchen on 2019-11-11.
//  Copyright © 2019 MultiGP Inc. All rights reserved.
//

import Foundation

public enum MGPWebConstant: String {
    case apiBase = "https://www.multigp.com/mgp/multigpwebservice/"
    case s3Url = "https://multigp-storage-new.s3.us-east-2.amazonaws.com"

    case raceView = "https://www.multigp.com/races/view/?race"
    case chapterView = "https://www.multigp.com/chapters/view/?chapter"
    case userView = "https://www.multigp.com/pilots/view/?pilot"

    case zippyqView = "https://www.multigp.com/MultiGP/views/zippyq.php?raceId"

    case viewZipperSeasonResults = "https://www.multigp.com/MultiGP/views/viewZipperSeasonResults.php"
    //     ?season1=2025Summer&season2=2025Spring&exportcsv=true

    case processPayment = "https://www.multigp.com/MultiGP/views/processPayment.php"
    //     ?raceId=zzzzzz&pilotId=yyyy

}

public class MGPWeb {

    public static func getURL(for constant: MGPWebConstant) -> URL {
        let url = getUrl(for: constant)
        return URL(string: url)!
    }

    public static func getUrl(for constant: MGPWebConstant, value: String? = nil) -> String {

        var baseUrl = constant.rawValue
        if APIServices.shared.settings.isDev {
            baseUrl = constant.rawValue.replacingOccurrences(of: "www", with: "dev")
        }

        if let value = value {
            return "\(baseUrl)=\(value.replacingOccurrences(of: " ", with: "-", options: .literal, range: nil))"
        } else {
            return baseUrl
        }
    }

    public static func getURL(for constant: MGPWebConstant, value: String? = nil) -> URL? {
        let url = Self.getUrl(for: constant, value: value)
        return URL(string: url)
    }
}
