//
//  SeriesResultViewModel.swift
//  RaceSync
//
//  Created by Ignacio Romero Zurbuchen on 2026-04-15.
//  Copyright © 2026 MultiGP Inc. All rights reserved.
//

import Foundation
import RaceSyncAPI

class SeriesResultViewModel: Descriptable {

    let pilotId: String?
    let chapterId: String?
    let type: SeriesResultType

    let titleLabel: String
    let subtitleLabel: String
    let scoreLabel: String
    let imageUrl: String?

    static let emptyLabel: String = "--"

    // MARK: - Initialization

    init(with result: SeriesResult, scoreType: SeriesScore) {
        self.pilotId = result.pilotId
        self.chapterId = result.chapterId
        self.type = result.type

        self.titleLabel = ViewModelHelper.titleLabel(for: result.displayName, country: result.country)
        self.imageUrl = Self.imageUrl(for: result)

        if scoreType == .fastest3laps {
            if let time = result.time {
                self.subtitleLabel = "\(TimeUtil.lapTimeFormat(seconds: time))"
            } else {
                self.subtitleLabel = Self.emptyLabel
            }
            self.scoreLabel = ""
        }
        else if scoreType == .collegiate {

            var labels = [String]()
            if result.type == .pilot, let time = result.time {
                labels += ["\(TimeUtil.lapTimeFormat(seconds: time))"]
            }
            else if result.type == .chapter, let best = result.bestResults {
                labels += ["Best: [\(best.map { String(format: "%g", $0) }.joined(separator: ", "))]"]
            }

            if labels.count > 0 {
                self.subtitleLabel = labels.joined(separator: "  |  ")
            } else {
                self.subtitleLabel = Self.emptyLabel
            }

            if result.score > 0 {
                let str = String(describing: result.score)
                let decimals = str.components(separatedBy: ".").last?.count ?? 0
                self.scoreLabel = decimals > 3 ? String(format: "%.3f", Double(str) ?? 0).replacingOccurrences(of: #"\.?0+$"#, with: "", options: .regularExpression) : str
            } else {
                self.scoreLabel = ""
            }
        }
        else {
            var labels = [String]()
            if result.raceCount > 0 {
                labels += ["Races: \(result.raceCount)"]
            }
            if result.type == .pilot {
                labels += ["Elo: \(result.eloScore)"]
            }
            self.subtitleLabel = labels.joined(separator: "  |  ")

            let unit = (result.score == 1) ? "pt" : "pts"
            self.scoreLabel = "\(String(format: "%.0f", result.score)) \(unit)"
        }
    }

    static func viewModels(with objects: [SeriesResult]?, scoreType: SeriesScore) -> [SeriesResultViewModel] {
        var viewModels = [SeriesResultViewModel]()

        if let objects = objects {
            for object in objects {
                viewModels.append(SeriesResultViewModel(with: object, scoreType: scoreType))
            }
        }
        return viewModels
    }
}

extension SeriesResultViewModel {

    static func imageUrl(for result: SeriesResult) -> String? {
        if let url = result.profileImageUrl {
            return url
        } else {
            return result.mainImageUrl
        }
    }
}
