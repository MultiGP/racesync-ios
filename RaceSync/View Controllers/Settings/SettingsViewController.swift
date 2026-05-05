//
//  SettingsViewController.swift
//  RaceSync
//
//  Created by Ignacio Romero Zurbuchen on 2020-01-18.
//  Copyright © 2020 MultiGP Inc. All rights reserved.
//

import UIKit
import SnapKit
import RaceSyncAPI
import Presentr

class SettingsViewController: UIViewController {

    // MARK: - Private Variables

   fileprivate lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.tableFooterView = UIView()
        tableView.register(cellType: FormTableViewCell.self)

        let backgroundView = UIView()
        backgroundView.backgroundColor = Color.gray20
        tableView.backgroundView = backgroundView

        return tableView
    }()

    fileprivate var sections = [Section: [Row]]()
    fileprivate let isDevModeEnabled: Bool = true
    fileprivate var isTogglingPush: Bool = false

    fileprivate func nextEnvironment() -> APIEnvironment {
        return APIServices.shared.settings.isDev ? APIEnvironment.prod : APIEnvironment.dev
    }

    fileprivate enum Constants {
        static let padding: CGFloat = UniversalConstants.padding
        static let cellHeight: CGFloat = 56
    }

    // MARK: - Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()

        configureNavigationItems()
        setupLayout()

        NotificationCenter.default.addObserver(self, selector: #selector(appDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handlePushMessageRegistration(_:)), name: .registeredForPushMessages, object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if sections.count == 0 {
            loadSections()
        } else {
            tableView.reloadData()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Layout

    fileprivate func setupLayout() {

        view.addSubview(tableView)
        tableView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(view.snp.bottom)
        }
    }

    fileprivate func configureNavigationItems() {
        title = "Settings"
        tabBarItem = UITabBarItem(title: title, image: SystemImg.gearshape, selectedImage: SystemImg.gearshapeFill)

        navigationItem.leftBarButtonItem = UIBarButtonItem(image: ButtonImg.close, style: .plain, target: self, action: #selector(didPressCloseButton))        
    }

    // MARK: - Actions

    func loadSections() {

        sections = {
            let resources: [Row] = [.buildGuide, .seasonRules, .visitSite]
            var auth: [Row] = [.logout]
            if let user = APIServices.shared.myUser, user.isDevTeam, isDevModeEnabled {
                auth += [.switchEnv]
            }

            var about: [Row] = [.feedback, .joinBeta, .viewProject]
            if UIApplication.shared.supportsAlternateIcons { about += [.appicon] }

            return [.notifications: [Row.notifications], .resources: resources, .about: about, .auth: auth]
       }()
    }

    @objc fileprivate func appDidBecomeActive() {
        resetTableViewForPushStatus()
    }

    @objc fileprivate func didPressCloseButton() {
        dismiss(animated: true)
    }

    fileprivate func togglePushNotifications() {
        guard !isTogglingPush else { return }

        let controller = PushMessagesController.shared

        if !controller.isPushNotificationsEnabled() {
            if (controller.authorizationStatus == .notDetermined || controller.authorizationStatus == .authorized) {
                controller.requestAuthorizationPushNotifications()
                isTogglingPush = true
            } else {
                AppControl.shared.openAppSettings()
            }
        } else {
            ActionSheetUtil.presentDestructiveActionSheet(withTitle: "Do you want to stop receiving push notifications?", destructiveTitle: "Yes, stop", completion: { (action) in
                self.isTogglingPush = true
                self.tableView.reloadData()

                controller.unregisterForPushNotifications(fromDevice: false) { status, error in
                    controller.store.removeAll() // clear all saved messages
                    self.resetTableViewForPushStatus()
                }

            }, cancel: nil)
        }
    }

    fileprivate func resetTableViewForPushStatus() {
        PushMessagesController.shared.refreshPushNotificationSettings { status in
            self.isTogglingPush = false
            self.tableView.reloadData()
        }
    }

    @objc fileprivate func handlePushMessageRegistration(_ notification: Notification)  {
        resetTableViewForPushStatus()
    }

    fileprivate func logout() {
        ActionSheetUtil.presentDestructiveActionSheet(withTitle: "Logout from RaceSync?", destructiveTitle: "Yes, log out", completion: { (action) in
            AppControl.shared.logout(forced: true)
        }, cancel: nil)
    }

    fileprivate func switchEnvironment() {
        // inverted environment
        let environment = nextEnvironment()

        ActionSheetUtil.presentDestructiveActionSheet(withTitle: "Switch to \(environment.title)?", destructiveTitle: "Yes, switch", completion: { (action) in
            AppControl.shared.logout(switchTo: environment)
        }, cancel: nil)
    }

    fileprivate func sendFeedback() {
        let subject = "RaceSync iOS Feedback"
        let email = StringConstants.supportEmail
        let device = UIDevice.current

        let diagnostics = """
        Device: \(device.model )
        OS: \(device.systemName ) \(device.systemVersion)
        App Version: \(Bundle.main.releaseDescriptionPretty)
        ***************************
        \n
        \n
        """
        
        guard let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return }
        guard let encodedBody = diagnostics.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return }
        guard let url = URL(string: "mailto:\(email)?subject=\(encodedSubject)&body=\(encodedBody)") else { return }

        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
}

