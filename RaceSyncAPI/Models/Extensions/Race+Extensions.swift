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
        return true
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
}
