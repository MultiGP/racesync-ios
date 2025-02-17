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
        tableView.tableHeaderView = headerView
        tableView.tableFooterView = UIView()
        tableView.register(cellType: FormTableViewCell.self)

        let backgroundView = UIView()
        backgroundView.backgroundColor = Color.gray20
        tableView.backgroundView = backgroundView

        return tableView
    }()

    fileprivate lazy var headerView: UIView = {
        let view = UIView()

        let imageView = UIImageView(image: UIImage(named: "icn_settings_header"))
        view.addSubview(imageView)
        imageView.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalToSuperview().offset(-120)
        }

        UIView.addParallaxToView(imageView)

        return view
    }()

    fileprivate lazy var sections: [Section: [Row]] = {
        let resources: [Row] = [.trackLayouts, .buildGuide, .seasonRules, .visitStore]
        var about: [Row] = []
        var auth: [Row] = [.logout]

        if UIApplication.shared.supportsAlternateIcons {
            about += [.appicon]
        }
        about += [.submitFeedback, .joinBeta, .visitSite]

        if let user = APIServices.shared.myUser, user.isDevTeam {
            auth += [.switchEnv] //, .featureFlags
        }

        return [.resources: resources, .about: about, .auth: auth]
    }()

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

        title = "Settings"

        let closeBtn = UIBarButtonItem(image: ButtonImg.close, style: .done, target: self, action: #selector(didPressCloseButton))
        navigationItem.leftBarButtonItem = closeBtn

        setupLayout()
    }

    override func viewWillAppear(_ animated: Bool) {

        tableView.reloadData()

        super.viewWillAppear(animated)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    // MARK: - Layout

    fileprivate func setupLayout() {

        view.addSubview(tableView)
        tableView.snp.makeConstraints {
            $0.top.leading.trailing.bottom.equalToSuperview()
        }
    }

    // MARK: - Actions

    @objc func didPressCloseButton() {
        dismiss(animated: true)
    }

    fileprivate func logout() {
        ActionSheetUtil.presentDestructiveActionSheet(withTitle: "Are you sure you want to log out?", destructiveTitle: "Yes, log out", completion: { (action) in
            ApplicationControl.shared.logout(forced: true)
        }, cancel: nil)
    }

    fileprivate func switchEnvironment() {
        // inverted environment
        let environment = nextEnvironment()

        ActionSheetUtil.presentDestructiveActionSheet(withTitle: "Are you sure you want to switch to \(environment.title)?", destructiveTitle: "Yes, switch", completion: { (action) in
            ApplicationControl.shared.logout(switchTo: environment)
        }, cancel: nil)
    }

    fileprivate func showFeatureFlags() {
        Clog.log("showFeatureFlags")
    }
}

extension SettingsViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let section = Section(rawValue: indexPath.section), let row = sections[section]?[indexPath.row] else { return }

        switch row {
        case .trackLayouts:
            let vc = TrackListViewController()
            vc.title = row.title
            navigationController?.pushViewController(vc, animated: true)
        case .buildGuide:
            WebViewController.openUrl(AppWebConstants.courseObstaclesDoc)
        case .seasonRules:
            WebViewController.openUrl(AppWebConstants.seasonRulesDoc)
        case .visitStore:
            WebViewController.openUrl(AppWebConstants.shop)
        case .appicon:
            let vc = AppIconViewController()
            vc.title = row.title
            navigationController?.pushViewController(vc, animated: true)
        case .submitFeedback:
            guard let url = AppWebConstants.getPrefilledFeedbackFormUrl() else { return }
            WebViewController.openUrl(url)
        case .joinBeta:
            WebViewController.openUrl(AppWebConstants.betaSignup)
        case .visitSite:
            WebViewController.openUrl(AppWebConstants.homepage)
        case .logout:
            logout()
        case .switchEnv:
            switchEnvironment()
        case .featureFlags:
            showFeatureFlags()
        }

        tableView.deselectRow(at: indexPath, animated: true)
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection sectionIdx: Int) -> String? {
        guard let section = Section(rawValue: sectionIdx) else { return nil }
        return section.title
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

        guard let section = Section(rawValue: indexPath.section), let rows = sections[section] else { return cell }
        let row = rows[indexPath.row]

        cell.textLabel?.text = row.title
        cell.textLabel?.textColor = Color.black
        cell.detailTextLabel?.text = nil
        cell.imageView?.image = UIImage.init(named: row.imageName)
        cell.accessoryType = .disclosureIndicator

        if row == .appicon {
            let icon = AppIconManager.selectedIcon()
            cell.detailTextLabel?.text = icon.title
        } else if row == .submitFeedback {
            cell.detailTextLabel?.text = "\(Bundle.main.releaseDescriptionPretty)"
        } else if row == .joinBeta {
            cell.detailTextLabel?.text = "Testflight"
        } else if row == .logout {
            cell.detailTextLabel?.text = APISessionManager.getSessionEmail()
        } else if row == .switchEnv {
            cell.detailTextLabel?.text = nextEnvironment().title
        }

        return cell
    }

    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if let section = Section(rawValue: section), section == .auth {
            return StringConstants.copyright
        } else {
            return nil
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return Constants.cellHeight
    }
}

fileprivate enum Section: Int, EnumTitle {
    case resources, about, auth

    var title: String {
        switch self {
        case .resources:    return "Resources"
        case .about:        return "About"
        case .auth:         return ""
        }
    }
}

fileprivate enum Row: Int, EnumTitle {
    case trackLayouts
    case buildGuide
    case seasonRules
    case appicon
    case submitFeedback
    case joinBeta
    case visitStore
    case visitSite
    case logout
    case featureFlags
    case switchEnv

    var title: String {
        switch self {
        case .trackLayouts:         return "MultiGP Track Designs"
        case .buildGuide:           return "Obstacles Build Guide"
        case .seasonRules:          return "MultiGP Rule Books"
        case .visitStore:           return "Visit the MultiGP Shop"
        case .appicon:              return "App Icon"
        case .submitFeedback:       return "Send Feedback"
        case .joinBeta:             return "Join the Beta"
        case .visitSite:            return "Go to MultiGP.com"
        case .logout:               return "Logout"
        case .featureFlags:         return "Feature Flags"
        case .switchEnv:            return "Switch to"
        }
    }

    // For including icons to each row. Look for icons at https://thenounproject.com/
    var imageName: String {
        switch self {
        case .trackLayouts:         return "icn_settings_tracks"
        case .buildGuide:           return "icn_settings_buildguide"
        case .seasonRules:          return "icn_settings_handbook"
        case .visitStore:           return "icn_settings_store"
        case .appicon:              return "icn_settings_appicn"
        case .submitFeedback:       return "icn_settings_feedback"
        case .joinBeta:             return "icn_settings_beta"
        case .visitSite:            return "icn_settings_mgp"
        case .logout:               return "icn_settings_logout"
        case .featureFlags:         return "icn_settings_logout"
        case .switchEnv:            return "icn_settings_logout"
        }
    }
}
