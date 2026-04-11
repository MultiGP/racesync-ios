//
//  RSAPIKey.swift
//  RaceSyncAPI
//
//  Created by Ignacio Romero Zurbuchen on 2019-10-27.
//  Copyright © 2019 MultiGP Inc. All rights reserved.
//

import Foundation

public class APICredential {
    public let apiKey: String
    public var email: String
    public var password: String

    public init(apiKey: String, email: String, password: String) {
        self.apiKey = apiKey
        self.email = email
        self.password = password
    }

    public func invalidateLogin() {
        self.email = ""
        self.password = ""
    }
}
