//
//  PollingController.swift
//  RaceSync
//
//  Created by Ignacio Romero on 2026-08-01.
//  Copyright © 2026 MultiGP Inc. All rights reserved.
//

import Foundation
import RaceSyncAPI

/// Receives polling events and determines whether polling is currently allowed.
public protocol PollingControllerDelegate: AnyObject {
    /// Return `true` while the owner should continue polling.
    func isPollEnabled() -> Bool
    /// Called when the refresh interval has elapsed and polling is enabled.
    func polling()
}

/// Coordinates interval-based polling without knowing what work is being refreshed.
public class PollingController {

    // MARK: - Public Variables

    /// The web app does every 15 seconds but the mobile apps expectation is different
    public static let refreshInterval: TimeInterval = 12
    
    /// The object that supplies the polling state and handles refreshes.
    weak var delegate: PollingControllerDelegate?

    /// Starts interval-based polling when the delegate allows it.
    func start() {
        guard delegate?.isPollEnabled() == true, refreshTimer == nil else { return }

        refreshTimer = Timer.scheduledTimer(withTimeInterval: Self.refreshInterval, repeats: true) { [weak self] _ in
            self?.pollIfNeeded()
        }

        Clog.log("Starting polling")
    }

    /// Stops polling until `start()` is called again.
    func stop() {
        refreshTimer?.invalidate()
        refreshTimer = nil

        Clog.log("Stopping polling")
    }

    /// Immediately requests a refresh and defers the next scheduled callback.
    func pollNow() {
        guard delegate?.isPollEnabled() == true else { return }

        forward()
        delegate?.polling()
    }

    /// Defers the next polling callback by one refresh interval.
    func forward() {
        lastRefreshInterval = Date.timeIntervalSinceReferenceDate
    }

    /// Allows polling to resume on the next timer tick.
    func resume() {
        lastRefreshInterval = 0
    }
    
    // MARK: - Private Variables
    
    fileprivate var refreshTimer: Timer?
    fileprivate var lastRefreshInterval: TimeInterval = 0

    fileprivate func pollIfNeeded() {
        guard delegate?.isPollEnabled() == true,
              Date.timeIntervalSinceReferenceDate - lastRefreshInterval >= Self.refreshInterval else { return }

        delegate?.polling()
    }
    
    deinit {
        stop()
    }
}
