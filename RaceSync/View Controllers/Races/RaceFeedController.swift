//
//  RaceFeedController.swift
//  RaceSync
//
//  Created by Ignacio Romero Zurbuchen on 2020-03-05.
//  Copyright © 2020 MultiGP Inc. All rights reserved.
//

import UIKit
import RaceSyncAPI
import CoreLocation

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
//        if filter == .series, raceCollection[filter]?.count == 0 {
//            return true
//        }
        return raceCollection[filter] == nil
    }

    func raceViewModels(for filter: RaceFilter, forceFetch: Bool = false, completion: @escaping ObjectCompletionBlock<[RaceViewModel]>) {
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

    func getJoinedRaces(_ forceFetch: Bool = false, _ completion: @escaping ObjectCompletionBlock<[RaceViewModel]>) {

        if let viewModels = raceCollection[.joined], !forceFetch {
            completion(viewModels, nil)
            return
        }

        let filters = remoteFilters(with: .joined)
        let sorting: RaceViewSorting = settings.showPastEvents ? .ascending : .descending

        raceApi.getMyRaces(filters: filters) { [weak self] (races, error) in
            if let filteredRaces = self?.locallyFilteredRaces(races) {
                let sortedViewModels = RaceViewModel.sortedViewModels(with: filteredRaces, sorting: sorting)
                self?.raceCollection[.joined] = sortedViewModels
                completion(sortedViewModels, nil)
            } else {
                completion(nil, error)
            }
        }
    }

    func getNearbydRaces(_ forceFetch: Bool = false, _ completion: @escaping ObjectCompletionBlock<[RaceViewModel]>) {

        if let viewModels = raceCollection[.nearby], !forceFetch {
            completion(viewModels, nil)
            return
        }

        let filters = remoteFilters(with: .nearby)

        let coordinate = LocationManager.shared.location?.coordinate
        let lat = coordinate?.latitude.string
        let long = coordinate?.longitude.string

        raceApi.getMyRaces(filters: filters, latitude: lat, longitude: long) { [weak self] (races, error) in
            if let filteredRaces = self?.locallyFilteredRaces(races) {
                let sortedViewModels = RaceViewModel.sortedViewModels(with: filteredRaces, sorting: .distance)
                self?.raceCollection[.nearby] = sortedViewModels
                completion(sortedViewModels, nil)
            } else {
                completion(nil, error)
            }
        }
    }

    func getChapterRaces(_ forceFetch: Bool = false, _ completion: @escaping ObjectCompletionBlock<[RaceViewModel]>) {
        guard let user = APIServices.shared.myUser else { return }

        if let viewModels = raceCollection[.chapters], !forceFetch {
            completion(viewModels, nil)
            return
        }

        let filters = remoteFilters()
        let sorting: RaceViewSorting = settings.showPastEvents ? .ascending : .descending

        raceApi.getRaces(with: filters, chapterIds: user.chapterIds) { [weak self] races, error in
            if let filteredRaces = self?.locallyFilteredRaces(races) {
                let sortedViewModels = RaceViewModel.sortedViewModels(with: filteredRaces, sorting: sorting)
                self?.raceCollection[.chapters] = sortedViewModels
                completion(sortedViewModels, nil)
            } else {
                completion(nil, error)
            }
        }
    }

    func getRaces(for class: RaceClass, _ forceFetch: Bool = false, _ completion: @escaping ObjectCompletionBlock<[RaceViewModel]>) {

        if let viewModels = raceCollection[.classes(`class`)], !forceFetch {
            completion(viewModels, nil)
            return
        }

        let filters: [RaceListFilters] = [.upcoming]
        let sorting: RaceViewSorting = settings.showPastEvents ? .ascending : .descending

        raceApi.getRaces(with: filters, raceClass: `class`) { [weak self] (races, error) in
            if let filteredRaces = self?.locallyFilteredRaces(races) {
                let sortedViewModels = RaceViewModel.sortedViewModels(with: filteredRaces, sorting: sorting)
                self?.raceCollection[.classes(`class`)] = sortedViewModels
                completion(sortedViewModels, nil)
            } else {
                completion(nil, error)
            }
        }
    }

    func getRaces(for series: GQSeries, _ forceFetch: Bool = false, _ completion: @escaping ObjectCompletionBlock<[RaceViewModel]>) {

        if let viewModels = raceCollection[.series(series)], !forceFetch {
            completion(viewModels, nil)
            return
        }

        let filters: [RaceListFilters] = [.series]

        raceApi.getRaces(with: filters, startDate: "\(series.year)", pageSize: 150) { [weak self]  (races, error) in
            if let seriesRaces = races {
                let sortedViewModels = RaceViewModel.sortedViewModels(with: seriesRaces, sorting: .ascending)
                self?.raceCollection[.series(series)] = sortedViewModels
                completion(sortedViewModels, nil)
            } else {
                completion(nil, error)
            }
        }
    }

    func locallyFilteredRaces(_ races: [Race]?) -> [Race]? {
        guard !settings.showPastEvents else { return races }

        return races?.filter({ (race) -> Bool in
            guard let startDate = race.startDate else { return false }
            return startDate.isInToday || startDate.timeIntervalSinceNow.sign == .plus
        })
    }

    func remoteFilters(with filter: RaceListFilters? = nil) -> [RaceListFilters] {
        var filters = [RaceListFilters]()

        if let filter = filter {
            filters += [filter]
        }
        if !settings.showPastEvents {
            filters += [.upcoming]
        }
        return filters
    }
}
