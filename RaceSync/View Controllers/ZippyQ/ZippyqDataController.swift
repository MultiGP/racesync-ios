//
//  ZippyqDataController.swift
//  RaceSync
//
//  Created by Ignacio Romero on 2026-08-15.
//  Copyright © 2026 MultiGP Inc. All rights reserved.
//

import Foundation
import RaceSyncAPI

protocol ZippyqDataControllerDelegate: AnyObject {
    func zippyqDataControllerDidUpdateContent(_ controller: ZippyqDataController)
    func zippyqDataController(_ controller: ZippyqDataController, didFailToLoadContent error: NSError)
}

/// Coordinates ZippyQ data and user actions independently from its view controller.
///
/// Responsibilities:
/// - Fetches queues and checks revision changes through interval-based polling.
/// - Prevents duplicate content requests and refreshes its derived state after mutations.
/// - Builds round view models and identifies the next queued round.
/// - Limits past queues while a race is active, keeping the most recent configurable number visible.
/// - Restores all past queues when no queue is running, the race is finalized, or its two-day window passes.
/// - Adds, switches, and removes the current user from queued rounds.
/// - Counts queued users per frequency, excluding LIVE and PAST rounds.
/// - Exposes the current user's pack usage, queued packs, and upcoming rounds.
/// - Persists selected frequency preferences per race, selecting all configured frequencies by default.
/// - Removes persisted preferences for frequencies that are no longer configured for the race.
/// - Builds smart-join input from available queued slots, all current assignments, and flown history.
/// - Enforces pack-limit eligibility and delegates frequency selection to `ZippyqSmartJoinable`.
/// - Joins the recommended round and frequency with a single API attempt.
///
/// This controller does not own view layout, expansion state, loading indicators, navigation,
/// alert presentation, or retry behavior.
final class ZippyqDataController {

    // MARK: - Public Variables

    /// Number of the most recent past queues displayed while focusing on a running race.
    static var visiblePastQueueCount = 2

    weak var delegate: ZippyqDataControllerDelegate?

    var canJoinQueues: Bool {
        return currentUser != nil && race?.isJoined == true && race?.zippyNoKiosk == true
    }

    var smartJoinRecommendation: ZippyqSmartJoinRecommendation? {
        guard canJoinQueues, let response, let userId = currentUser?.id else { return nil }
        return smartJoiner.recommendation(for: smartJoinInput(from: response, userId: userId))
    }

    var headerViewModel: ZippyqHeaderViewModel {
        let configuredViewModels = frequencies.prefix(8).map {
            ZippyqHeaderFrequencyViewModel(
                frequency: $0.frequency,
                channelLabel: $0.channelLabel,
                queuedPilotCount: queuedPilotCount(for: $0.frequency),
                color: FrequencyColor.color(for: $0.frequency),
                isSelected: selectedFrequencies.contains($0.frequency),
                isEnabled: true
            )
        }
        var frequencyViewModels = Array(configuredViewModels)
        while frequencyViewModels.count < 4 {
            frequencyViewModels.append(ZippyqHeaderFrequencyViewModel())
        }

        return ZippyqHeaderViewModel(
            frequencyViewModels: frequencyViewModels,
            preferenceLabel: selectedFrequencies.isEmpty ? "Select at least one channel" : "Select your preference",
            currentUserStats: currentUserStats,
            maximumPackCount: race?.cycleCount ?? 0,
            isCurrentUserUpNext: isCurrentUserUpNext,
            isJoinEnabled: smartJoinRecommendation != nil
        )
    }

    // MARK: - Private Variables

    fileprivate weak var raceController: RaceController?
    fileprivate let raceId: ObjectId
    fileprivate let zippyqApi: ZippyqApiInterface = ZippyqApi()
    fileprivate let smartJoiner: ZippyqSmartJoinable = ZippyqSmartJoiner()
    fileprivate let userDefaults = UserDefaults.standard
    fileprivate let pollingController = PollingController()

    fileprivate var response: ZippyqResponse?
    fileprivate var revisionHash: ZippyqRevisionHash?
    fileprivate var isLoadingContent = false
    
