//
//  ViewModelHelper.swift
//  RaceSync
//
//  Created by Ignacio Romero Zurbuchen on 2019-11-20.
//  Copyright © 2019 MultiGP Inc. All rights reserved.
//

import UIKit

class ViewModelHelper {

    static func titleLabel(for userName: String, country: String? = nil) -> String {
        var output = userName
        output.append(self.locationLabel(country: country))
        return output
    }

    static func locationLabel(for city: String? = nil, state: String? = nil, country: String? = nil) -> String {
        var strings = [String]()
        var output = String()

        if let city = city, !city.isEmpty {
            strings.append(city.capitalized)
        }
        if let state = state, !state.isEmpty {
            if state.count < 3 { // Acronyms
                strings.append(state.uppercased())
            } else if let code = RegionCodes.code(for: state) {
                strings.append(code)
            }
        }

        output = strings.joined(separator: strings.count > 1 ? ", " : "")

        // Use emojis for countries
        if let country = country, !country.isEmpty {
            output.append(" \(FlagEmojiGenerator.flag(country: country))")
        }

        return output
    }
}

struct RegionCodes {

    static let allRegions: [String: String] = {
        return usCodes.merging(canCodes) { (_, new) in new }
    }()

    static func code(for name: String) -> String? {
        // Normalize input (trim + case-insensitive)
        let key = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return allRegions.first { $0.key.caseInsensitiveCompare(key) == .orderedSame }?.value
    }

    static let usCodes: [String: String] = [
        "Alabama": "AL",
        "Alaska": "AK",
        "Arizona": "AZ",
        "Arkansas": "AR",
        "California": "CA",
        "Colorado": "CO",
        "Connecticut": "CT",
        "Delaware": "DE",
        "District of Columbia": "DC",
        "Florida": "FL",
        "Georgia": "GA",
        "Hawaii": "HI",
        "Idaho": "ID",
        "Illinois": "IL",
        "Indiana": "IN",
        "Iowa": "IA",
        "Kansas": "KS",
        "Kentucky": "KY",
        "Louisiana": "LA",
        "Maine": "ME",
        "Maryland": "MD",
        "Massachusetts": "MA",
        "Michigan": "MI",
        "Minnesota": "MN",
        "Mississippi": "MS",
        "Missouri": "MO",
        "Montana": "MT",
        "Nebraska": "NE",
        "Nevada": "NV",
        "New Hampshire": "NH",
        "New Jersey": "NJ",
        "New Mexico": "NM",
        "New York": "NY",
        "North Carolina": "NC",
        "North Dakota": "ND",
        "Ohio": "OH",
        "Oklahoma": "OK",
        "Oregon": "OR",
        "Pennsylvania": "PA",
        "Rhode Island": "RI",
        "South Carolina": "SC",
        "South Dakota": "SD",
        "Tennessee": "TN",
        "Texas": "TX",
        "Utah": "UT",
        "Vermont": "VT",
        "Virginia": "VA",
        "Washington": "WA",
        "West Virginia": "WV",
        "Wisconsin": "WI",
        "Wyoming": "WY"
    ]

    static let canCodes: [String: String] = [
        "Alberta": "AB",
        "British Columbia": "BC",
        "Manitoba": "MB",
        "New Brunswick": "NB",
        "Newfoundland and Labrador": "NL",
        "Northwest Territories": "NT",
        "Nova Scotia": "NS",
        "Nunavut": "NU",
        "Ontario": "ON",
        "Prince Edward Island": "PE",
        "Quebec": "QC",
        "Saskatchewan": "SK",
        "Yukon": "YT"
    ]
}

