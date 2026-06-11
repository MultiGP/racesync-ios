//
//  RaceFeedController.swift
//  RaceSync
//
//  Created by Ignacio Romero Zurbuchen on 2020-03-05.
//  Copyright © 2020 MultiGP Inc. All rights reserved.
//

import Foundation
import RaceSyncAPI
import CoreLocation

// cached is true when the returned array is from the cached collection or a new data collection from the server
public typealias RaceFeedControllerCompletionBlock<T> = (_ object: T?, _ cached: Bool, _ error: NSError?) -> Void

// 
class RaceFeedController {

    // MARK: - Public Variables

    var raceFilters: [RaceFilter]

    // MARK: - Private Variables

    fileprivate let api = RaceApi()
    fileprivate var collection = [RaceFilter: [RaceViewModel]]()

    fileprivate var settings: APISettings {
        get { return APIServices.shared.settings }
    }

    // MARK: - Initialization

    init(_ filters: [RaceFilter]) {
        self.raceFilters = filters
    }

    // MARK: - Data

    func viewModelsCount(for filter: RaceFilter) -> Int {
        return collection[filter]?.count ?? 0
    }

    func viewModels(for filter: RaceFilter) -> [RaceViewModel]? {
        return collection[filter]
    }

    func shouldShowShimmer(for filter: RaceFilter) -> Bool {
        return collection[filter] == nil
    }

    func viewModels(for filter: RaceFilter, forceFetch: Bool = false, completion: RaceFeedControllerCompletionBlock<[RaceViewModel]>?) {
        switch filter {
        case .joined:
            getJoinedRaces(forceFetch, completion)
        case .nearby:
            getNearbydRaces(forceFetch, completion)
        case .chapters:
            getChapterRaces(forceFetch, completion)
        case .classes(let raceClass):
            getRaces(for: raceClass, forceFetch, completion)
        case .series(let series):
            getRaces(for: series, forceFetch, completion)
        }
    }

    func invalidateDataSource() {
        collection = [RaceFilter: [RaceViewModel]]() // re-initialize collection
    }
}

fileprivate extension RaceFeedController {

    func getJoinedRaces(_ forceFetch: Bool = false, _ completion: RaceFeedControllerCompletionBlock<[RaceViewModel]>?) {

        if let viewModels = collection[.joined] {
            completion?(viewModels, true, nil)
            guard forceFetch else { return }
        }

        let filters: [RaceListFilters] = [.joined]
        let sorting: RaceViewSorting = .descending

        api.getMyRaces(filters: filters) { [weak self] (races, error) in
            if let races = races {
                let filtered = races.filter { !$0.hasEnded }
                let sortedViewModels = RaceViewModel.sortedViewModels(with: filtered, sorting: sorting)
                self?.collection[.joined] = sortedViewModels
                completion?(sortedViewModels, false, nil)
            } else {
                completion?(nil, false, error)
            }
        }
    }

    func getNearbydRaces(_ forceFetch: Bool = false, _ completion: RaceFeedControllerCompletionBlock<[RaceViewModel]>?) {

        if let viewModels = collection[.nearby] {
            completion?(viewModels, true, nil)
            guard forceFetch else { return }
        }

        let filters: [RaceListFilters] = [.nearby, .upcoming]
        let sorting: RaceViewSorting = .descending

        let coordinate = LocationManager.shared.location?.coordinate
        let lat = coordinate?.latitude.string
        let long = coordinate?.longitude.string

        api.getMyRaces(filters: filters, latitude: lat, longitude: long) { [weak self] (races, error) in
            if let races = races {
                let sortedViewModels = RaceViewModel.sortedViewModels(with: races, sorting: sorting)
                self?.collection[.nearby] = sortedViewModels
                completion?(sortedViewModels, false, nil)
            } else {
                completion?(nil, false, error)
            }
        }
    }

    func getChapterRaces(_ forceFetch: Bool = false, _ completion: RaceFeedControllerCompletionBlock<[RaceViewModel]>?) {
        guard let user = APIServices.shared.myUser else { return }

        if let viewModels = collection[.chapters] {
            completion?(viewModels, true, nil)
            guard forceFetch else { return }
        }

        let filters: [RaceListFilters] = [.upcoming]
        let sorting: RaceViewSorting = .descending

        api.getRaces(with: filters, chapterIds: user.chapterIds) { [weak self] races, error in
            if let races = races {
                let sortedViewModels = RaceViewModel.sortedViewModels(with: races, sorting: sorting)
                self?.collection[.chapters] = sortedViewModels
                completion?(sortedViewModels, false, nil)
            } else {
                completion?(nil, false, error)
            }
        }
    }

    func getRaces(for class: RaceClass, _ forceFetch: Bool = false, _ completion: RaceFeedControllerCompletionBlock<[RaceViewModel]>?) {

        if let viewModels = collection[.classes(`class`)] {
            completion?(viewModels, true, nil)
            guard forceFetch else { return }
        }

        let filters: [RaceListFilters] = [.upcoming]
        let sorting: RaceViewSorting = .descending

        api.getRaces(with: filters, raceClass: `class`) { [weak self] (races, error) in
            if let races = races {
                let sortedViewModels = RaceViewModel.sortedViewModels(with: races, sorting: sorting)
                self?.collection[.classes(`class`)] = sortedViewModels
                completion?(sortedViewModels, false, nil)
            } else {
                completion?(nil, false, error)
            }
        }
    }

    func getRaces(for series: GQSeries, _ forceFetch: Bool = false, _ completion: RaceFeedControllerCompletionBlock<[RaceViewModel]>?) {

        if let viewModels = collection[.series(series)] {
            completion?(viewModels, true, nil)
            guard forceFetch else { return }
        }

        var filters: [RaceListFilters] = [.series]
        if series.isActive() { filters += [.upcoming] }

        let sorting: RaceViewSorting = !series.isActive() ? .ascending : .descending

        api.getRaces(with: filters, startDate: "\(series.year)", pageSize: 300) { [weak self]  (races, error) in

            if let races = races {
                let sortedViewModels = RaceViewModel.sortedViewModels(with: races, sorting: sorting)
                self?.collection[.series(series)] = sortedViewModels
                completion?(sortedViewModels, false, nil)
            } else {
                completion?(nil, false, error)
            }
        }
    }
}
