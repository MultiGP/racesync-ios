//
//  StandingsController.swift
//  RaceSync
//
//  Created by Ignacio Romero Zurbuchen on 2025-12-23.
//  Copyright © 2025 MultiGP Inc. All rights reserved.
//

import Foundation
import RaceSyncAPI

class StandingsController {

    // MARK: - Private Variables

    fileprivate let standingApi = StandingApi()
    fileprivate var standingCollection = [StandingSeason: [StandingViewModel]]()

    // MARK: - Public Functions

    public func isEmpty(for season: StandingSeason) -> Bool {
        return (viewModels(for: season)).count == 0
    }

    public func viewModel(at index: Int, for season: StandingSeason) -> StandingViewModel? {
        let viewModels = viewModels(for: season)
        return viewModels[safe: index]
    }

    public func viewModels(for season: StandingSeason) -> [StandingViewModel] {
        if let viewModels = standingCollection[season] {
            return viewModels
        } else {
            return [StandingViewModel]()
        }
    }

    public func fetchStandings(for season: StandingSeason, _ completion: @escaping ObjectCompletionBlock<[StandingViewModel]>) {

        standingApi.getStandings(for: season) { (objects, error) in
            if let objects = objects {
                let vms = StandingViewModel.viewModels(with: objects)
                self.standingCollection[season] = vms
                completion(vms, nil)

            } else if error != nil {
                completion([], error)
            }
        }
    }

    public func didFetchStandings(for season: StandingSeason) -> Bool {
        let vms = standingCollection[season]
        return vms != nil
    }

    public func filter(with text: String, length: Int, for season: StandingSeason) -> [StandingViewModel] {
        let query = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard query.count >= length || query.containsEmoji else { return [] }

        let normalizedQuery = query.lowercased().folding(options: .diacriticInsensitive, locale: .current)
        let viewModels = viewModels(for: season)

        return viewModels.filter { viewModel in
            let label = viewModel.titleLabel

            if query.containsEmoji {
                return label.contains(query)
            } else {
                let words = label.lowercased()
                    .folding(options: .diacriticInsensitive, locale: .current)
                    .components(separatedBy: CharacterSet.alphanumerics.inverted)
                    .filter { !$0.isEmpty }
                return words.contains { $0.hasPrefix(normalizedQuery) }
            }
        }
    }
}
