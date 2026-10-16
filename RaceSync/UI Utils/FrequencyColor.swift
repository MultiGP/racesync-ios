//
//  FrequencyColor.swift
//  RaceSync
//
//  Created by Ignacio Romero on 2026-07-29.
//  Copyright © 2026 MultiGP Inc. All rights reserved.
//

import UIKit

/// Provides UI colors for VTX frequencies.
///
/// The frequency ranges are derived from Betaflight's default VTX Frequency
/// LED-strip overlay. RaceSync may adapt the displayed colors to maintain
/// contrast with its interface.
/// Source: https://www.betaflight.com/docs/development/LedStrip#vtx-frequency
///
final class FrequencyColor {

    static func color(for frequency: String) -> UIColor {
        guard let frequency = Int(frequency) else { return Color.gray200 }
        return color(for: frequency)
    }

    static func color(for frequency: Int) -> UIColor {
        switch frequency {
        case ...5672: return Color.gray100
        case 5673...5711: return .systemRed
        case 5712...5750: return .systemOrange
        case 5751...5789: return .systemYellow
        case 5790...5829: return .systemGreen
        case 5830...5867: return .systemBlue
        case 5868...5906: return UIColor(red: 0.58, green: 0, blue: 0.83, alpha: 1) // Dark violet
        default: return UIColor(red: 1, green: 0.50, blue: 0.67, alpha: 1)
        }
    }
}
