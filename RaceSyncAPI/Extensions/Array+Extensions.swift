//
//  Array+Extensions.swift
//  RaceSyncAPI
//
//  Created by Ignacio Romero Zurbuchen on 2020-07-31.
//  Copyright © 2020 MultiGP Inc. All rights reserved.
//

import Foundation

public extension Array {

    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }

    mutating func rearrange(from: Int, to: Int) {
        insert(remove(at: from), at: to)
    }
    
    func interspersed(with separator: Element) -> [Element] {
        guard count > 1 else { return self }
        return dropLast().flatMap { [$0, separator] } + [last!]
    }
}

public extension Array where Element: Equatable {
    func removingDuplicates() -> Array {
        return reduce(into: []) { result, element in
            if !result.contains(element) {
                result.append(element)
            }
        }
    }
}
