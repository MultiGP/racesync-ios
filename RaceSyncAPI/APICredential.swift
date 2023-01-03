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
    public let email: String
    public let password: String

    init() {
        let bundle = Bundle(for: APICredential.self)

        let path = bundle.path(forResource: "Credentials", ofType: "plist")!
        let dict = NSDictionary(contentsOfFile: path)!

        apiKey = dict["API_KEY"] as? String ?? ""

        // Used during development for auto-completing the login screen
    #if DEBUG
        email = dict["EMAIL"] as? String ?? ""
        password = dict["PASSWORD"] as? String ?? ""
    #else
        email = ""
        password = ""
    #endif
    }
}
