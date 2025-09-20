//
//  String+HTML.swift
//  RaceSync
//
//  Created by Ignacio Romero Zurbuchen on 2024-12-29.
//  Copyright © 2024 MultiGP Inc. All rights reserved.
//

import UIKit

extension String {

    func replaceHTMLColorTag(with color: UIColor) -> String {
        let colorHex = color.toHexString()
        let pattern = #"color:\s*#([a-fA-F0-9]{6}|[a-fA-F0-9]{3})"#
        return self.replacingOccurrences(of: pattern, with: colorHex, options: .regularExpression, range: nil)
    }

    func stripHTMLFontTag() -> String {
        let pattern = #"font-family:\s*[^;"]*;?"#
        return self.replacingOccurrences(of: pattern, with: "", options: .regularExpression, range: nil )
    }

    func stripHTMLEdges() -> String {
        var result = self

        let emptyParagraphPattern = #"<p>(&nbsp;|\s)*</p>"#
        if let regex = try? NSRegularExpression(pattern: emptyParagraphPattern, options: [.caseInsensitive]) {
            let range = NSRange(result.startIndex..<result.endIndex, in: result)
            result = regex.stringByReplacingMatches(in: result, options: [], range: range, withTemplate: "")
        }

        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
