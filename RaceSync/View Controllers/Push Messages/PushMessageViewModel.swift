//
//  PushMessageViewModel.swift
//  RaceSync
//
//  Created by Ignacio Romero Zurbuchen on 2025-05-20.
//  Copyright © 2025 MultiGP Inc. All rights reserved.
//

import UIKit
import RaceSyncAPI

class PushMessageViewModel: Descriptable {

    let message: PushMessage

    let titleLabel: String
    let detailLabel: String
    let dateLabel: String

    // MARK: - Initialization

    init(with message: PushMessage) {
        self.message = message
        self.titleLabel = (message.title.isEmpty) ? "New Message" : message.title
        self.detailLabel = message.detail
        self.dateLabel = Self.formatTimestamp(message.timestamp)
    }

    static func viewModels(with objects:[PushMessage]) -> [PushMessageViewModel] {
        var viewModels = [PushMessageViewModel]()
        for object in objects {
            viewModels.append(PushMessageViewModel(with: object))
        }
        return viewModels
    }
}

extension PushMessageViewModel {

    static func formatTimestamp(_ timestamp: TimeInterval) -> String {
        guard timestamp > 0 else { return "" }
        let date = Date(timeIntervalSince1970: timestamp.normalized)

        if date.isInToday {
            return DateUtil.displayTimeFormatter2.string(from: date) // just displaying time
        } else {
            return DateUtil.displayDateFormatter2.string(from: date)
        }
    }
}