    private(set) var hasLoadedContent = false
    private(set) var roundViewModels = [ZippyqRoundViewModel]()
    private(set) var frequencies = [Frequency]()
    private(set) var frequencyQueueCounts = [String: Int]()
    private(set) var currentUserStats: ZippyqPilotStats?
    private(set) var selectedFrequencies = Set<String>()

    fileprivate var race: Race? {
        return raceController?.race
    }

    fileprivate var currentUser: User? {
        return APIServices.shared.myUser
    }

    fileprivate var preferencesKey: String {
        return "com.multigp.racesync.preferences.zippyq.frequencies.\(raceId)"
    }

    // MARK: - Initialization

    init(raceController: RaceController) {
        self.raceController = raceController
        self.raceId = raceController.raceId
        pollingController.delegate = self
    }

    // MARK: - Data Load

    func startPolling() {
        pollingController.start() // won't start if isPollEnabled() returns false
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

    func toggleSelectedFrequency(_ frequency: String) {
        var frequencies = selectedFrequencies
        if frequencies.contains(frequency) {
            frequencies.remove(frequency)
        } else {
            frequencies.insert(frequency)
        }
        setSelectedFrequencies(frequencies)
    }

    func queuedPilotCount(for frequency: String) -> Int {
        return frequencyQueueCounts[frequency, default: 0]
    }

    func channelLabel(for frequency: String) -> String? {
        return frequencies.first { $0.frequency == frequency }?.channelLabel
    }

    func joinConfirmationViewModel(for recommendation: ZippyqSmartJoinRecommendation) -> ZippyqJoinConfirmationViewModel {
        let channel = channelLabel(for: recommendation.frequency) ?? recommendation.frequency
        let previousFrequency = mostRecentlyAssignedFrequency(before: recommendation)
        let queue = response?.queues.first {
            $0.cycle == recommendation.cycle && $0.heat == recommendation.heat
        }
        let projectedStartTime = queue?.projected == true ? queue?.startTime : nil
        return ZippyqJoinConfirmationViewModel(
            recommendation: recommendation,
            channel: channel,
            previousFrequency: previousFrequency,
            projectedStartTime: projectedStartTime
        )
    }

    // MARK: - Actions

    func addPilot(slot: Int, cycle: Int, heat: Int, completion: @escaping CompletionBlock) {
        guard let user = currentUser else {
            completion(missingCurrentUserError)
            return
        }

        performAction({ completionBlock in
            zippyqApi.addPilot(to: raceId, pilotId: user.id, slot: slot,
                         cycle: cycle, heat: heat, completion: completionBlock)
        }, completion: completion)
    }

    func removePilot(slot: Int, cycle: Int, heat: Int, completion: @escaping CompletionBlock) {
        guard let user = currentUser else {
            completion(missingCurrentUserError)
            return
        }

        performAction({ completionBlock in
            zippyqApi.removePilot(from: raceId, pilotId: user.id, slot: slot,
                            cycle: cycle, heat: heat, completion: completionBlock)
        }, completion: completion)
    }

    func joinNextRound(completion: @escaping (ZippyqSmartJoinRecommendation?, NSError?) -> Void) {
        guard let response, let userId = currentUser?.id else {
            completion(nil, nil)
            return
        }

        let input = smartJoinInput(from: response, userId: userId)
        let recommendation = smartJoiner.recommendation(for: input)
        logSmartJoin(input: input, recommendation: recommendation)

        guard let recommendation else {
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

// MARK: - PollingControllerDelegate

extension ZippyqDataController: PollingControllerDelegate {

    func isPollEnabled() -> Bool {
        guard let race else { return false }
        return !race.isFinalized && !race.hasEnded
    }

    func polling() {
        zippyqApi.getRevision(for: raceId, revision: revisionHash) { [weak self] revision, error in
            guard let self else { return }

            if let error {
                Clog.log("ZippyQ getRevision failed: \(error.localizedDescription)")
            } else if let revision, revision.value != revisionHash {
                fetchContent(revision: revision.value)
            }
        }
    }
}

private extension ZippyqDataController {

    func mostRecentlyAssignedFrequency(before recommendation: ZippyqSmartJoinRecommendation) -> String? {
        guard let userId = currentUser?.id else { return nil }

        return response?.queues
            .filter {
                $0.cycle < recommendation.cycle
                    || ($0.cycle == recommendation.cycle && $0.heat < recommendation.heat)
            }
            .flatMap { queue in
                queue.entries.compactMap { entry -> (queue: ZippyQueue, frequency: String)? in
                    guard entry.user?.id == userId,
                          let frequency = entry.frequency?.frequency else { return nil }
                    return (queue, frequency)
                }
            }
            .max {
                if $0.queue.cycle == $1.queue.cycle { return $0.queue.heat < $1.queue.heat }
                return $0.queue.cycle < $1.queue.cycle
            }?.frequency
    }

    var isCurrentUserUpNext: Bool {
        guard let userId = currentUser?.id,
              let nextQueue = response?.queues.first(where: { $0.status == .queued }) else {
            return false
        }
        return nextQueue.entries.contains { $0.user?.id == userId }
    }

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

        zippyqApi.getQueues(for: raceId) { [weak self] response, error in
            guard let self else { return }
            isLoadingContent = false

            if let response {
                revisionHash = revision
                updateContent(with: response)
            } else if let error {
                Clog.log("ZippyQ getQueues failed: \(error.localizedDescription)")
                delegate?.zippyqDataController(self, didFailToLoadContent: error)
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
        delegate?.zippyqDataControllerDidUpdateContent(self)
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

        let hasRunningQueue = response.queues.contains { $0.status == .running }
        let hidesPastQueues = hasRunningQueue
            && !race.isFinalized
            && !race.hasEnded(extendedByDays: 2)
        let visiblePastQueues = Set(
            response.queues
                .filter { $0.status == .previous }
                .sorted {
                    if $0.cycle == $1.cycle { return $0.heat < $1.heat }
                    return $0.cycle < $1.cycle
                }
                .suffix(max(0, Self.visiblePastQueueCount))
                .map(ObjectIdentifier.init)
        )
        let queues = response.queues.filter {
            !hidesPastQueues
                || $0.status != .previous
                || visiblePastQueues.contains(ObjectIdentifier($0))
        }

        var queueGroups = [(cycle: Int32, status: ZippyqStatus, queues: [ZippyQueue])]()
        for queue in queues {
            if let index = queueGroups.firstIndex(where: {
                $0.cycle == queue.cycle && $0.status == queue.status
            }) {
                queueGroups[index].queues.append(queue)
            } else {
                queueGroups.append((queue.cycle, queue.status, [queue]))
            }
        }

        let orderedQueues = queueGroups.flatMap {
            $0.queues.sorted { $0.heat < $1.heat }
        }
        
        let lastOccupiedQueuedIndex = orderedQueues.lastIndex {
            $0.status == .queued && !$0.entries.isEmpty
        }
        var includedTrailingEmptyQueuedRound = false
        let visibleQueues = orderedQueues.enumerated().compactMap { index, queue in
            guard queue.status == .queued, queue.entries.isEmpty else { return queue }
            if let lastOccupiedQueuedIndex, index < lastOccupiedQueuedIndex { return queue }
            guard canJoinQueues, !includedTrailingEmptyQueuedRound else { return nil }
            includedTrailingEmptyQueuedRound = true
            return queue
        }
        let nextQueuedIndex = visibleQueues.firstIndex { $0.status == .queued }

        roundViewModels = visibleQueues.enumerated().map { index, queue in
            ZippyqRoundViewModel(
                with: queue,
                frequencies: frequencies,
                pilotStats: response.pilotStats,
                maximumPackCount: race.cycleCount,
                scoringFormat: race.trueScoringFormat,
                isUpNext: (race.inProgress && index == nextQueuedIndex)
            )
        }
    }

    func smartJoinInput(from response: ZippyqResponse, userId: ObjectId) -> ZippyqSmartJoinInput {
        let prospectiveRoundCount = max(1, Int(race?.zippyqIterator ?? 0) + 1)
        let lastCycle = response.queues.map(\.cycle).max() ?? 0
        let prospectiveRounds = (1...prospectiveRoundCount).map { offset in
            ZippyqSmartJoinRound(
                cycle: lastCycle + Int32(offset),
                heat: 1,
                containsCurrentUser: false,
                slots: frequencies.map {
                    ZippyqSmartJoinSlot(frequency: $0.frequency, slot: $0.slot, isAvailable: true)
                }
            )
        }
        let roundSequence = (response.queues.map {
            ZippyqSmartJoinRoundPosition(cycle: $0.cycle, heat: $0.heat)
        } + prospectiveRounds.map {
            ZippyqSmartJoinRoundPosition(cycle: $0.cycle, heat: $0.heat)
        })
            .reduce(into: [ZippyqSmartJoinRoundPosition]()) { positions, position in
                if !positions.contains(position) { positions.append(position) }
            }
            .sorted {
                if $0.cycle == $1.cycle { return $0.heat < $1.heat }
                return $0.cycle < $1.cycle
            }

        let assignedEntries = response.queues.flatMap { queue in
            queue.entries.compactMap { entry -> (queue: ZippyQueue, entry: ZippyqEntry)? in
                guard entry.user?.id == userId else { return nil }
                return (queue, entry)
            }
        }

        let currentUserRounds = response.queues.compactMap { queue -> ZippyqSmartJoinRoundPosition? in
            guard queue.entries.contains(where: { $0.user?.id == userId }) else { return nil }
            return ZippyqSmartJoinRoundPosition(cycle: queue.cycle, heat: queue.heat)
        }

        let flownEntries = response.queues
            .filter { $0.status == .running || $0.status == .previous }
            .flatMap { queue in
                queue.entries.compactMap { entry -> (queue: ZippyQueue, entry: ZippyqEntry)? in
                    guard entry.user?.id == userId else { return nil }
                    return (queue, entry)
                }
            }

        let mostRecentAssignedFrequency = assignedEntries.max {
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
            } + prospectiveRounds

        let maximumPackCount = race?.cycleCount ?? 0
        let allocatedPackCount = currentUserStats?.queuedCount ?? 0
        let canJoinAnotherRound = maximumPackCount <= 0 || allocatedPackCount < maximumPackCount

        return ZippyqSmartJoinInput(
            queuedRounds: rounds,
            roundSequence: roundSequence,
            currentUserRounds: currentUserRounds,
            selectedFrequencies: selectedFrequencies,
            mostRecentlyAssignedFrequency: mostRecentAssignedFrequency,
            flownFrequencyCounts: frequencyCounts,
            canJoinAnotherRound: canJoinAnotherRound,
            maximumQueueDepth: race?.maxZippyqDepth ?? 0,
            requiredRestRounds: race?.zippyqIterator ?? 0
        )
    }

    func logSmartJoin(input: ZippyqSmartJoinInput,
                      recommendation: ZippyqSmartJoinRecommendation?) {
        let selected = input.selectedFrequencies
            .map { channelLabel(for: $0) ?? $0 }
            .sorted()
            .joined(separator: ", ")
        let recent = input.mostRecentlyAssignedFrequency
            .map { channelLabel(for: $0) ?? $0 } ?? "none"
        let usage = input.flownFrequencyCounts
            .map { "\(channelLabel(for: $0.key) ?? $0.key):\($0.value)" }
            .sorted()
            .joined(separator: ", ")
        let queuedCount = input.queuedRounds.filter(\.containsCurrentUser).count

        Clog.log("ZippyQ Smart Join choice: selected [\(selected)], recent \(recent), usage [\(usage)], depth \(queuedCount)/\(input.maximumQueueDepth), rest \(input.requiredRestRounds), pack eligible \(input.canJoinAnotherRound)")

        guard let recommendation else {
            Clog.log("ZippyQ Smart Join result: none")
            return
        }

        let channel = channelLabel(for: recommendation.frequency) ?? recommendation.frequency
        Clog.log("ZippyQ Smart Join result: round \(recommendation.cycle), heat \(recommendation.heat), channel \(channel), slot \(recommendation.slot), reason \(recommendation.reason)")
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
