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

    case joined, nearby, chapters, classes(RaceClass), series(GQSeries)

    public var title: String {
        switch self {
        case .joined:
            return "Joined"
        case .nearby:
            return "Nearby"
        case .chapters:
            return "My Chapters"
        case .classes(let `class`):
            return `class`.title
        case .series(let series):
            return series.title
        }
    }

    public var subtitle: String {
        switch self {
        case .classes( _):
            return RaceClass.groupTitle
        case .series( _):
            return GQSeries.groupTitle
        default:
            return self.title
        }
    }

    // CaseIterable
    public static var allCases: [RaceFilter] {
        return [.joined, .nearby, .chapters, .series(.init(year: Date.currentYear)), .classes(.open)] // defaults
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
        case .classes(let raceClass):
            hasher.combine("classes")
            hasher.combine(raceClass)
        case .series:
            hasher.combine("series")
        }
    }

    // Equatable
    public static func == (lhs: RaceFilter, rhs: RaceFilter) -> Bool {
        switch (lhs, rhs) {
        case (.joined, .joined),
             (.nearby, .nearby),
             (.chapters, .chapters):
            return true
        case (.classes(let lhsClass), .classes(let rhsClass)):
            return lhsClass == rhsClass
        case (.series(let lhsSeries), .series(let rhsSeries)):
            return lhsSeries == rhsSeries
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
            } else if let series = GQSeries(title: item) {
                filters += [RaceFilter.series(series)]
            }
        }
        return filters
    }
}

public struct GQSeries: EnumTitle, Hashable, Equatable {

    public let year: Int
    public static let groupTitle: String = "Global Qualifiers"

    // Computed property for the title
    public var title: String {
        return "GQ\(year)"
    }

    // CaseIterable
    public static var allCases: [GQSeries] {
        return (startYear...Date.currentYear).map { GQSeries(year: $0) }
    }

    private static let startYear: Int = 2017

    private static func isValidYear(_ year: Int) -> Bool {
        return (startYear...Date.currentYear).contains(year) // Adjust the range as needed
    }

    private static func create(for year: Int) -> GQSeries? {
        guard isValidYear(year) else { return nil }
        return GQSeries(year: year)
    }
}

public extension RaceClass {

    static let groupTitle: String = "Race Classes"
}
