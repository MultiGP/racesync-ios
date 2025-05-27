//
//  ApplicationControl.swift
//  RaceSync
//
//  Created by Ignacio Romero Zurbuchen on 2020-01-20.
//  Copyright © 2020 MultiGP Inc. All rights reserved.
//

import UIKit
import RaceSyncAPI
import QRCode

class ApplicationControl: NSObject {

    // MARK: - Public Variables

    static let shared = ApplicationControl()

    // MARK: - Private Variables

    fileprivate let authApi = AuthApi()

    // MARK: - Public Methods

    func invalidateSession(forced: Bool = false) {
        guard let window = UIApplication.shared.delegate?.window else { return }

        if forced {
            APISessionManager.invalidateSession()
        } else {
            APISessionManager.invalidateSessionId() // doesn't remove email & pwd
        }

        APIServices.shared.invalidate()

        // dismisses the presented view and displays the login screen view instead
        let rootViewController = window?.rootViewController
        rootViewController?.dismiss(animated: true)
    }

    // Default environment value is based on the existing environment
    func logout(switchTo environment: APIEnvironment = APIServices.shared.settings.environment, forced: Bool = false) {

        // Unregister from push notifications, on the device and on the server
        PushMessagesController.shared.unregisterForNotifications { status, error in
            PushMessagesController.shared.store.removeAll() // clear all saved messages
        }

        // Logs out from RaceSync and invalidates session
        authApi.logout { [weak self] (status, error) in
            if error == nil {
                self?.invalidateSession(forced: forced)
            }

            if status {
                APIServices.shared.settings.environment = environment
            }
        }
    }
}
