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

    fileprivate var authApi = AuthApi()
    fileprivate var deeplinkObserver: NSObjectProtocol?

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

        // clears all cached ViewJoinable objects
        ViewJoinableRegistry.shared.unregisterAll()
    }

    // Default environment value is based on the existing environment
    func logout(switchTo environment: APIEnvironment = APIServices.shared.settings.environment, forced: Bool = false) {

        // Unregister from push notifications, on the device and on the server
        PushMessagesController.shared.unregisterForPushNotifications { status, error in
            PushMessagesController.shared.store.removeAll() // clear all saved messages
        }

        authApi.logout { [weak self] (status, error) in

            // Invalidates the session, regardless if the logout call was successful or not
            self?.invalidateSession(forced: forced)

            // The authAPI must be resetted, in case we switched environments (prod, dev)
            self?.authApi = AuthApi()

            APIServices.shared.settings.environment = environment
        }
    }

    func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    override init() {
        super.init()

        deeplinkObserver = NotificationCenter.default.addObserver(with: .joinedRaceViaDeeplink) { note in
            guard let deeplink = note.object as? DeepLink else { return }

            DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: { [weak self] in
                self?.handleDeepLink(deeplink)
            })
        }
    }

    deinit {
        // Add more observers to collections instead of variables?
        if let observer = deeplinkObserver {
            NotificationCenter.default.removeObserver(observer)
        }
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
            join(race: race, raceApi: raceApi, completion)
        }
    }

    func join(race: Race, raceApi: RaceApi, _ completion: @escaping JoinStateCompletionBlock) {

        raceApi.join(race: race.id) { (status, error) in
            if status == true {
                completion(.joined)

                if race.isPayable {
                    AlertUtil.presentAlertMessage("This race has a fee of \(race.fee) USD. Would you like to pay it now?",
                                                  title: "Joined race!",
                                                  buttonTitle: "Pay Now", delay: 0.5) { action in
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: {
                            self.presentPayment(for: race, completion)
                        })
                    }
                }
            } else if let error = error {
                completion(.notJoined)
                AlertUtil.presentAlertMessage("\(error.localizedDescription)", title: "Error", delay: 0.5)
            } else {
                completion(.notJoined)
                AlertUtil.presentAlertMessage("Couldn't join this race. Please try again later.", title: "Error", delay: 0.5)
            }
        }
    }

    func resign(race: Race, raceApi: RaceApi, _ completion: @escaping JoinStateCompletionBlock) {

        let handler: AlertCompletionBlock = { _ in
            raceApi.resign(race: race.id) { (status, error) in
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

    fileprivate func handleDeepLink(_ deeplink: DeepLink)  {

        if deeplink.action == .join {
            // Makes sure to dismiss the payment webview, if still present
            if let webvc = UIViewController.topMostViewController(), webvc.isKind(of: WebViewController.self) {

                webvc.dismiss(animated: true)

                // force reloading the visible ViewJoinable
                // to reflect the updated state change.
                // TODO: Consider reactive join button states, to avoid heavylift reloads
                let joinables = ViewJoinableRegistry.shared.all()
                for vc in joinables {
                    vc.loadContent(forced: true)
                }
            }
        }
    }
}

// MARK: - Chapter API Methods

extension ApplicationControl {

    func join(chapter: Chapter, chapterApi: ChapterApi, _ completion: @escaping JoinStateCompletionBlock) {

        chapterApi.join(chapter: chapter.id) { (status, error) in
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

    func resign(chapter: Chapter, chapterApi: ChapterApi, _ completion: @escaping JoinStateCompletionBlock) {

        let handler: AlertCompletionBlock = { _ in
            chapterApi.resign(chapter: chapter.id) { (status, error) in
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
