//
//  Series+Extensions.swift
//  RaceSyncAPI
//
//  Created by Ignacio Romero Zurbuchen on 2026-04-11.
//  Copyright © 2026 MultiGP Inc. All rights reserved.
//

import Foundation

public extension Series {

    var canBeEdited: Bool {
        guard ownerId == APIServices.shared.myUser?.id else { return false }
        return true
    }

    var canBeDeleted: Bool {
        guard ownerId == APIServices.shared.myUser?.id else { return false }
        return true
    }
}
