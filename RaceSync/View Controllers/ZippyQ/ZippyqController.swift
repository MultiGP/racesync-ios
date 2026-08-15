//
//  ZippyqController.swift
//  RaceSync
//
//  Created by Ignacio Romero on 2026-08-15.
//  Copyright © 2026 MultiGP Inc. All rights reserved.
//

import Foundation
import RaceSyncAPI

protocol ZippyqControllerDelegate: AnyObject {
    func zippyqControllerDidUpdateContent(_ controller: ZippyqController)
}

/// Coordinates ZippyQ data and user actions independently from its view controller.
///
/// Responsibilities:
/// - Fetches queues and checks revision changes through interval-based polling.
/// - Prevents duplicate content requests and refreshes its derived state after mutations.
/// - Builds round view models and identifies the next queued round.
/// - Adds, switches, and removes the current user from queued rounds.
/// - Counts queued users per frequency, excluding LIVE and PAST rounds.
/// - Exposes the current user's pack usage, queued packs, and upcoming rounds.
/// - Persists selected frequency preferences per race, selecting all configured frequencies by default.
/// - Removes persisted preferences for frequencies that are no longer configured for the race.
/// - Builds smart-join input from available queued slots and the current user's LIVE and PAST history.
/// - Enforces pack-limit eligibility and delegates frequency selection to `ZippyqSmartJoinable`.
/// - Joins the recommended round and frequency with a single API attempt.
///
/// This controller does not own view layout, expansion state, loading indicators, navigation,
/// alert presentation, or retry behavior.
final class ZippyqController {

    weak var delegate: ZippyqControllerDelegate?

    private(set) var roundViewModels = [ZippyqRoundViewModel]()
    private(set) var frequencies = [Frequency]()
    private(set) var frequencyQueueCounts = [String: Int]()
    private(set) var currentUserStats: ZippyqPilotStats?
    private(set) var selectedFrequencies = Set<String>()

    var smartJoinRecommendation: ZippyqSmartJoinRecommendation? {
        guard race != nil, let response, let userId = currentUser?.id else { return nil }
        return smartJoiner.recommendation(for: smartJoinInput(from: response, userId: userId))
    }

    fileprivate weak var raceController: RaceController?
    fileprivate let raceId: ObjectId
    fileprivate let api: ZippyqApiInterface = ZippyqApi()
    fileprivate let smartJoiner: ZippyqSmartJoinable = ZippyqSmartJoiner()
    fileprivate let userDefaults = UserDefaults.standard
    fileprivate let pollingController = PollingController(refreshInterval: 10.0)

    fileprivate var response: ZippyqResponse?
    fileprivate var revisionHash: ZippyqRevisionHash?
    fileprivate var hasLoadedContent = false
    fileprivate var isLoadingContent = false

    fileprivate var race: Race? {
        return raceController?.race
    }

    fileprivate var currentUser: User? {
        return APIServices.shared.myUser
    }

    fileprivate var preferencesKey: String {
        return "com.multigp.racesync.preferences.zippyq.frequencies.\(raceId)"
    }

    init(raceController: RaceController) {
        self.raceController = raceController
        self.raceId = raceController.raceId
        pollingController.delegate = self
    }

    func startPolling() {
        guard race?.inProgress == true else {
            Clog.log("Skipping polling, race is not in progress anymore")
            return
        }
        
        pollingController.start()
    }

    func stopPolling() {
        pollingController.stop()
    }

    func loadContent(force: Bool = false) {
        guard !isLoadingContent, force || !hasLoadedContent else { return }
        fetchContent(revision: nil)
    }

    func setSelectedFrequencies(_ frequencies: Set<String>) {
        let validFrequencies = Set(self.frequencies.map { $0.frequency })
        selectedFrequencies = frequencies.intersection(validFrequencies)
        userDefaults.set(Array(selectedFrequencies).sorted(), forKey: preferencesKey)
    }

    func queuedPilotCount(for frequency: String) -> Int {
        return frequencyQueueCounts[frequency, default: 0]
    }

    func addPilot(slot: Int, cycle: Int, heat: Int, completion: @escaping CompletionBlock) {
        guard let user = currentUser else {
            completion(missingCurrentUserError)
            return
        }

        performAction({ completionBlock in
            api.addPilot(to: raceId, pilotId: user.id, slot: slot,
                         cycle: cycle, heat: heat, completion: completionBlock)
        }, completion: completion)
    }

    func removePilot(slot: Int, cycle: Int, heat: Int, completion: @escaping CompletionBlock) {
        guard let user = currentUser else {
            completion(missingCurrentUserError)
            return
        }

        performAction({ completionBlock in
            api.removePilot(from: raceId, pilotId: user.id, slot: slot,
                            cycle: cycle, heat: heat, completion: completionBlock)
        }, completion: completion)
    }

    func joinNextRound(completion: @escaping (ZippyqSmartJoinRecommendation?, NSError?) -> Void) {
        guard let recommendation = smartJoinRecommendation else {
            completion(nil, nil)
            return
        }

        addPilot(slot: Int(recommendation.slot),
                 cycle: Int(recommendation.cycle),
                 heat: Int(recommendation.heat)) { error in
            completion(error == nil ? recommendation : nil, error)
        }
    }
}

extension ZippyqController: PollingControllerDelegate {

    func isPollEnabled() -> Bool {
        return race?.isFinalized == false
    }

