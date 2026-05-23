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
    var authApi = AuthApi()

    // MARK: - Private Variables

    fileprivate var deeplinkObserver: NSObjectProtocol?


    // MARK: - Initialization

    override init() {
        super.init()

        deeplinkObserver = NotificationCenter.default.addObserver(with: .joinedRaceViaDeeplink) { note in
            guard let deeplink = note.object as? DeepLink else { return }

            DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: { [weak self] in
                self?.handle(deeplink)
            })
        }
    }

    deinit {
        // Add more observers to collections instead of variables?
        if let observer = deeplinkObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    // MARK: - Public Methods

    static func initializeRaceSyncAPI() {

        // This was moved to the main Bundle, but it will break whenever the API framework is used on another bundle
        let path = Bundle.main.path(forResource: "credentials", ofType: "plist")
        let dict = NSDictionary(contentsOfFile: path ?? "")

        guard let key = dict?["API_KEY"] as? String else {
            fatalError("API key missing from credentials.plist")
        }

#if DEBUG
        // Used for auto-completing in the login screen
        let email = dict?["EMAIL"] as? String ?? ""
        let password = dict?["PASSWORD"] as? String ?? ""
#else
        let email = APISessionManager.getSessionEmail() ?? ""
        let password = APISessionManager.getSessionPasword() ?? ""
#endif

        let credential = APICredential(apiKey: key, email: email, password: password)
        APIServices.configure(with: credential)
    }

    func invalidateSession(forced: Bool = false) {
        guard let window = UIApplication.shared.delegate?.window else { return }

        if forced {
            APISessionManager.invalidateSession()
            APIServices.shared.credential.invalidateLogin()
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

            APIServices.shared.settings.environment = environment

            // The authAPI must be resetted, in case we switched environments (prod, dev)
            self?.authApi = AuthApi()
        }
    }

    func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}

// MARK: - Race API Methods
// TODO: Maybe move all this stateless implementation to a separate class?

extension ApplicationControl {

    func tryJoining(race: Race, raceApi: RaceApi, _ completion: @escaping JoinStateCompletionBlock) {

        if race.requiresPayment || (race.isJoined && race.isPayable)  {
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
                                                  okTitle: "Pay Now",
                                                  cancelTitle: "Later",
                                                  delay: 0.5) { action in
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

        WebViewController.open(url, style: .formSheet) {
            // return the original state for now
            let state = RaceViewModel.joinState(for: race)
            completion(state)
        }
    }

    // Use this method to know if a specific deep link is supported or not
    func canHandleDeepLink(_ link: DeepLink) -> Bool  {

        if link.isRace {
            if link.action == .view, let _ = link.parameters[ParamKey.id] {
                return true
            } else if link.action == .join {
                return true
            }
        }
        return false
    }

    func handle(_ link: DeepLink)  {

        if link.isRace {
            if link.action == .view, let raceId = link.parameters[ParamKey.id]  {
                if let nc = UIViewController.topMostViewController() as? NavigationController {

                    let vc = RaceTabBarController(with: raceId)
                    vc.hidesBottomBarWhenPushed = true
                    nc.pushViewController(vc, animated: true)
                }
            }
            else if link.action == .join  {
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
