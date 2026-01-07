//
//  MapperUtil.swift
//  RaceSyncAPI
//
//  Created by Ignacio Romero Zurbuchen on 2025-09-26.
//  Copyright © 2025 MultiGP Inc. All rights reserved.
//

import Foundation
import ObjectMapper

public struct HTMLLinkTransform: TransformType {
    public typealias Object = String
    public typealias JSON = String

    private let baseURL: URL

    public init(baseURL: URL) {
        self.baseURL = baseURL
    }

    public func transformFromJSON(_ value: Any?) -> String? {
        guard var html = value as? String else { return nil }

        // Regex to capture href="something"
        let pattern = #"href="([^"]+)""#
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let nsString = html as NSString
        var matches: [(NSRange, String)] = []

        regex?.enumerateMatches(in: html, options: [], range: NSRange(location: 0, length: nsString.length)) { match, _, _ in
            guard let match = match, match.numberOfRanges > 1 else { return }
            let urlString = nsString.substring(with: match.range(at: 1))
            matches.append((match.range(at: 1), urlString))
        }

        // Replace from the back to avoid shifting indices
        for (range, urlString) in matches.reversed() {
            if let absolute = fixedURLString(urlString) {
                html = (html as NSString).replacingCharacters(in: range, with: absolute)
            }
        }

        return html
    }

    public func transformToJSON(_ value: String?) -> String? {
        return value
    }

    private func fixedURLString(_ original: String) -> String? {
        // Already absolute?
        if let url = URL(string: original), url.scheme != nil {
            return original // leave as-is
        }

        // Relative case — remove only the leading slash if present
        let trimmed = original.hasPrefix("/") ? String(original.dropFirst()) : original

        // Use URL(string:relativeTo:) so query parameters stay intact
        if let url = URL(string: trimmed, relativeTo: baseURL) {
            return url.absoluteString
        }

        // Fallback to concatenation
        return baseURL.absoluteString + original
    }
}
