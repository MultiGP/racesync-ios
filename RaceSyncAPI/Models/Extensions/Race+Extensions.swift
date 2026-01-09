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

    var canManagePilots: Bool {
        guard canBeEdited else { return false }
        return schedule != nil
    }

    var canChangeEnrollment: Bool {
        guard canBeEdited else { return false }
        return !isFinalized
    }

    var canBeDuplicated: Bool {
        guard canBeEdited else { return false }
        guard raceType == .normal else { return false }
        return true
    }

    var canBeDeleted: Bool {
        guard canBeEdited else { return false }
        guard ownerId == APIServices.shared.myUser?.id else { return false }
        return true
    }

    var canBeFinalized: Bool {
//        guard canBeEdited else { return false }
//        guard ownerId == APIServices.shared.myUser?.id else { return false }
//        guard let startDate = startDate, startDate.isPassed else { return false }
//        return !isFinalized

        // The API finalize(id) still returns 500 error. Reported https://github.com/MultiGP/multigp-com/issues/93
        return false
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
        return fee > 0 && amountPaid == 0 && isPaymentRequiredToJoin
    }

    var canManagePayments: Bool {
        return fee > 0 && isMyChapter
    }

    func getMyPaymentUrl() -> URL? {
        guard let myUser = APIServices.shared.myUser else { return nil }
        return RaceApi.getPaymentUrl(for: self.id, user: myUser.id)
    }
}
