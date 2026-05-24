//
//  FileStore.swift
//  RaceSync
//
//  Created by Ignacio Romero on 2026-05-23.
//  Copyright © 2026 MultiGP Inc. All rights reserved.
//

import Foundation

class FileStore {
    
    static func url(for filename: String) -> URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return docs.appendingPathComponent(filename)
    }
    
    /// Converts a human-readable name into a snake_cased lowercased filename
    /// e.g. "MultiGP International Open 2026" → "MultiGP_International_Open_2026.json"
    static func sanitizedFileName(from name: String, extension ext: String = "json") -> String {
        let snake = name
            .components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
            .joined(separator: "_")
        return "\(snake).\(ext)".lowercased()
    }
}
