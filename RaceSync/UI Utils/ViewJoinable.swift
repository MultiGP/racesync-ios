//
//  JoinButtonAdapter.swift
//  RaceSync
//
//  Created by Ignacio Romero Zurbuchen on 2019-12-05.
//  Copyright © 2019 MultiGP Inc. All rights reserved.
//

import UIKit
import RaceSyncAPI
import Presentr

public typealias JoinStateCompletionBlock = (_ joinState: JoinState) -> Void

protocol ViewJoinable where Self: UIViewController {
    func loadContent(forced: Bool)
    func toggleJoinButton(_ button: JoinButton, forRace race: Race, raceApi: RaceApi, _ completion: @escaping JoinStateCompletionBlock)
    func toggleJoinButton(_ button: JoinButton, forChapter chapter: Chapter, chapterApi: ChapterApi, _ completion: @escaping JoinStateCompletionBlock)
}

public enum JoinState: Equatable {
    case notJoined, notPaid(fee: Float), joined, closed

    var title: String {
        switch self {
        case .notJoined:    return "Join"
        case .joined:       return "Joined"
        case .closed:       return "Closed"
        case .notPaid(fee: let fee): return String(format: "$%.2f", fee)
        }
    }

    var flag: Bool {
        switch self {
        case .joined:       return true
        default:            return false
        }
    }

    public static func == (lhs: JoinState, rhs: JoinState) -> Bool {
        switch (lhs, rhs) {
        case (.notJoined, .notJoined),
             (.joined, .joined),
             (.closed, .closed):
            return true
        case let (.notPaid(fee1), .notPaid(fee2)):
            return fee1 == fee2
        default:
            return false
        }
    }
}

extension ViewJoinable {

    func toggleJoinButton(_ button: JoinButton, forRace race: Race, raceApi: RaceApi, _ completion: @escaping JoinStateCompletionBlock) {

        button.isLoading = true
        let state = button.joinState

        switch state {

        case .notJoined, .notPaid(_):
            if let endDate = race.endDate, endDate.isPassed {
                AlertUtil.presentAlertMessage("Cannot join a passed race.",
                                              title: "Uh Oh",
                                              delay: 0.5,
                                              completion: { _ in button.isLoading = false })
            } else {
                AppControl.shared.tryJoining(race: race, raceApi: raceApi) { (newState) in
                    self.handleStateChange(state, newState: newState, in: button, with: race, completion)
                }
            }
        case .joined:
            AppControl.shared.resign(race: race, raceApi: raceApi) { (newState) in
                self.handleStateChange(state, newState: newState, in: button, with: race, completion)
            }

        default:
            break
        }
    }

    func toggleJoinButton(_ button: JoinButton, forChapter chapter: Chapter, chapterApi: ChapterApi, _ completion: @escaping JoinStateCompletionBlock) {

        button.isLoading = true
        let state = button.joinState

        switch state {
        case .notJoined:
            AppControl.shared.join(chapter: chapter, chapterApi: chapterApi) { (newState) in
                self.handleStateChange(state, newState: newState, in: button, with: chapter, completion)
            }

        case .joined:
            AppControl.shared.resign(chapter: chapter, chapterApi: chapterApi) { (newState) in
                self.handleStateChange(state, newState: newState, in: button, with: chapter, completion)
            }
        default:
            break
        }
    }

    fileprivate func handleStateChange(_ oldState: JoinState, newState: JoinState, in button: JoinButton, with joinable: Joinable, _ completion: @escaping JoinStateCompletionBlock) {

        button.isLoading = false

        if oldState != newState {
            var object = joinable
            object.isJoined = newState.flag

            RateMe.shared.userDidPerformEvent()
        }

        completion(newState)
    }
}

extension ViewJoinable where Self: UIViewController {
    
    func registerJoinable() {
        ViewJoinableRegistry.shared.register(self)
    }

    func unregisterJoinable() {
        ViewJoinableRegistry.shared.unregister(self)
    }
}
