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

    static func ordinalSuffix(for number: Int32) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .ordinal
        guard let full = formatter.string(from: NSNumber(value: number)) else {
            return ""
        }

        let numberString = String(number)
        if full.hasPrefix(numberString) {
            return String(full.dropFirst(numberString.count))
        } else {
            return ""
        }
    }

    static func stringWithOrdinalSuffix(for number: Int32) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .ordinal
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }
}
