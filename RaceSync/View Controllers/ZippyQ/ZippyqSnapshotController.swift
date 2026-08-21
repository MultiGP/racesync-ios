//
//  ZippyqSnapshotController.swift
//  RaceSync
//
//  Created by Ignacio Romero on 2026-08-19.
//  Copyright © 2026 MultiGP Inc. All rights reserved.
//

import UIKit

/// Owns the collection view snapshot and round expansion state used by ZippyQ.
///
/// Responsibilities:
/// - Keeps a stable section for the layout-wide ZippyQ supplementary header.
/// - Preserves the API-provided ordering of rounds and their frequencies.
/// - Builds diffable data source snapshots for the collection view.
/// - Includes frequency items only while their round is expanded.
/// - Initially expands current active rounds and rounds containing the current user.
/// - Preserves expansion state across content refreshes and removes rounds that no longer exist.
/// - Resolves snapshot identifiers back to their corresponding view models.
///
/// This controller does not fetch or transform ZippyQ data, configure views, or apply snapshots
/// to the collection view.
final class ZippyqSnapshotController {

    // MARK: - Public Types

    enum SectionIdentifier: Hashable {
        case header
        case round(String)
    }

    struct ItemIdentifier: Hashable {
        let roundId: String
        let frequency: String
    }

    typealias Snapshot = NSDiffableDataSourceSnapshot<SectionIdentifier, ItemIdentifier>

    // MARK: - Public Variables

    private(set) var expandedRoundIds = Set<String>()

    // MARK: - Private Variables

    private var roundViewModels = [ZippyqRoundViewModel]()
    private var roundsById = [String: ZippyqRoundViewModel]()
    private var frequenciesById = [ItemIdentifier: ZippyqFrequencyViewModel]()
    private var hasInitializedExpandedRounds = false

    // MARK: - Public Methods

    func update(with roundViewModels: [ZippyqRoundViewModel]) {
        self.roundViewModels = roundViewModels
        roundsById = Dictionary(uniqueKeysWithValues: roundViewModels.map { ($0.id, $0) })
        frequenciesById = roundViewModels.reduce(into: [:]) { values, round in
            for frequency in round.frequencyViewModels {
                values[itemIdentifier(for: frequency, roundId: round.id)] = frequency
            }
        }

        let validRoundIds = Set(roundViewModels.map(\.id))
        expandedRoundIds.formIntersection(validRoundIds)

        guard !hasInitializedExpandedRounds, !roundViewModels.isEmpty else { return }
        expandedRoundIds.formUnion(roundViewModels.filter {
            $0.badge == .running || $0.frequencyViewModels.contains(where: \.isCurrentUser)
        }.map(\.id))
        hasInitializedExpandedRounds = true
    }

    func makeSnapshot() -> Snapshot {
        var snapshot = Snapshot()
        snapshot.appendSections([.header])
        for round in roundViewModels {
            let sectionIdentifier = SectionIdentifier.round(round.id)
            snapshot.appendSections([sectionIdentifier])

            guard expandedRoundIds.contains(round.id) else { continue }
            let itemIdentifiers = round.frequencyViewModels.map {
                itemIdentifier(for: $0, roundId: round.id)
            }
            snapshot.appendItems(itemIdentifiers, toSection: sectionIdentifier)
        }
        return snapshot
    }

    func toggleRound(withId roundId: String) {
        if expandedRoundIds.contains(roundId) {
            expandedRoundIds.remove(roundId)
        } else {
            expandedRoundIds.insert(roundId)
        }
    }

    func expandRound(withId roundId: String) {
        expandedRoundIds.insert(roundId)
    }

    func isRoundExpanded(withId roundId: String) -> Bool {
        return expandedRoundIds.contains(roundId)
    }

    func roundViewModel(for sectionIdentifier: SectionIdentifier) -> ZippyqRoundViewModel? {
        switch sectionIdentifier {
        case .header:
            return nil
        case .round(let roundId):
            return roundsById[roundId]
        }
    }

    func frequencyViewModel(for itemIdentifier: ItemIdentifier) -> ZippyqFrequencyViewModel? {
        return frequenciesById[itemIdentifier]
    }

    // MARK: - Private Methods

    private func itemIdentifier(for viewModel: ZippyqFrequencyViewModel,
                                roundId: String) -> ItemIdentifier {
        return ItemIdentifier(roundId: roundId, frequency: viewModel.frequency.frequency)
    }
}
