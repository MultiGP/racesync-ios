//
//  ViewApprovable.swift
//  RaceSync
//
//  Created by Ignacio Romero Zurbuchen on 2026-04-11.
//  Copyright © 2026 MultiGP Inc. All rights reserved.
//

import UIKit
import RaceSyncAPI

public typealias ApproveStateCompletionBlock = (_ state: ApproveState) -> Void

public protocol Approvable {
    var id: ObjectId { get }
    var isApproved: Bool { get set }
}

extension Series: Approvable { }
extension Race: Approvable { }

public enum ApproveState: Equatable {
    case notApproved, approved

    var title: String {
        switch self {
        case .notApproved:    return "Approve"
        case .approved:       return "Unapprove"
        }
    }

    var flag: Bool {
        switch self {
        case .approved:     return true
        default:            return false
        }
    }

    public static func == (lhs: ApproveState, rhs: ApproveState) -> Bool {
        switch (lhs, rhs) {
        case (.notApproved, .notApproved),
             (.approved, .approved):
            return true
        default:
            return false
        }
    }
}
