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

protocol ViewJoinable {
    func toggleJoinButton(_ button: JoinButton, forRace race: Race, raceApi: RaceApi, _ completion: @escaping JoinStateCompletionBlock)
    func toggleJoinButton(_ button: JoinButton, forChapter chapter: Chapter, chapterApi: ChapterApi, _ completion: @escaping JoinStateCompletionBlock)
}

public enum JoinState {
    case notJoined, joined, joinedPaid, closed

    var title: String {
        switch self {
        case .notJoined:    return "Join"
        case .joined:       return "Joined"
        case .joinedPaid:   return "Paid"
        case .closed:       return "Closed"
        }
    }

    var flag: Bool {
        if self == .notJoined { return true }
        return false
    }
}

extension ViewJoinable {

    func toggleJoinButton(_ button: JoinButton, forRace race: Race, raceApi: RaceApi, _ completion: @escaping JoinStateCompletionBlock) {

        button.isLoading = true
        let state = button.joinState

        if state == .notJoined {
            if let endDate = race.endDate, endDate.isPassed {
                AlertUtil.presentAlertMessage("Cannot join a passed race.",
                                              title: "Uh Oh",
                                              delay: 0.5,
                                              completion: { _ in button.isLoading = false })
            } else {
                join(race: race, raceApi: raceApi) { (newState) in
                    self.handleStateChange(state, newState: newState, in: button, with: race, completion)
                }
            }
        } else if state == .joined {
            resign(race: race, raceApi: raceApi) { (newState) in
                self.handleStateChange(state, newState: newState, in: button, with: race, completion)
            }
        }
    }

    func toggleJoinButton(_ button: JoinButton, forChapter chapter: Chapter, chapterApi: ChapterApi, _ completion: @escaping JoinStateCompletionBlock) {

        button.isLoading = true
        let state = button.joinState

        if state == .joined {
            resign(chapter: chapter, chapterApi: chapterApi) { (newState) in
                self.handleStateChange(state, newState: newState, in: button, with: chapter, completion)
            }

        } else if state == .notJoined  {
            join(chapter: chapter, chapterApi: chapterApi) { (newState) in
                self.handleStateChange(state, newState: newState, in: button, with: chapter, completion)
            }
        }
    }

    fileprivate func handleStateChange(_ oldState: JoinState, newState: JoinState, in button: JoinButton, with joinable: Joinable, _ completion: @escaping JoinStateCompletionBlock) {
        if oldState != newState {
            var object = joinable
            object.isJoined = newState.flag
            button.joinState = newState

            RateMe.shared.userDidPerformEvent()
        }

        button.isLoading = false
        completion(newState)
    }
}

// MARK: - Races

extension ViewJoinable {

    func join(race: Race, raceApi: RaceApi, _ completion: @escaping JoinStateCompletionBlock) {

        if race.requiresPayment, let url = race.getMyPaymentUrl()  {

//            AlertUtil.presentAlertMessage("", title: <#T##String?#>, buttonTitle: "Go Paym,en", delay: <#T##TimeInterval#>, completion: <#T##AlertCompletionBlock?#>)

            WebViewController.openURL(url)
        } else {
            handleJoiningRace()
        }

        func handleJoiningRace() {
            raceApi.join(race: race.id) { (status, error) in
                if status == true {
                    completion(.joined)

                    raceApi.checkIn(race: race.id) { (raceEntry, error) in
                        // when joining a race, we checkin to get a frequency assigned
                    }
                } else if let error = error {
                    completion(.notJoined)
                    AlertUtil.presentAlertMessage("Couldn't join this race. Please try again later. \(error.localizedDescription)", title: "Error", delay: 0.5)
                } else {
                    completion(.notJoined)
                }
            }
        }
    }

    func resign(race: Race, raceApi: RaceApi, _ completion: @escaping JoinStateCompletionBlock) {

        ActionSheetUtil.presentDestructiveActionSheet(withTitle: "Resign from this race?",
                                                      destructiveTitle: "Yes, Resign",
                                                      completion: { (action) in
                                                        raceApi.resign(race: race.id) { (status, error) in
                                                            if status == true {
                                                                completion(.notJoined)
                                                            } else {
                                                                completion(.joined)
                                                                AlertUtil.presentAlertMessage("Couldn't resign from this race. Please try again later.", title: "Error", delay: 0.5)
                                                            }
                                                        }
        }) { (action) in
            completion(.joined)
        }
    }
}

// MARK: - Chapters

extension ViewJoinable {

    func join(chapter: Chapter, chapterApi: ChapterApi, _ completion: @escaping JoinStateCompletionBlock) {

        chapterApi.join(chapter: chapter.id) { (status, error) in
            if status == true {
                completion(.joined)
            } else if let error = error {
                completion(.notJoined)
                AlertUtil.presentAlertMessage("Couldn't join this chapter. Please try again later. \(error.localizedDescription)", title: "Error", delay: 0.5)
            } else {
                completion(.notJoined)
            }
        }
    }

    func resign(chapter: Chapter, chapterApi: ChapterApi, _ completion: @escaping JoinStateCompletionBlock) {

        ActionSheetUtil.presentDestructiveActionSheet(withTitle: "Leave this chapter?",
                                                      destructiveTitle: "Yes, Leave",
                                                      completion: { (action) in
                                                        chapterApi.resign(chapter: chapter.id) { (status, error) in
                                                            if status == true {
                                                                completion(.notJoined)
                                                            } else {
                                                                completion(.joined)
                                                                AlertUtil.presentAlertMessage("Couldn't leave this chapter. Please try again later.", title: "Error", delay: 0.5)
                                                            }
                                                        }
        }) { (action) in
            completion(.joined)
        }
    }
}
