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
    case details, pilots, schedule, payments
    static let `default`: Self = .details
}

class RaceTabBarController: UITabBarController {

    // MARK: - Public Variables

    let raceController: RaceController

    var raceId: ObjectId {
        get { return raceController.raceId }
    }

    var race: Race? {
        get { return raceController.race }
    }

    var isDismissable: Bool = false {
        didSet {
            if isDismissable {
                navigationItem.leftBarButtonItem = UIBarButtonItem(image: ButtonImg.close, style: .plain, target: self, action: #selector(didPressCloseButton))
                navigationItem.backBarButtonItem = nil
            } else {
                navigationItem.leftBarButtonItem = nil
            }
        }
    }

    override var selectedIndex: Int {
        didSet {
            didSelectedIndex(selectedIndex)
        }
    }

    override var title: String? {
        didSet {
            titleButton.setTitle(title, for: .normal)
            titleButton.invalidateIntrinsicContentSize()
            titleButton.sizeToFit()
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
        button.titleLabel?.lineBreakMode = .byClipping
        return button
    }()

    fileprivate lazy var titleActivityIndicatorView: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(style: .medium)
        view.color = .secondaryLabel
        view.hidesWhenStopped = true
        return view
    }()

    fileprivate lazy var titleContainerView: UIStackView = {
        let leadingSpacer = UIView()
        let activityContainer = UIView()
        leadingSpacer.snp.makeConstraints { $0.width.equalTo(20) }
        activityContainer.snp.makeConstraints { $0.width.equalTo(20) }
        activityContainer.addSubview(titleActivityIndicatorView)
        titleActivityIndicatorView.snp.makeConstraints { $0.center.equalToSuperview() }

        let stackView = UIStackView(arrangedSubviews: [leadingSpacer, titleButton, activityContainer])
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = 6
        return stackView
    }()

    fileprivate lazy var activityIndicatorView: ActivityLoadingView = {
        let view = ActivityLoadingView(style: .medium)
        view.title = "Loading Race..."
        view.hidesWhenStopped = true
        return view
    }()

    fileprivate var initialSelectedIndex: Int
    fileprivate var emptyStateError: EmptyStateViewModel?

    fileprivate enum Constants {
        static let padding: CGFloat = UniversalConstants.padding
        static let buttonSpacing: CGFloat = 12
    }

    // MARK: - Initialization

    init(with race: Race, selectedTab: RaceTabs = .details) {
        self.raceController = RaceController(with: race)
        self.initialSelectedIndex = selectedTab.rawValue
        super.init(nibName: nil, bundle: nil)
    }

    init(with raceId: ObjectId, selectedTab: RaceTabs = .details) {
        self.raceController = RaceController(id: raceId)
        self.initialSelectedIndex = selectedTab.rawValue
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        //
    }

    // MARK: - Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()
        
        raceController.parentViewController = self

        setupLayout()
        loadRace()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    // MARK: - Layout

    fileprivate func setupLayout() {

        // Using a custom button title in this case, to display the id of a Race on tap
        navigationItem.titleView = titleContainerView

        view.backgroundColor = Color.white
        tabBar.isHidden = true // hiding temporarily, while the view loads
        delegate = self

        view.addSubview(activityIndicatorView)
        activityIndicatorView.snp.makeConstraints {
            $0.centerX.centerY.equalToSuperview()
        }
    }

    fileprivate func configureViewControllers() {

        let controller = raceController
        let existingVCs = viewControllers ?? []
        let previouslySelectedVC = selectedViewController

        var vcs = [UIViewController]()
        vcs += [existingVCs.first { $0 is RaceDetailViewController }
            ?? RaceDetailViewController(with: controller)]
        vcs += [existingVCs.first { $0 is RacePilotsViewController }
            ?? RacePilotsViewController(with: controller)]

        if let race = race {
            if race.canShowZippyQ {
                vcs += [existingVCs.first { $0 is ZippyqViewController }
                    ?? ZippyqViewController(with: controller)]
            }
            if race.canManagePayments {
                vcs += [existingVCs.first { $0 is RacePaymentsViewController }
                    ?? RacePaymentsViewController(with: controller)]
            }
        }

        if viewControllers == nil {
            configureTabBarController(
                with: vcs,
                selectedIndex: min(initialSelectedIndex, max(0, vcs.count-1))
            )
        } else {
            setViewControllers(vcs, animated: false)
            if let previouslySelectedVC,
               let selectedIndex = vcs.firstIndex(of: previouslySelectedVC) {
                self.selectedIndex = selectedIndex
            } else {
                selectTab(.details)
            }
            preloadTabs()
        }

        tabBar.isHidden = false
    }

    // MARK: - Actions

    func selectTab(_ tab: RaceTabs) {
        selectedIndex = tab.rawValue
    }

    fileprivate func didSelectedIndex(_ index: Int) {
        guard let vc = viewControllers?[index] else { return }

        title = vc.title
        titleActivityIndicatorView.stopAnimating()
        navigationItem.rightBarButtonItems = vc.navigationItem.rightBarButtonItems

        if let detailVC = vc as? RaceDetailViewController,
           detailVC.shouldUseTransparentNavigationBar {
            Appearance.applyTransparentStyle(to: navigationItem)
        } else {
            Appearance.applyOpaqueStyle(to: navigationItem, shadow: true)
        }
    }

    func setTitleActivityIndicatorVisible(_ visible: Bool, for viewController: UIViewController) {
        guard selectedViewController === viewController else { return }
        visible ? titleActivityIndicatorView.startAnimating() : titleActivityIndicatorView.stopAnimating()
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

    @objc fileprivate func didPressCloseButton() {
        dismiss(animated: true)
    }

    // MARK: - Data Update

    fileprivate func loadRace() {
        setLoading(true)

        raceController.loadRace { [weak self] race, error in
            guard let self = self else { return }
            self.setLoading(false)

            if let error = error {
                self.handleError(error)
            } else {
                self.configureViewControllers()
            }
        }
    }

    public func reloadRace() {
        raceController.loadRace { [weak self] race, error in
            guard let self = self else { return }

            if error == nil {
                self.reloadRaceTabs()
            }
        }
    }

    public func reloadRaceTabs() {
        configureViewControllers()
        viewControllers?
            .compactMap { $0 as? RaceTabbable }
            .forEach { $0.reloadContent() }
    }

    fileprivate func setLoading(_ loading: Bool) {
        activityIndicatorView.isLoading = loading
    }

    // MARK: - Error Handling

    fileprivate func handleError(_ error: NSError) {

        emptyStateError = EmptyStateViewModel(.error(error))

        // temporary scroll view used to display the error message
        let scrollView = UIScrollView()
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.emptyDataSetDelegate = self
        scrollView.emptyDataSetSource = self

        view.addSubview(scrollView)
        scrollView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        scrollView.reloadEmptyDataSet()
    }
}

extension RaceTabBarController: UITabBarControllerDelegate {

    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        return true
    }
    
    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        // Trigger haptic gesture to emphasize the action
        HapticEngine.shared.trigger()
    }

    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {

        if let index = viewControllers?.lastIndex(of: viewController) {
            didSelectedIndex(index)
        }
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
}
