//
//  RaceTabBarController.swift
//  RaceSync
//
//  Created by Ignacio Romero Zurbuchen on 2019-11-15.
//  Copyright © 2019 MultiGP Inc. All rights reserved.
//

import UIKit
import SnapKit
import EmptyDataSet_Swift
import RaceSyncAPI

enum RaceTabs: Int {
    case details, results, schedule
}

class RaceTabBarController: UITabBarController {

    // MARK: - Public Variables

    var raceId: ObjectId
    var race: Race?

    var isDismissable: Bool = false {
        didSet {
            if isDismissable {
                navigationItem.leftBarButtonItem = UIBarButtonItem(image: ButtonImg.close, style: .done, target: self, action: #selector(didPressCloseButton))
                navigationItem.backBarButtonItem = nil
            } else {
                navigationItem.leftBarButtonItem = nil
            }
        }
    }

    var isLoading: Bool = false {
        didSet {
            if isLoading { activityIndicatorView.startAnimating() }
            else { activityIndicatorView.stopAnimating() }
        }
    }

    override var selectedIndex: Int {
        didSet {
            didSelectedIndex(selectedIndex)
        }
    }

    // MARK: - Private Variables

    fileprivate lazy var titleButton: PasteboardButton = {
        let button = PasteboardButton(type: .system)
        button.addTarget(self, action: #selector(didPressTitleButton), for: .touchUpInside)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        button.titleLabel?.textAlignment = .center
        button.setTitleColor(Color.black, for: .normal)
        button.setTitle(self.title, for: .normal)
        return button
    }()

    fileprivate lazy var activityIndicatorView: UIActivityIndicatorView = {
        return UIActivityIndicatorView(style: .medium)
    }()

    fileprivate var initialSelectedIndex: Int = RaceTabs.details.rawValue
    fileprivate var emptyStateError: EmptyStateViewModel?

    fileprivate let raceApi = RaceApi()

    fileprivate enum Constants {
        static let padding: CGFloat = UniversalConstants.padding
    }

    // MARK: - Initialization

    init(with race: Race) {
        self.raceId = race.id
        self.race = race
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()

        setupLayout()
        loadRaceView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    // MARK: - Layout

    fileprivate func setupLayout() {

        title = ""
        view.backgroundColor = Color.white

        tabBar.isHidden = true
        delegate = self

        view.addSubview(activityIndicatorView)
        activityIndicatorView.snp.makeConstraints {
            $0.centerX.centerY.equalToSuperview()
        }
    }

    fileprivate func configureViewControllers(with race: Race) {

        var vcs = [UIViewController]()
        vcs += [RaceDetailViewController(with: race)]
        vcs += [RacePilotsViewController(with: race)]
        vcs += [RaceScheduleViewController()]

        for vc in vcs { vc.willMove(toParent: self) }
        viewControllers = vcs
        for vc in vcs { vc.didMove(toParent: self) }

        // Dirty little trick to select the first tab bar item
        self.selectedIndex = initialSelectedIndex+1
        self.selectedIndex = initialSelectedIndex

        // Trick to pre-load each view controller
        preloadTabs()
        tabBar.isHidden = false

        // Using a custom button title in this case, to display the id of a Race on tap
        navigationItem.titleView = titleButton
    }

    // MARK: - Actions

    func selectTab(_ tab: RaceTabs) {
        selectedIndex = tab.rawValue
    }

    fileprivate func didSelectedIndex(_ index: Int) {
        guard let vc = viewControllers?[index] else { return }

        title = vc.title
        titleButton.setTitle(title, for: .normal)
        titleButton.sizeToFit()

        navigationItem.rightBarButtonItem = vc.navigationItem.rightBarButtonItem
    }

    @objc fileprivate func didPressCloseButton() {
        dismiss(animated: true)
    }

    @objc fileprivate func didPressTitleButton() {
        guard let _ = race else { return }

        let btnTitle = titleButton.title(for: .normal)

        if btnTitle == title {
            titleButton.setTitle(raceId, for: .normal)
        } else if btnTitle == raceId {
            titleButton.setTitle(title, for: .normal)
        }
    }

    // MARK: - Error

    fileprivate func handleError(_ error: Error) {

        emptyStateError = EmptyStateViewModel(.errorRaces)

        // temporary scroll view used to display the error message
        let scrollView = UIScrollView()
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.emptyDataSetDelegate = self
        scrollView.emptyDataSetSource = self

        view.addSubview(scrollView)
        scrollView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            $0.bottom.leading.trailing.equalToSuperview()
        }

        scrollView.reloadEmptyDataSet()
    }
}

extension RaceTabBarController {

    public func loadRaceView() {
        guard !isLoading else { return }

        isLoading = true

        raceApi.view(race: raceId) { [weak self] (race, error) in
            self?.isLoading = false

            if let race = race, let raceId = self?.raceId {

                // TODO: Temporary hack since race/view API doesn't include the raceId & raceOwnerName attributes just yet
                // See issue https://github.com/MultiGP/multigp-com/issues/88
                race.id = raceId
                race.ownerUserName = self?.race?.ownerUserName ?? ""

                self?.race = race
                self?.configureViewControllers(with: race)
            } else if let error = error {
                self?.handleError(error)
            }
        }
    }

    public func reloadRaceView() {
        guard !isLoading else { return }

        raceApi.view(race: raceId) { [weak self] (race, error) in
            guard let race = race, let raceId = self?.raceId , let vcs = self?.viewControllers else { return }

            // TODO: Temporary hack since race/view API doesn't include the raceId & raceOwnerName attributes just yet
            // See issue https://github.com/MultiGP/multigp-com/issues/88
            race.id = raceId
            race.ownerUserName = self?.race?.ownerUserName ?? ""

            self?.race = race

            for viewcontroller in vcs {
                guard var vc = viewcontroller as? RaceTabbable else { continue }
                vc.race = race
                vc.reloadContent()
            }
        }
    }

    @objc public func didPressShareButton() {

        guard  let raceURL = MGPWeb.getURL(for: .raceView, value: raceId) else { return }

        var items: [Any] = [raceURL]
        var activities: [UIActivity] = [CopyLinkActivity()]

        // Calendar integration
        if let event = race?.createCalendarEvent(with: raceId) {
            items += [event]
            activities += [CalendarActivity()]
        }

        activities += [MultiGPActivity()]

        let vc = UIActivityViewController(activityItems: items, applicationActivities: activities)
        vc.excludeAllActivityTypes(except: [.airDrop])
        present(vc, animated: true)
    }
}

extension RaceTabBarController: EmptyDataSetSource {

    func title(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        return emptyStateError?.title
    }

    func description(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        return emptyStateError?.description
    }

    func buttonTitle(forEmptyDataSet scrollView: UIScrollView, for state: UIControl.State) -> NSAttributedString? {
        return emptyStateError?.buttonTitle(state)
    }
}

extension RaceTabBarController: EmptyDataSetDelegate {

    func emptyDataSetShouldAllowScroll(_ scrollView: UIScrollView) -> Bool {
        return false
    }

    func emptyDataSet(_ scrollView: UIScrollView, didTapButton button: UIButton) {
        guard let url = AppWebConstants.getPrefilledFeedbackFormUrl() else { return }
        WebViewController.openUrl(url)
    }
}

extension RaceTabBarController: UITabBarControllerDelegate {

    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        return true
    }

    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        if let index = viewControllers?.lastIndex(of: viewController) {
            didSelectedIndex(index)
        }
    }
}
