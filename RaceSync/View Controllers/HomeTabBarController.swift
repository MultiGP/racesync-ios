//
//  HomeTabBarController.swift
//  RaceSync
//
//  Created by Ignacio Romero Zurbuchen on 2025-05-31.
//  Copyright © 2025 MultiGP Inc. All rights reserved.
//

import UIKit
import SnapKit
import RaceSyncAPI

enum HomeTabs: Int {
    case races, standings, series
    
    static let `default`: Self = .standings
}

class HomeTabBarController: UITabBarController {

    // MARK: - Private Variables

    fileprivate lazy var raceFeedVC: RaceFeedViewController = {
        let settings = APIServices.shared.settings
        let filters = settings.raceFeedFilters
        return RaceFeedViewController(filters, selectedFilter: filters.first!)
    }()

    fileprivate lazy var seriesVC: SeriesFeedViewController = {
        return SeriesFeedViewController()
    }()

    fileprivate lazy var standingsVC: StandingsViewController = {
        let vc = StandingsViewController(with: .y2026)
        vc.title = "Standings"
        vc.tabBarItem = UITabBarItem(title: vc.title, image: SystemImg.trophy, selectedImage: SystemImg.trophyFill)
        vc.isRootTabBar = true
        return vc
    }()

    fileprivate lazy var titleView: UIView = {
        let view = UIView()
        let imageView = UIImageView(image: LogoImg.header)
        view.addSubview(imageView)
        imageView.snp.makeConstraints {
            $0.centerX.centerY.equalToSuperview()
        }
        return view
    }()

