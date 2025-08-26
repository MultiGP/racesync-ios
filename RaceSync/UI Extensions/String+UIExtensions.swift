//
//  String+UIExtensions.swift
//  RaceSync
//
//  Created by Ignacio Romero Zurbuchen on 2025-06-02.
//  Copyright © 2025 MultiGP Inc. All rights reserved.
//

import Foundation

extension String {

    var containsEmoji: Bool {
        return self.unicodeScalars.contains { $0.properties.isEmoji && ($0.value > 0x238C || $0.properties.isEmojiPresentation) }
    }

    // The native ordinal API from NumberFormatter (.numberStyle = .ordinal)
    // always adds a comma for thousands, hitting a limit.
    // This is a custom method suggested by ChatGPT
    static func stringWithOrdinalSuffix(for number: Int32) -> String {
        return "\(number)\(ordinalSuffix(for: number))"
    }

    static func ordinalSuffix(for number: Int32) -> String {
        let ones = number % 10
        let tens = (number / 10) % 10

        if tens == 1 {
            return "th"
        }

        switch ones {
            case 1: return "st"
            case 2: return "nd"
            case 3: return "rd"
            default: return "th"
        }
    }
}
