//
//  AppIcon.swift
//  RaceSync
//
//  Created by Ignacio Romero Zurbuchen on 2022-12-11.
//  Copyright © 2022 MultiGP Inc. All rights reserved.
//

import Foundation
import RaceSyncAPI
import ObjectMapper
import UIKit

class AppIcon: ImmutableMappable, Descriptable {

    let title: String
    let type: Int
    let name: String?
    let filename: String?
    let preview: UIImage?

    // MARK: - Initialization

    required init(map: Map) throws {
        title = try map.value("title")
        type = try map.value("type")
        name = try map.value("name")

        if let name = name {
            filename = "AppIcon-\(name)"
            preview = UIImage(named: filename!)
        } else {
            filename = nil
            preview = LogoImg.app_icon
        }
    }

    init() {
        title = "Red (Default)"
        type = 1
        name = ""
        filename = nil
        preview = LogoImg.app_icon
    }
}
