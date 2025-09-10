//
//  Race+Extensions.swift
//  RaceSyncAPI
//
//  Created by Ignacio Romero Zurbuchen on 2020-02-28.
//  Copyright © 2020 MultiGP Inc. All rights reserved.
//

import Foundation

public extension Race {

    var isMyChapter: Bool {
        guard let managedChapters = APIServices.shared.myManagedChapters else { return false }
        let chapterIds = managedChapters.compactMap { $0.id }
        return chapterIds.contains(chapterId)
    }

    var canBeEdited: Bool {
        guard isMyChapter else { return false }
        return true
    }

    var canChangeEnrollment: Bool {
        guard isMyChapter else { return false }
        return !isFinalized
    }

    var canBeDuplicated: Bool {
        guard isMyChapter else { return false }
        guard raceType == .normal else { return false }
        return true
    }

    var canBeDeleted: Bool {
        guard isMyChapter else { return false }
        guard ownerId == APIServices.shared.myUser?.id else { return false }
        return true
    }

    var canBeFinalized: Bool {
        guard isMyChapter else { return false }
        guard ownerId == APIServices.shared.myUser?.id else { return false }
        guard let startDate = startDate, startDate.isPassed else { return false }
        return !isFinalized
    }

    var isGQ: Bool {
        guard raceType == .qualifier else { return false }
        return true
    }

    var trueScoringFormat: ScoringFormat {
        return isGQ ? .fastest3Laps : scoringFormat
    }

    var isZippyQEnabled: Bool {
        return (maxZippyqDepth > 0 && disableSlotAutoPopulation == .open)
    }
}

// MARK: - Payments

public extension Race {

    var isPayable: Bool {
        return fee > 0 && amountPaid == 0
    }

    var isPaid: Bool {
        return fee > 0 && amountPaid > 0
    }

    var requiresPayment: Bool {
        return !isPaid && isPaymentRequiredToJoin
    }

    var canManagePayments: Bool {
        return fee > 0 && isMyChapter
    }

    func getMyPaymentUrl() -> URL? {
        guard let myUser = APIServices.shared.myUser else { return nil }

        let baseUrl = MGPWeb.getUrl(for: .processPayment)
        let params: [(String, String)] = [
            ("raceId", "\(self.id)"),
            ("pilotId", "\(myUser.id)"),
            ("user-agent", "ios")
        ]

        var components = URLComponents(string: baseUrl)
        components?.queryItems = params.map { URLQueryItem(name: $0.0, value: $0.1) }

        return components?.url
    }
}
