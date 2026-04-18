//
//  SeriesFeedController.swift
//  RaceSync
//
//  Created by Ignacio Romero Zurbuchen on 2026-02-17.
//  Copyright © 2026 MultiGP Inc. All rights reserved.
//

import RaceSyncAPI

enum SeriesFilter: EnumTitle {
    case joined, regionals, all

    var title: String {
        switch self {
        case .joined:       return "My Series"
        case .regionals:    return "Regionals"
        case .all:          return "All Series"
        }
    }

    var index: Int {
        Self.allCases.firstIndex(of: self)!
    }

    static let `default`: Self = .regionals
}

public typealias SeriesFeedControllerCompletionBlock<T> = (_ object: T?, _ cached: Bool, _ error: NSError?) -> Void

class SeriesFeedController {

    // MARK: - Private Variables

    fileprivate let api = SeriesApi()
    fileprivate var collection = [SeriesFilter: [SeriesViewModel]]()

    // MARK: - Data

    func viewModelsCount(for filter: SeriesFilter) -> Int {
        return collection[filter]?.count ?? 0
    }

    func viewModels(for filter: SeriesFilter) -> [SeriesViewModel]? {
        return collection[filter]
    }

    func shouldShowShimmer(for filter: SeriesFilter) -> Bool {
        return collection[filter] == nil
    }

    func viewModels(for filter: SeriesFilter, forceFetch: Bool = false, completion: SeriesFeedControllerCompletionBlock<[SeriesViewModel]>?) {
        
        if let viewModels = viewModels(for: filter) {
            completion?(viewModels, true, nil)
            guard forceFetch else { return }
        }

        api.getSeries { objects, error in
            if let objects = objects {
                self.collection[.joined] = self.getJoinedSeries(from: objects)
                self.collection[.regionals] = self.getRegionalSeries(from: objects)
                self.collection[.all] = self.getAllSeries(from: objects)
                completion?(self.collection[filter], false, nil)
            } else if error != nil {
                completion?(nil, false, error)
            }
        }
    }

    fileprivate func getJoinedSeries(from objects: [Series]) -> [SeriesViewModel] {
        return sortedSeries(objects.filter { $0.isJoined == true }, prioritizeRecent: true)
            .map { SeriesViewModel(with: $0) }
    }

    fileprivate func getRegionalSeries(from objects: [Series]) -> [SeriesViewModel] {
        return sortedSeries(objects.filter { $0.scoreType == .regionals }, prioritizeJoined: true)
            .map { SeriesViewModel(with: $0) }
    }

    fileprivate func getAllSeries(from objects: [Series]) -> [SeriesViewModel] {
        return sortedSeries(objects, prioritizeRecent: true)
            .map { SeriesViewModel(with: $0) }
    }

    fileprivate func sortedSeries(_ objects: [Series], prioritizeJoined: Bool = false, prioritizeRecent: Bool = false) -> [Series] {
        return objects.sorted {
            let now = Date()

            let aEnded = $0.endDate.map { $0 < now } ?? false
            let bEnded = $1.endDate.map { $0 < now } ?? false
            let aNoParticipation = $0.pilotCount == 0
            let bNoParticipation = $1.pilotCount == 0
            
            // joined series first
            if prioritizeJoined {
                if $0.isJoined != $1.isJoined { return $0.isJoined == true }
            }

            // ended series always last
            if aEnded != bEnded { return !aEnded }

            // no participation just before ended
            if aNoParticipation != bNoParticipation { return !aNoParticipation }

            // recency before popularity
            if prioritizeRecent {
                let calendar = Calendar.current
                let aYear = ($0.endDate ?? $0.startDate).map { calendar.component(.year, from: $0) }
                let bYear = ($1.endDate ?? $1.startDate).map { calendar.component(.year, from: $0) }

                if let aYear, let bYear, aYear != bYear {
                    return aYear > bYear
                }
                if (aYear == nil) != (bYear == nil) {
                    return aYear != nil
                }
            }

            // popularity last
            return $0.pilotCount > $1.pilotCount
        }
    }
}
