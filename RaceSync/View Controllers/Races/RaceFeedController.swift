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

    fileprivate let raceApi = RaceApi()
    fileprivate var raceCollection = [RaceFilter: [RaceViewModel]]()

    fileprivate var settings: APISettings {
        get { return APIServices.shared.settings }
    }

    // MARK: - Initialization

    init(_ filters: [RaceFilter]) {
        self.raceFilters = filters
    }

    // MARK: - Actions

    func raceViewModelsCount(for filter: RaceFilter) -> Int {
        return raceCollection[filter]?.count ?? 0
    }

    func raceViewModels(for filter: RaceFilter) -> [RaceViewModel]? {
        return raceCollection[filter]
    }

    func shouldShowShimmer(for filter: RaceFilter) -> Bool {
        return raceCollection[filter] == nil
    }

    func raceViewModels(for filter: RaceFilter, forceFetch: Bool = false, completion: @escaping RaceFeedControllerCompletionBlock<[RaceViewModel]>) {
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
        raceCollection = [RaceFilter: [RaceViewModel]]() // re-initialize collection
    }
}

fileprivate extension RaceFeedController {

    func getJoinedRaces(_ forceFetch: Bool = false, _ completion: @escaping RaceFeedControllerCompletionBlock<[RaceViewModel]>) {

        if let viewModels = raceCollection[.joined] {
            completion(viewModels, true, nil)
            guard forceFetch else { return }
        }

        let filters: [RaceListFilters] = [.joined, .upcoming]
        let sorting: RaceViewSorting = .descending

        raceApi.getMyRaces(filters: filters) { [weak self] (races, error) in
            if let races = races {
                let sortedViewModels = RaceViewModel.sortedViewModels(with: races, sorting: sorting)
                self?.raceCollection[.joined] = sortedViewModels
                completion(sortedViewModels, false, nil)
            } else {
                completion(nil, false, error)
            }
        }
    }

    func getNearbydRaces(_ forceFetch: Bool = false, _ completion: @escaping RaceFeedControllerCompletionBlock<[RaceViewModel]>) {

        if let viewModels = raceCollection[.nearby] {
            completion(viewModels, true, nil)
            guard forceFetch else { return }
        }

        let filters: [RaceListFilters] = [.nearby, .upcoming]
        let sorting: RaceViewSorting = .descending

        let coordinate = LocationManager.shared.location?.coordinate
        let lat = coordinate?.latitude.string
        let long = coordinate?.longitude.string

        raceApi.getMyRaces(filters: filters, latitude: lat, longitude: long) { [weak self] (races, error) in
            if let races = races {
                let sortedViewModels = RaceViewModel.sortedViewModels(with: races, sorting: sorting)
                self?.raceCollection[.nearby] = sortedViewModels
                completion(sortedViewModels, false, nil)
            } else {
                completion(nil, false, error)
            }
        }
    }

    func getChapterRaces(_ forceFetch: Bool = false, _ completion: @escaping RaceFeedControllerCompletionBlock<[RaceViewModel]>) {
        guard let user = APIServices.shared.myUser else { return }

        if let viewModels = raceCollection[.chapters] {
            completion(viewModels, true, nil)
            guard forceFetch else { return }
        }

        let filters: [RaceListFilters] = [.upcoming]
        let sorting: RaceViewSorting = .descending

        raceApi.getRaces(with: filters, chapterIds: user.chapterIds) { [weak self] races, error in
            if let races = races {
                let sortedViewModels = RaceViewModel.sortedViewModels(with: races, sorting: sorting)
                self?.raceCollection[.chapters] = sortedViewModels
                completion(sortedViewModels, false, nil)
            } else {
                completion(nil, false, error)
            }
        }
    }

    func getRaces(for class: RaceClass, _ forceFetch: Bool = false, _ completion: @escaping RaceFeedControllerCompletionBlock<[RaceViewModel]>) {

        if let viewModels = raceCollection[.classes(`class`)] {
            completion(viewModels, true, nil)
            guard forceFetch else { return }
        }

        let filters: [RaceListFilters] = [.upcoming]
        let sorting: RaceViewSorting = .descending

        raceApi.getRaces(with: filters, raceClass: `class`) { [weak self] (races, error) in
            if let races = races {
                let sortedViewModels = RaceViewModel.sortedViewModels(with: races, sorting: sorting)
                self?.raceCollection[.classes(`class`)] = sortedViewModels
                completion(sortedViewModels, false, nil)
            } else {
                completion(nil, false, error)
            }
        }
    }

    func getRaces(for series: GQSeries, _ forceFetch: Bool = false, _ completion: @escaping RaceFeedControllerCompletionBlock<[RaceViewModel]>) {

        if let viewModels = raceCollection[.series(series)] {
            completion(viewModels, true, nil)
            guard forceFetch else { return }
        }

        var filters: [RaceListFilters] = [.series]
        if series.isActive() { filters += [.upcoming] }

        let sorting: RaceViewSorting = !series.isActive() ? .ascending : .descending

        raceApi.getRaces(with: filters, startDate: "\(series.year)", pageSize: 300) { [weak self]  (races, error) in

            if let races = races {
                let sortedViewModels = RaceViewModel.sortedViewModels(with: races, sorting: sorting)
                self?.raceCollection[.series(series)] = sortedViewModels
                completion(sortedViewModels, false, nil)
            } else {
                completion(nil, false, error)
            }
        }
    }
}
