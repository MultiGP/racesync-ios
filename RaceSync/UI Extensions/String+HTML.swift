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
        let regexPattern = #"color:\s*#([a-fA-F0-9]{6}|[a-fA-F0-9]{3})"#

        let updatedString = self.replacingOccurrences(
            of: regexPattern,
            with: colorHex,
            options: .regularExpression,
            range: nil
        )

        return updatedString
    }

    func stripHTMLFontTag() -> String {

        let regexPattern = #"font-family:\s*[^;"]*;?"#

        let updatedString = self.replacingOccurrences(
                of: regexPattern,
                with: "",
                options: .regularExpression,
                range: nil
            )

        return updatedString
    }
}