    fileprivate lazy var notificationsButton: CustomButton = {
        let button = CustomButton(type: .system)
        button.addTarget(self, action: #selector(didPressNotificationsButton), for: .touchUpInside)
        button.setImage(ButtonImg.notifications, for: .normal)
        return button
    }()

    fileprivate lazy var settingsButton: CustomButton = {
        let button = CustomButton(type: .system)
        button.addTarget(self, action: #selector(didPressSettingsButton), for: .touchUpInside)
        button.setImage(ButtonImg.settings, for: .normal)
        return button
    }()

    fileprivate lazy var userProfileButton: UIButton = {
        let button = UIButton(type: .system)
        button.addTarget(self, action: #selector(didPressUserProfileButton), for: .touchUpInside)
        button.isHidden = true

        if let placeholder = PlaceholderImg.small?.withRenderingMode(.alwaysOriginal) {
            button.setImage(placeholder, for: .normal) // 32x32
            button.layer.cornerRadius = placeholder.size.width / 2
            button.layer.borderWidth = 0.5
            button.layer.borderColor = Color.gray100.cgColor
            button.layer.masksToBounds = true
        }
        return button
    }()

    fileprivate lazy var chapterProfileButton: CustomButton = {
        let button = CustomButton(type: .system)
        button.addTarget(self, action: #selector(didPressChapterProfileButton), for: .touchUpInside)
        button.addTarget(self, action: #selector(didLongPressChapterProfileButton), for: .touchLong)
        button.isHidden = true

        if let placeholder = PlaceholderImg.small?.withRenderingMode(.alwaysOriginal) {
            button.setImage(placeholder, for: .normal) // 32x32
            button.layer.cornerRadius = placeholder.size.width / 2
            button.layer.borderWidth = 0.5
            button.layer.borderColor = Color.gray100.cgColor
            button.layer.masksToBounds = true
        }
        return button
    }()

    fileprivate lazy var badgeHub: BadgeHub = {
        let hub = BadgeHub(view: notificationsButton)
        hub.setCircleColor(Color.lightRed, label: Color.white)
        hub.setCircleBorderColor(Color.white, borderWidth: 1)
        hub.setMaxCount(to: 100)
        hub.scaleCircleSize(by: 0.7)
        hub.moveCircleBy(x: 35.0, y: 0)
        return hub
    }()

    fileprivate let presenter = Appearance.defaultPresenter()
    fileprivate let userApi = UserApi()
    fileprivate let chapterApi = ChapterApi()

    fileprivate let hidesNavigationShadowAtRoot: Bool = true

    fileprivate enum Constants {
        static let padding: CGFloat = UniversalConstants.padding
        static let buttonSpacing: CGFloat = 12
        static let miniProfileSize: CGSize = CGSize(width: 32, height: 32)
    }

    // MARK: - Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()

        setupLayout()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        loadContent()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if hidesNavigationShadowAtRoot {
            hideNavigationShadow()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if let nc = navigationController, nc.viewControllers.count == 2 {
            if hidesNavigationShadowAtRoot {
                hideNavigationShadow(false)
            }
        }
    }

    // MARK: - Layout

    fileprivate func setupLayout() {
        delegate = self
        configureNavigationItems()
    }

    fileprivate func configureNavigationItems() {

        navigationItem.titleView = titleView

        let leftStackSubviews = [notificationsButton, settingsButton]
        let leftStackView = UIStackView(arrangedSubviews: leftStackSubviews)
        leftStackView.axis = .horizontal
        leftStackView.distribution = .fillEqually
        leftStackView.alignment = .leading
        leftStackView.spacing = Constants.padding
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: leftStackView)

        let rightStackView = UIStackView(arrangedSubviews: [chapterProfileButton, userProfileButton])
        rightStackView.axis = .horizontal
        rightStackView.distribution = .fillEqually
        rightStackView.alignment = .trailing
        rightStackView.spacing = Constants.buttonSpacing
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: rightStackView)
    }

    // MARK: - Actions

    @objc fileprivate func didPressUserProfileButton() {
        guard let myUser = APIServices.shared.myUser else { return }

        let vc = UserViewController(with: myUser)
        let nc = NavigationController(rootViewController: vc)
        nc.modalPresentationStyle = .fullScreen
        present(nc, animated: true)
    }

    @objc fileprivate func didPressChapterProfileButton() {
        guard let myChapter = APIServices.shared.myChapter else { return }

        let vc = ChapterViewController(with: myChapter)
        let nc = NavigationController(rootViewController: vc)
        nc.modalPresentationStyle = .fullScreen
        present(nc, animated: true)
    }

    @objc fileprivate func didLongPressChapterProfileButton() {

        let vc = ChapterPickerViewController()
        vc.title = "Change Home Chapter"
        vc.delegate = self

        let nc = NavigationController(rootViewController: vc)
        customPresentViewController(presenter, viewController: nc, animated: true)
    }

    @objc fileprivate func didPressNotificationsButton(_ sender: Any) {
        let vc = PushMessagesViewController()
        let nc = NavigationController(rootViewController: vc)
        present(nc, animated: true)
    }

    @objc fileprivate func didPressSettingsButton(_ sender: Any) {
        let vc = SettingsViewController()
        let nc = NavigationController(rootViewController: vc)
        present(nc, animated: true)
    }

    // MARK: - Data Update

    fileprivate func loadContent() {
        let vcs: [UIViewController] = [raceFeedVC, seriesVC, standingsVC]
        let idx = AppPrefs.lastSelectedTab

        configureTabBarController(with: vcs, selectedIndex: idx)

        if APIServices.shared.myUser == nil {
            loadMyUser()
        }
    }

    fileprivate func loadMyUser() {
        userApi.getMyUser { [weak self] (user, error) in
            if let user = user {
                // Load content only if it's the current tab
                if self?.selectedIndex == HomeTabs.races.rawValue {
                    self?.raceFeedVC.loadContent(forced: true)
                }

                self?.loadMyHomeChapter(user.homeChapterId)
                self?.loadMyManagedChapters()
                self?.updateUserProfileImage()
            } else if error != nil {
                // This is somewhat the best way to detect an invalid session
                AppControl.shared.invalidateSession(forced: false)
            }
        }
    }

    fileprivate func loadMyHomeChapter(_ chapterId: String) {
        guard !chapterId.isEmpty else { return }

        chapterApi.getChapter(with: chapterId) { [weak self] (chapter, error) in
            guard let chapter = chapter else { return }
            self?.updateMyHomeChapter(with: chapter)
        }
    }

    fileprivate func loadMyManagedChapters() {
        chapterApi.getMyManagedChapters { (managedChapters, error) in

            guard let chapters = managedChapters else {
                APIServices.shared.myManagedChapters = []
                return
            }

            // Remove duplicated managed chapters, if any, and sorting alphabetically
            let uniqueChapters = Dictionary(grouping: chapters, by: \.id)
                .compactMap { $0.value.first }
                .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }

            APIServices.shared.myManagedChapters = uniqueChapters
        }
    }

    fileprivate func updateUserProfileImage() {
        let imageUrl = APIServices.shared.myUser?.miniProfilePictureUrl
        let placeholder = PlaceholderImg.small?.withRenderingMode(.alwaysOriginal)

        userProfileButton.isHidden = false
        userProfileButton.setImage(with: imageUrl, placeholderImage: placeholder, forState: .normal, size: Constants.miniProfileSize) { (image) in
            //
        }
    }

    fileprivate func updateChapterProfileImage() {
        let imageUrl = APIServices.shared.myChapter?.miniProfilePictureUrl
        let placeholder = PlaceholderImg.small?.withRenderingMode(.alwaysOriginal)

        chapterProfileButton.isHidden = false
        chapterProfileButton.setImage(with: imageUrl, placeholderImage: placeholder, forState: .normal, size: Constants.miniProfileSize)
    }

    fileprivate func updateMyHomeChapter(with chapter: Chapter) {
        APIServices.shared.myChapter = chapter
        updateChapterProfileImage()
    }
}

extension HomeTabBarController: ChapterPickerViewControllerDelegate {

    func pickerController(_ viewController: ChapterPickerViewController, didPickChapter chapter: Chapter) {

        viewController.isLoading = true

        userApi.updateMyHomeChapter(with: chapter.id) { [weak self] user, error in
            if let user = user, user.homeChapterId == chapter.id {
                self?.updateMyHomeChapter(with: chapter)
                viewController.dismiss(animated: true)
            } else {
                viewController.isLoading = false
                Clog.log("Home Chapter Update error : \(error.debugDescription)")
            }
        }
    }
}

extension HomeTabBarController: UITabBarControllerDelegate {

    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {

        (tabBar as? RoundedSelectionTabBar)?.updateSelectionFrame(animated: true)

        if hidesNavigationShadowAtRoot, let vcs = viewControllers, vcs.contains(viewController) {
            hideNavigationShadow()
        } else {
            hideNavigationShadow(false)
        }

        if tabBarController.selectedViewController == viewController {
            // Notify the currently visible VC to scroll to top
            if let topVC = viewController as? ScrollToTop {
                topVC.scrollToTop()
            }
        }

        // To open the last tab at launch
        AppPrefs.lastSelectedTab = tabBarController.selectedIndex
    }
}
