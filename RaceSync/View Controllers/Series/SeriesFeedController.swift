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
        SeriesFilter.allCases.firstIndex(of: self)!
    }

    static let `default`: Self = .regionals
}

public typealias SeriesFeedControllerCompletionBlock<T> = (_ object: T?, _ error: NSError?) -> Void


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

        guard collection.isEmpty else {
            completion?(viewModels(for: filter), nil)
            return
        }

        api.getSeries { objects, error in
            if let objects = objects {
                let viewModels = SeriesViewModel.viewModels(with: objects)

                self.collection[.regionals] = objects.compactMap {
                    $0.scoreType == .regionals ? SeriesViewModel(with: $0) : nil
                }

                self.collection[.joined] = objects.compactMap {
                    $0.isJoined == true ? SeriesViewModel(with: $0) : nil
                }

                // sorted by popularity (highest pilot participation)
                self.collection[.all] = viewModels.sorted { $0.pilotCount > $1.pilotCount }

                completion?(self.collection[filter], nil)

            } else if error != nil {
                completion?(nil, error)
            }
        }
    }
}
