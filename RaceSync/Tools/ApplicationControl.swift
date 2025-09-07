//
//  ApplicationControl.swift
//  RaceSync
//
//  Created by Ignacio Romero Zurbuchen on 2020-01-20.
//  Copyright © 2020 MultiGP Inc. All rights reserved.
//

import UIKit
import RaceSyncAPI

typealias AppControl = ApplicationControl

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
        PushMessagesController.shared.unregisterForPushNotifications { status, error in
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

    func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    override init() {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(handleDeepLinkNotification(_:)), name: .joinedRaceViaDeeplink, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Race API Methods
// TODO: Maybe move all this stateless implementation to a separate class?

extension ApplicationControl {

    func tryJoining(race: Race, raceApi: RaceApi, _ completion: @escaping JoinStateCompletionBlock) {

        if race.requiresPayment  {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: {
                self.presentPayment(for: race, completion)
            })
        } else {
            join(race: race.id, raceApi: raceApi, completion)
        }
    }

    func join(race raceId: ObjectId, raceApi: RaceApi, _ completion: @escaping JoinStateCompletionBlock) {

        raceApi.join(race: raceId) { (status, error) in
            if status == true {
                completion(.joined)
            } else if let error = error {
                completion(.notJoined)
                AlertUtil.presentAlertMessage("\(error.localizedDescription)", title: "Error", delay: 0.5)
            } else {
                completion(.notJoined)
                AlertUtil.presentAlertMessage("Couldn't join this race. Please try again later.", title: "Error", delay: 0.5)
            }
        }
    }

    func resign(race raceId: ObjectId, raceApi: RaceApi, _ completion: @escaping JoinStateCompletionBlock) {

        let handler: AlertCompletionBlock = { _ in
            raceApi.resign(race: raceId) { (status, error) in
                if status == true {
                    completion(.notJoined)
                } else if let error = error {
                    completion(.joined)
                    AlertUtil.presentAlertMessage("\(error.localizedDescription)", title: "Error", delay: 0.5)
                } else {
                    completion(.joined)
                    AlertUtil.presentAlertMessage("Couldn't resign from this race. Please try again later.", title: "Error", delay: 0.5)
                }
            }
        }

        ActionSheetUtil.presentDestructiveActionSheet(
            withTitle: "Resign from this race?",
            destructiveTitle: "Yes, Resign",
            completion: handler,
            cancel: { _ in
                completion(.joined)
            }
        )
    }

    func presentPayment(for race: Race, _ completion: @escaping JoinStateCompletionBlock) {
        guard let url = race.getMyPaymentUrl() else { return }

        WebViewController.openURL(url, style: .formSheet) {
            // return the original state for now
            let state = RaceViewModel.joinState(for: race)
            completion(state)
        }
    }

    @objc fileprivate func handleDeepLinkNotification(_ notification: Notification)  {
        guard notification.object is DeepLink else { return }

        if notification.name == .joinedRaceViaDeeplink {
            if let webvc = UIViewController.topMostViewController(), webvc.isKind(of: WebViewController.self) {
                webvc.dismiss(animated: true)
            }
        }
    }
}

// MARK: - Chapter API Methods

extension ApplicationControl {

    func join(chapter chapterId: ObjectId, chapterApi: ChapterApi, _ completion: @escaping JoinStateCompletionBlock) {

        chapterApi.join(chapter: chapterId) { (status, error) in
            if status == true {
                completion(.joined)
            } else if let error = error {
                completion(.notJoined)
                AlertUtil.presentAlertMessage("\(error.localizedDescription)", title: "Error", delay: 0.5)
            } else {
                completion(.notJoined)
                AlertUtil.presentAlertMessage("Couldn't join this chapter. Please try again later.", title: "Error", delay: 0.5)
            }
        }
    }

    func resign(chapter chapterId: ObjectId, chapterApi: ChapterApi, _ completion: @escaping JoinStateCompletionBlock) {

        let handler: AlertCompletionBlock = { _ in
            chapterApi.resign(chapter: chapterId) { (status, error) in
                if status == true {
                    completion(.notJoined)
                } else if let error = error {
                    completion(.joined)
                    AlertUtil.presentAlertMessage("\(error.localizedDescription)", title: "Error", delay: 0.5)
                } else {
                    completion(.joined)
                    AlertUtil.presentAlertMessage("Couldn't leave this chapter. Please try again later.", title: "Error", delay: 0.5)
                }
            }
        }

        ActionSheetUtil.presentDestructiveActionSheet(
            withTitle: "Leave this chapter?",
            destructiveTitle: "Yes, Leave",
            completion: handler,
            cancel: { _ in
                completion(.joined)
            }
        )
    }
}
