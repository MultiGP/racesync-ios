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
        let path = bundle.path(forResource: "credentials", ofType: "plist")
        let dict = NSDictionary(contentsOfFile: path ?? "")

        // The RaceSync API key for the iOS client is stored on a non-versioned plist file
        guard let key = dict?["API_KEY"] as? String else {
            fatalError(MapError.apiKeyMissing.localizedDescription)
        }
        apiKey = key

#if DEBUG
        // Used for auto-completing in the login screen
        email = dict?["EMAIL"] as? String ?? ""
        password = dict?["PASSWORD"] as? String ?? ""
#else
        email = APISessionManager.getSessionEmail() ?? ""
        password = APISessionManager.getSessionPasword() ?? ""
#endif
    }
}
