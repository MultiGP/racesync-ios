//
//  URL+Extensions.swift
//  RaceSyncAPI
//
//  Created by Ignacio Romero Zurbuchen on 2020-03-04.
//  Copyright © 2020 MultiGP Inc. All rights reserved.
//

import Foundation

public extension URL {

    var SLD: String? {
        return host?.components(separatedBy: ".").suffix(2).joined(separator: ".")
    }

    var rootDomain: String? {
        guard let hostName = self.host else { return nil }
        let components = hostName.components(separatedBy: ".")

        if components.count > 2 {
            return components.suffix(2).joined(separator: ".")
        } else {
            return hostName
        }
    }
}
