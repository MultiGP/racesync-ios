//
//  UserData.swift
//  RaceSyncAPI
//
//  Created by Ignacio Romero Zurbuchen on 2023-01-26.
//  Copyright © 2023 MultiGP Inc. All rights reserved.
//

import Foundation

public struct UserData: Descriptable {

    public var firstName: String? = nil
    public var lastName: String? = nil

    public var dob: Date? = nil

    public var isPublic: Bool = true

    public init() {
        
    }
}