    func polling() {
        api.getRevision(for: raceId, revision: revisionHash) { [weak self] revision, error in
            guard let self else { return }

            if let error {
                Clog.log("ZippyQ getRevision failed: \(error.localizedDescription)")
            } else if let revision, revision.value != revisionHash {
                fetchContent(revision: revision.value)
            }
        }
    }
}

private extension ZippyqController {

    var missingCurrentUserError: NSError {
        return NSError(
            domain: "com.multigp.racesync.zippyq",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "You must be signed in to update the queue."]
        )
    }

    func fetchContent(revision: ZippyqRevisionHash?) {
        guard !isLoadingContent else { return }
        isLoadingContent = true

        api.getQueues(for: raceId) { [weak self] response, error in
            guard let self else { return }
            isLoadingContent = false

            if let response {
                revisionHash = revision
                updateContent(with: response)
            } else if let error {
                Clog.log("ZippyQ getQueues failed: \(error.localizedDescription)")
            }
        }
    }

    func updateContent(with response: ZippyqResponse) {
        self.response = response
        hasLoadedContent = true
        frequencies = response.frequencies.sorted { $0.slot < $1.slot }
        updateSelectedFrequencies()
        updateQueueCounts()
        updateCurrentUserStats()
        updateRoundViewModels()
        delegate?.zippyqControllerDidUpdateContent(self)
    }

    func updateSelectedFrequencies() {
        let validFrequencies = Set(frequencies.map { $0.frequency })

        if let storedFrequencies = userDefaults.stringArray(forKey: preferencesKey) {
            selectedFrequencies = Set(storedFrequencies).intersection(validFrequencies)
        } else {
            selectedFrequencies = validFrequencies
        }
        userDefaults.set(Array(selectedFrequencies).sorted(), forKey: preferencesKey)
    }

    func updateQueueCounts() {
        guard let response else { return }

        frequencyQueueCounts = response.queues
            .filter { $0.status == .queued }
            .flatMap { $0.entries }
            .reduce(into: [String: Int]()) { counts, entry in
                guard let frequency = entry.frequency?.frequency else { return }
                counts[frequency, default: 0] += 1
            }
    }

    func updateCurrentUserStats() {
        guard let userId = currentUser?.id else {
            currentUserStats = nil
            return
        }
        currentUserStats = response?.pilotStats[userId]
    }

    func updateRoundViewModels() {
        guard let response, let race else { return }

        let nextQueuedIndex = response.queues.firstIndex { $0.status == .queued }
        roundViewModels = response.queues.enumerated().map { index, queue in
            ZippyqRoundViewModel(
                with: queue,
                frequencies: frequencies,
                pilotStats: response.pilotStats,
                maximumPackCount: race.cycleCount,
                scoringFormat: race.trueScoringFormat,
                isUpNext: index == nextQueuedIndex
            )
        }
    }

    func smartJoinInput(from response: ZippyqResponse, userId: ObjectId) -> ZippyqSmartJoinInput {
        let flownEntries = response.queues
            .filter { $0.status == .running || $0.status == .previous }
            .flatMap { queue in
                queue.entries.compactMap { entry -> (queue: ZippyQueue, entry: ZippyqEntry)? in
                    guard entry.user?.id == userId else { return nil }
                    return (queue, entry)
                }
            }

        let mostRecentFrequency = flownEntries.max {
            if $0.queue.cycle == $1.queue.cycle { return $0.queue.heat < $1.queue.heat }
            return $0.queue.cycle < $1.queue.cycle
        }?.entry.frequency?.frequency

        let frequencyCounts = flownEntries.reduce(into: [String: Int]()) { counts, item in
            guard let frequency = item.entry.frequency?.frequency else { return }
            counts[frequency, default: 0] += 1
        }

        let rounds = response.queues
            .filter { $0.status == .queued }
            .map { queue in
                let occupiedFrequencies = Set(queue.entries.compactMap { $0.frequency?.frequency })
                let slots = frequencies.map {
                    ZippyqSmartJoinSlot(
                        frequency: $0.frequency,
                        slot: $0.slot,
                        isAvailable: !occupiedFrequencies.contains($0.frequency)
                    )
                }
                return ZippyqSmartJoinRound(
                    cycle: queue.cycle,
                    heat: queue.heat,
                    containsCurrentUser: queue.entries.contains { $0.user?.id == userId },
                    slots: slots
                )
            }

        let maximumPackCount = race?.cycleCount ?? 0
        let allocatedPackCount = (currentUserStats?.usedCount ?? 0) + (currentUserStats?.queuedCount ?? 0)
        let canJoinAnotherRound = maximumPackCount <= 0 || allocatedPackCount < maximumPackCount

        return ZippyqSmartJoinInput(
            queuedRounds: rounds,
            selectedFrequencies: selectedFrequencies,
            mostRecentlyFlownFrequency: mostRecentFrequency,
            flownFrequencyCounts: frequencyCounts,
            canJoinAnotherRound: canJoinAnotherRound
        )
    }

    func performAction(_ action: (@escaping ObjectCompletionBlock<ZippyqResponse>) -> Void,
                       completion: @escaping CompletionBlock) {
        pollingController.forward()
        action { [weak self] response, error in
            guard let self else { return }

            pollingController.forward()
            if let response {
                updateContent(with: response)
            } else {
                pollingController.resume()
                if let error { Clog.log("ZippyQ action failed: \(error.localizedDescription)") }
            }
            completion(error)
        }
    }
}
