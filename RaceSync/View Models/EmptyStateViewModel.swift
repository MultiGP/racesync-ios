//
//  EmptyStateViewModel.swift
//  RaceSync
//
//  Created by Ignacio Romero Zurbuchen on 2020-01-20.
//  Copyright © 2020 MultiGP Inc. All rights reserved.
//

import UIKit
import RaceSyncAPI

protocol EmptyStateViewModelInterface {
    var title: NSAttributedString? { get }
    var description: NSAttributedString? { get }
    var image: UIImage? { get }
    var backgroundColor: UIColor? { get }

    func buttonTitle(_ state: UIControl.State) -> NSAttributedString?

    static func attributtedStringForTitle(_ string: String?) -> NSAttributedString?
    static func attributtedStringForDescription(_ string: String?) -> NSAttributedString?
    static func attributtedStringForButton(_ string: String?, state: UIControl.State) -> NSAttributedString?
}

enum EmptyState {
    case noRaces
    case noJoinedRaces
    case noNearbydRaces
    case noSeriesRaces
    case noRacePilots
    case noRaceResults
    case noRacePayments
    case noChapters
    case noChapterMembers

    case noSeries
    case noJoinedSeries
    case noSeriesResults
    case noProfileRaces
    case noProfileChapters
    case noMyProfileRaces
    case noMyProfileChapters

    case noPushMessages
    case noPushAuthorized
    case noPushEnabled

    case comingSoon

    case noSearchResults
    case errorChapters
    case errorUsers
    case error(_: NSError)
}

struct EmptyStateViewModel: EmptyStateViewModelInterface {

    var emptyState: EmptyState
    var isLoading = false

    init(_ emptyState: EmptyState) {
        self.emptyState = emptyState
    }

    var title: NSAttributedString? {

        var text: String?

        switch emptyState {
        case .noJoinedRaces, .noNearbydRaces:
            text = "No Races Found"
        case .noSeriesRaces:
            text = "No GQ Found"
        case .noRacePilots:
            text = "No Registered Pilots"
        case .noRaceResults:
            text = "No Race Results"
        case .noChapterMembers:
            text = "No Chapter Members"
        case .noRaces, .noMyProfileRaces, .noProfileRaces:
            text = "No Races Found"
        case .noSeries, .noJoinedSeries:
            text = "No Series Found"
        case .noSeriesResults:
            text = "No Series Results"
        case .noRacePayments:
            text = "No Race Payments"
        case .noChapters, .noMyProfileChapters, .noProfileChapters:
            text = "No Chapters"
        case .noPushMessages:
            text = "No Messages"
        case .noPushAuthorized:
            text = "Push Notifications"
        case .noPushEnabled:
            text = "Push Notifications Disabled"
        case .comingSoon:
            text = "Coming Soon"
        case .noSearchResults:
            text = "No Results"
        case .error( _):
            text = "Error"
        default:
            return nil
        }

        return Self.attributtedStringForTitle(text)
    }

    var description: NSAttributedString? {

        let settings = APIServices.shared.settings
        var text: String?

        switch emptyState {
        case .noRaces:
            text = "There are no races available yet."
        case .noJoinedRaces, .noMyProfileRaces:
            text = "You haven't joined any upcoming races yet."
        case .noSeriesRaces:
            text = "There are no \(Date().thisYear()) GQ races available just yet."
        case .noNearbydRaces:
            text = "There are no races available in a \(settings.searchRadius)\(settings.lengthUnit.symbol) radius."
        case .noRacePilots:
            text = "There are no registered pilots yet."
        case .noRaceResults:
            text = "There are no race results available just yet."
        case .noSeries, .noJoinedSeries:
            text = "There are no series available yet under this category."
        case .noSeriesResults:
            text = "There are no series results available just yet."
        case .noRacePayments:
            text = "No payments found yet, or a network error occurred."
        case .noChapterMembers:
            text = "There are no registered members yet."
        case .noProfileRaces:
            text = "This user hasn't joined any races yet."
        case .noProfileChapters:
            text = "This user hasn't joined any chapters yet."
        case .noMyProfileChapters:
            text = "You haven't joined any chapters yet."
        case .noPushMessages:
            text = "You don't have any messages yet."
        case .noPushAuthorized:
            text = "Want race updates sent to you?\nTurn on Push Notifications to stay updated!"
        case .noPushEnabled:
            text = "Please enable Push Notifications to continue."
        case .comingSoon:
            text = "This section is under development."
        case .error(let error):
            text = "\(error.localizedDescription)\nPlease try again later or report a bug."
        default:
            return nil
        }

        return Self.attributtedStringForDescription(text)
    }

    var image: UIImage? {
        return nil
    }

    func buttonTitle(_ state: UIControl.State) -> NSAttributedString? {

        var text: String?

        switch emptyState {
        case .noJoinedRaces:
            text = "Search Nearby Races"
        case .noRacePilots:
            text = "Join Race"
        case .noPushAuthorized:
            text = "Allow Push Notifications"
        case .noPushEnabled:
            text = "Open Settings"
        default:
            return nil
        }

        return Self.attributtedStringForButton(text, state: state)
    }

    var backgroundColor: UIColor? {
        return Color.white
    }

    static func attributtedStringForTitle(_ string: String?) -> NSAttributedString? {
        guard let string = string else { return nil }

        var attributes: [NSAttributedString.Key: Any] = [:]
        attributes[NSAttributedString.Key.font] = UIFont.boldSystemFont(ofSize: 25)
        attributes[NSAttributedString.Key.foregroundColor] = Color.gray200

        return NSAttributedString.init(string: string, attributes: attributes)
    }

    static func attributtedStringForDescription(_ string: String?) -> NSAttributedString? {
        guard let string = string else { return nil }

        var attributes: [NSAttributedString.Key: Any] = [:]
        attributes[NSAttributedString.Key.font] = UIFont.systemFont(ofSize: 19)
        attributes[NSAttributedString.Key.foregroundColor] = Color.gray200

        return NSAttributedString.init(string: string, attributes: attributes)
    }

    static func attributtedStringForButton(_ string: String?, state: UIControl.State) -> NSAttributedString? {
        guard let string = string else { return nil }

        var attributes: [NSAttributedString.Key: Any] = [:]
        attributes[NSAttributedString.Key.font] = UIFont.boldSystemFont(ofSize: 19)

        if state == .highlighted {
            attributes[NSAttributedString.Key.foregroundColor] = Color.blue.withAlphaComponent(0.5)
        } else {
            attributes[NSAttributedString.Key.foregroundColor] = Color.blue
        }

        return NSAttributedString.init(string: string, attributes: attributes)
    }
}
