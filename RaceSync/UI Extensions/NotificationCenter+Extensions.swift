//
//  NSNotificationCenter+Extensions.swift
//  RaceSync
//
//  Created by Ignacio Romero Zurbuchen on 2025-09-08.
//  Copyright © 2025 MultiGP Inc. All rights reserved.
//

import Foundation

typealias NotificationBlock = (Notification) -> Void

extension NotificationCenter {

    @discardableResult
    func addObserver(with name: NSNotification.Name?, object obj: Any? = nil, queue: OperationQueue? = nil, block: @escaping NotificationBlock) -> NSObjectProtocol {
        return self.addObserver(forName: name, object: obj, queue: queue, using: block)
    }
}
