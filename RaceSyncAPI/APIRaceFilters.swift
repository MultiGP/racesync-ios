//
//  APIRaceFilter.swift
//  RaceSyncAPI
//
//  Created by Ignacio Romero Zurbuchen on 2025-01-02.
//  Copyright © 2025 MultiGP Inc. All rights reserved.
//

import Foundation

public enum RaceListFilters: String {
    case upcoming = "upcoming"
    case past = "past"
    case nearby = "nearby"
    case series = "qualifier"
    case joined = "joined"
}

public enum RaceFilter: EnumTitle, Hashable, Equatable {

    case joined, nearby, chapters, series, classes(RaceClass)

    public var title: String {
        switch self {
        case .joined:
            return "Joined"
        case .nearby:
            return "Nearby"
        case .chapters:
            return "Chapters"
        case .series:
            return "Global Qualifiers"
        case .classes(let `class`):
            return `class`.title
        }
    }
    public var subtitle: String {
        switch self {
        case .classes(let `class`):
            return "Classes"
        default:
            return self.title
        }
    }

    // CaseIterable
    public static var allCases: [RaceFilter] {
        return [.joined, .nearby, .chapters, .series, .classes(.open)]
    }

    // Hashable
    public func hash(into hasher: inout Hasher) {
        switch self {
        case .joined:
            hasher.combine("joined")
        case .nearby:
            hasher.combine("nearby")
        case .chapters:
            hasher.combine("chapters")
        case .series:
            hasher.combine("series")
        case .classes(let raceClass):
            hasher.combine("classes")
            hasher.combine(raceClass)
        }
    }

    // Equatable
    public static func == (lhs: RaceFilter, rhs: RaceFilter) -> Bool {
        switch (lhs, rhs) {
        case (.joined, .joined),
             (.nearby, .nearby),
             (.chapters, .chapters),
             (.series, .series):
            return true
        case (.classes(let lhsClass), .classes(let rhsClass)):
            return lhsClass == rhsClass
        default:
            return false
        }
    }
}

public extension RaceFilter {

    static func filters(with items: [String]) -> [RaceFilter] {
        var filters = [RaceFilter]()
        for item in items {
            if let filter = RaceFilter(title: item) {
                filters += [filter]
            } else if let `class` = RaceClass(title: item) {
                filters += [RaceFilter.classes(`class`)]
            }
        }
        return filters
    }
}
