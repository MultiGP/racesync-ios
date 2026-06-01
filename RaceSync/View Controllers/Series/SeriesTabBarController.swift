//
//  SeriesTabBarController.swift
//  RaceSync
//
//  Created by Ignacio Romero Zurbuchen on 2025-10-01.
//  Copyright © 2025 MultiGP Inc. All rights reserved.
//

import UIKit
import SnapKit
import EmptyDataSet_Swift
import RaceSyncAPI

enum SeriesTabs: Int {
    case details, races, standings
    static let `default`: Self = .details
}

class SeriesTabBarController: UITabBarController {

    // MARK: - Public Variables

    var seriesId: ObjectId
    var series: Series?

    override var title: String? {
        didSet {
            titleButton.setTitle(title, for: .normal)
            titleButton.invalidateIntrinsicContentSize()
            titleButton.sizeToFit()
        }
    }

    // MARK: - Private Variables

    fileprivate lazy var activityIndicatorView: ActivityLoadingView = {
        let view = ActivityLoadingView(style: .medium)
        view.title = "Loading Series..."
        view.hidesWhenStopped = true
        return view
    }()

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

    fileprivate var initialSelectedIndex: Int = SeriesTabs.default.rawValue
    fileprivate var emptyStateError: EmptyStateViewModel?

    fileprivate let seriesApi = SeriesApi()
    fileprivate var seriesViewModels: SeriesViewModel?

    // MARK: - Initialization

    init(with id: ObjectId) {
        self.seriesId = id
        super.init(nibName: nil, bundle: nil)
        self.title = "Details"
    }

    init(with series: Series) {
        self.seriesId = series.id
        self.series = series
        super.init(nibName: nil, bundle: nil)
        self.title = "Details"
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()

        setupLayout()

        if series == nil {
            loadSeries()
        }
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
        navigationItem.titleView = titleButton

        view.backgroundColor = Color.white
        tabBar.isHidden = true // hiding temporarily, while the view loads
        delegate = self

        if series != nil {
            configureViewControllers()
        }
    }

    fileprivate func configureViewControllers() {
        guard let series = series else { return }

        var raceViewModels = [RaceViewModel]()
        if let races = series.races {
            raceViewModels += RaceViewModel.sortedViewModels(with: races, sorting: .ascending)
        }

        let controller = SeriesController(with: series)

        let raceListVC = RaceListViewController(raceViewModels, series: series)
        raceListVC.navigationItem.rightBarButtonItems = controller.navigationItems()

        var vcs = [UIViewController]()
        vcs += [SeriesDetailViewController(with: controller)]
        vcs += [raceListVC]
        vcs += [SeriesStandingsViewController(with: controller)]

        configureTabBarController(with: vcs, selectedIndex: initialSelectedIndex)

        title = vcs.first?.title
        tabBar.isHidden = false
        navigationItem.rightBarButtonItems = controller.navigationItems()
    }

    // MARK: - Data Update

    fileprivate func loadSeries() {

        view.addSubview(activityIndicatorView)
        activityIndicatorView.snp.makeConstraints {
            $0.centerX.centerY.equalToSuperview()
        }

        activityIndicatorView.isLoading = true

        seriesApi.view(series: seriesId) { [weak self] series, error in
            guard let self = self else { return }
            self.activityIndicatorView.isLoading = false
            self.activityIndicatorView.removeFromSuperview()

            self.series = series

            if let error = error {
                self.handleError(error)
            } else {
                self.configureViewControllers()
            }
        }
    }

    // MARK: - Actions

    fileprivate func selectTab(_ tab: SeriesTabs) {
        selectedIndex = tab.rawValue
    }

    fileprivate func didSelectedIndex(_ index: Int) {
        guard let vc = viewControllers?[index] else { return }

        title = vc.title
        navigationItem.rightBarButtonItem = vc.navigationItem.rightBarButtonItem
    }

    // MARK: - Actions

    @objc fileprivate func didPressTitleButton() {
        guard let seriesId = series?.id else { return }

        let btnTitle = titleButton.title(for: .normal)

        if btnTitle == title {
            titleButton.setTitle(seriesId, for: .normal)
        } else if btnTitle == seriesId {
            titleButton.setTitle(title, for: .normal)
        }
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
            $0.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            $0.bottom.leading.trailing.equalToSuperview()
        }

        scrollView.reloadEmptyDataSet()
    }
}

extension SeriesTabBarController: UITabBarControllerDelegate {

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

extension SeriesTabBarController: EmptyDataSetSource {

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

extension SeriesTabBarController: EmptyDataSetDelegate {

    func emptyDataSetShouldAllowScroll(_ scrollView: UIScrollView) -> Bool {
        return false
    }

    func verticalOffset(forEmptyDataSet scrollView: UIScrollView) -> CGFloat {
        return -(navigationController?.navigationBar.frame.height ?? 0)
    }
}
