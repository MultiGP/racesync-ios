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
    case races, series, standings, events
    static let `default`: Self = .series
}

class HomeTabBarController: UITabBarController {

    // MARK: - Private Variables
    
    fileprivate var isEventsTabEnable: Bool {
        get {
            // From May 22nd to June 16th
            return Date().isBetween(day: 22, month: 5, andDay: 16, month: 6)
        }
    }

    fileprivate lazy var raceFeedVC: RaceFeedViewController = {
        let settings = APIServices.shared.settings
        let filters = settings.raceFeedFilters
        let selectedFilter = AppPrefs.lastSelectedRaceFilter
        return RaceFeedViewController(filters, selectedFilter: selectedFilter)
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
    
    fileprivate lazy var eventsVC: EventsViewController = {
        return EventsViewController()
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

    fileprivate lazy var userProfileButton: UIButton = {
        let button = UIButton(type: .system)
        button.addTarget(self, action: #selector(didPressUserProfileButton), for: .touchUpInside)
        button.isHidden = true

        if let placeholder = PlaceholderImg.small?.withRenderingMode(.alwaysOriginal) {
            button.setImage(placeholder, for: .normal) // 32x32
            button.layer.cornerRadius = Constants.miniProfileSize.width / 2
            button.layer.cornerCurve = .continuous
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
            button.layer.cornerRadius = Constants.miniProfileSize.width / 2
            button.layer.cornerCurve = .continuous
            button.layer.borderWidth = 0.5
            button.layer.borderColor = Color.gray100.cgColor
            button.layer.masksToBounds = true
        }
        return button
    }()

//    fileprivate lazy var badgeHub: BadgeHub = {
//        let hub = BadgeHub(barButtonItem: notificationsButton)
//        hub.setCircleColor(Color.lightRed, label: Color.white)
//        hub.setCircleBorderColor(Color.white, borderWidth: 1)
//        hub.setMaxCount(to: 100)
//        hub.scaleCircleSize(by: 0.7)
//        hub.moveCircleBy(x: 35.0, y: 0)
//        return hub
//    }()

    fileprivate let presenter = Appearance.defaultPresenter()
    fileprivate let userApi = UserApi()
    fileprivate let chapterApi = ChapterApi()

    fileprivate enum Constants {
        static let padding: CGFloat = UniversalConstants.padding
        static let buttonSpacing: CGFloat = 12
        static let miniProfileSize: CGSize = {
            if #available(iOS 26.0, *) {
                CGSize(width: 38, height: 38)
            } else {
                CGSize(width: 32, height: 32)
            }
        }()
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

        hideNavigationShadow()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if let nc = navigationController, nc.viewControllers.count == 2 {
            hideNavigationShadow(false)
        }
    }

    // MARK: - Layout

    fileprivate func setupLayout() {
        delegate = self
        configureNavigationItems()
    }

    fileprivate func configureNavigationItems() {

        navigationItem.titleView = titleView
        
        let leftActions: [BarButtonAction] = [
            (ButtonImg.notifications, #selector(didPressNotificationsButton), 0),
            (ButtonImg.settings, #selector(didPressSettingsButton), 0)
        ]
        
        if #available(iOS 26, *) {
            navigationItem.leftBarButtonItems = leftActions.map { action in
                UIBarButtonItem(image: action.image, style: .plain, target: self, action: action.selector)
            }.interspersed(with: UIBarButtonItem.spacer())
        } else {
            navigationItem.leftBarButtonItem = UIBarButtonItem.stackedBarButtonItem(for: leftActions, target: self)
        }
        
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
        var vcs = [UIViewController]()
        vcs += [raceFeedVC]
        vcs += [seriesVC]
        vcs += [standingsVC]
        if isEventsTabEnable { vcs += [eventsVC] }

        let tab = AppPrefs.lastSelectedHomeTab

        configureTabBarController(with: vcs, selectedIndex: tab.rawValue)

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
        userProfileButton.setImage(with: imageUrl, placeholderImage: placeholder, forState: .normal, size: Constants.miniProfileSize)
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

extension UIImage {
    func roundedImage(ofSize size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            UIBezierPath(ovalIn: CGRect(origin: .zero, size: size)).addClip()
            draw(in: CGRect(origin: .zero, size: size))
        }
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

    func tabBarController(_ controller: UITabBarController, didSelect viewController: UIViewController) {

        if let vcs = viewControllers, vcs.contains(viewController) {
            hideNavigationShadow()
        } else {
            hideNavigationShadow(false)
        }

        if controller.selectedViewController == viewController {
            // Scroll the visible VC to the top
            if let topVC = viewController as? ScrollToTop {
                topVC.scrollToTop()
            }
        }

        // To open the last tab at launch
        if let tab = HomeTabs(rawValue: controller.selectedIndex) {
            AppPrefs.lastSelectedHomeTab = tab
        }
    }
}
