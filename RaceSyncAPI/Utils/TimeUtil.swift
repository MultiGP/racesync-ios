//
//  TimeUtil.swift
//  RaceSyncAPI
//
//  Created by Ignacio Romero Zurbuchen on 2024-12-19.
//  Copyright © 2024 MultiGP Inc. All rights reserved.
//

import Foundation

public class TimeUtil {

    public static func lapTimeFormat(seconds timeString: String, showUnit: Bool = true) -> String {

        guard let raw = Double(timeString) else { return "" }

        // Convert to integer milliseconds by truncation
        let totalMs = Int(raw * 1000)

        let hours = totalMs / 3_600_000
        let minutes = (totalMs / 60_000) % 60
        let seconds = (totalMs / 1000) % 60
        let milliseconds = totalMs % 1000

        if hours > 0 {
            // Format into "H:MM:SS.mmm"
            return String(format: "%d:%02d:%02d.%03d", hours, minutes, seconds, milliseconds)
        } else if minutes > 0 {
            // Format into "MM:SS.mmm"
            return String(format: "%02d:%02d.%03d", minutes, seconds, milliseconds)
        } else if seconds >= 10 {
            // Format into "SS.mmm"
            return String(format: "%02d.%03d", seconds, milliseconds) + "\(showUnit ? "s" : "")"
        } else {
            // Format into "S.mmm"
            return String(format: "%d.%03d", seconds, milliseconds) + "\(showUnit ? "s" : "")"
        }
    }
}
