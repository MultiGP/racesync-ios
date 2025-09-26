//
//  SeriesViewModel.swift
//  RaceSync
//
//  Created by Ignacio Romero Zurbuchen on 2025-09-25.
//  Copyright © 2025 MultiGP Inc. All rights reserved.
//

import Foundation
import RaceSyncAPI

class SeriesViewModel: Descriptable {

    let series: Series

    let titleLabel: String
    let subtitleLabel: String
    let dateLabel: String
    let typeLabel: String
    let raceCount: Int
    let pilotCount: Int

    // MARK: - Initialization

    init(with series: Series) {
        self.series = series
        self.titleLabel = series.name
        self.dateLabel = Self.dateLabelString(for: series.startDate) // 14/09/2024
        self.typeLabel = series.typeString
        self.subtitleLabel = "\(self.typeLabel) | Started: \(self.dateLabel)"

        self.raceCount = Int(series.raceApprovedCount)
        self.pilotCount = Int(series.pilotCount)
    }

    static func viewModels(with objects:[Series]) -> [SeriesViewModel] {
        var viewModels = [SeriesViewModel]()
        for object in objects {
            viewModels.append(SeriesViewModel(with: object))
        }
        return viewModels
    }
}

extension SeriesViewModel {

    static func dateLabelString(for date: Date?) -> String {
        guard let date = date else { return "" }
        return DateUtil.isoDateFormatter.string(from: date)
    }
}