extension SettingsViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) as? FormTableViewCell else { return }
        tableView.deselectRow(at: indexPath, animated: true)
        guard let section = Section(rawValue: indexPath.section), let row = sections[section]?[indexPath.row] else { return }

        switch row {
        case .notifications:
            togglePushNotifications()
            cell.isLoading = isTogglingPush
        case .tracksGuide:
            WebViewController.open(AppWebConstants.tracks)
        case .buildGuide:
            WebViewController.open(AppWebConstants.obstaclesDoc)
        case .seasonRules:
            WebViewController.open(AppWebConstants.seasonRulesDoc)
        case .appicon:
            let vc = AppIconViewController()
            vc.title = row.title
            navigationController?.pushViewController(vc, animated: true)
        case .joinBeta:
            WebViewController.open(AppWebConstants.testflight)
        case .viewProject:
            WebViewController.open(AppWebConstants.github)
        case .visitSite:
            WebViewController.open(AppWebConstants.homepage)
        case .logout:
            logout()
        case .switchEnv:
            switchEnvironment()
        case .feedback:
            sendFeedback()
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection sectionIdx: Int) -> String? {
        guard let section = Section(rawValue: sectionIdx) else { return nil }
        return section.title
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 30
    }

    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        guard let section = Section(rawValue: section) else { return nil }

        switch section {
        case .auth:     return "\(StringConstants.copyright)\n\(StringConstants.developedBy)"
        default:        return ""
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return Constants.cellHeight
    }
}

extension SettingsViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection sectionIdx: Int) -> Int {
        guard let section = Section(rawValue: sectionIdx), let rows = sections[section] else { return 0 }
        return rows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(forIndexPath: indexPath) as FormTableViewCell
        guard let section = Section(rawValue: indexPath.section), let row = sections[section]?[indexPath.row] else { return cell }

        cell.textLabel?.text = row.title
        cell.textLabel?.textColor = Color.black
        cell.detailTextLabel?.text = nil
        cell.imageView?.image = UIImage.init(named: row.imageName)
        cell.accessoryType = .disclosureIndicator
        cell.isLoading = false

        if row == .notifications {
            cell.detailTextLabel?.text = PushMessagesController.shared.isPushNotificationsEnabled() ? "Enabled" : "Disabled"
            cell.isLoading = isTogglingPush
        } else if row == .appicon {
            let icon = AppIconManager.selectedIcon()
            cell.detailTextLabel?.text = icon.title
        } else if row == .joinBeta {
            cell.detailTextLabel?.text = "Testflight"
        } else if row == .viewProject {
            cell.detailTextLabel?.text = "Github"
        } else if row == .logout {
            cell.detailTextLabel?.text = APISessionManager.getSessionEmail()
        } else if row == .switchEnv {
            cell.detailTextLabel?.text = nextEnvironment().title
        }
        return cell
    }
}

fileprivate enum Section: Int, EnumTitle {
    case notifications, resources, about, auth

    var title: String {
        switch self {
        case .notifications:    return ""
        case .resources:        return "Resources"
        case .about:            return "RaceSync iOS \(Bundle.main.releaseDescriptionPretty)"
        case .auth:             return ""
        }
    }
}

fileprivate enum Row: Int, EnumTitle {
    case notifications
    case tracksGuide
    case buildGuide
    case seasonRules
    case visitSite
    case feedback
    case joinBeta
    case viewProject
    case appicon
    case logout
    case switchEnv

    var title: String {
        switch self {
        case .notifications:        return "Push Notifications"
        case .tracksGuide:          return "MultiGP Tracks"
        case .buildGuide:           return "Obstacles Build Guide"
        case .seasonRules:          return "Season Rule Books"
        case .visitSite:            return "Visit MultiGP.com"
        case .feedback:             return "Share Feedback"
        case .joinBeta:             return "Join the Beta"
        case .viewProject:          return "View Project"
        case .appicon:              return "Change App Icon"
        case .logout:               return "Logout"
        case .switchEnv:            return "Switch to"
        }
    }

    // For including icons to each row. Look for icons at https://thenounproject.com/
    var imageName: String {
        switch self {
        case .notifications:        return "icn_settings_apns"
        case .tracksGuide:          return "icn_settings_tracks"
        case .buildGuide:           return "icn_settings_buildguide"
        case .seasonRules:          return "icn_settings_handbook"
        case .visitSite:            return "icn_settings_mgp"
        case .feedback:             return "icn_settings_feedback"
        case .joinBeta:             return "icn_settings_testflight"
        case .viewProject:          return "icn_settings_github"
        case .appicon:              return "icn_settings_appicn"
        case .logout:               return "icn_settings_logout"
        case .switchEnv:            return "icn_settings_logout"
        }
    }
}
