//
//  User+Extensions.swift
//  RaceSyncAPI
//
//  Created by Ignacio Romero Zurbuchen on 2019-12-12.
//  Copyright © 2019 MultiGP Inc. All rights reserved.
//

import Foundation

public extension User {

    /**
     Convenience to identify if a User is the current signed in user.
     */
    var isMe: Bool {
        guard let myUser = APIServices.shared.myUser else { return false }
        return id == myUser.id
    }

    /**
     Convenience to identify if a user has joined a specific race.
     */
    func hasJoined(_ race: Race) -> Bool {
        guard let raceEntries = race.entries else { return false }

        return raceEntries.contains(where: { (entry) -> Bool in
            return entry.pilotId == id
        })
    }

    /**
     Convenience to identify if a multigp.com User is part of the development team,
     to show special dev tools such as API environment switch, feature flags and more.
     Add your MGP user id to the list.
     */
    var isDevTeam: Bool {
        let ids = [
            "20676",    // Ignacio Romero
            "35533",    // Viki Baarathi
            "2145",     // Mark Grohe
            "15308",    // Shawn Ames
            "96",       // Roger Bess
        ]

        return ids.contains(where: { (someId) -> Bool in
            return someId == id
        })
    }
}
