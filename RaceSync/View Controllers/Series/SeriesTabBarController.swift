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

    // MARK: - Private Variables

    fileprivate lazy var activityIndicatorView: ActivityLoadingView = {
        let view = ActivityLoadingView(style: .medium)
        view.title = "Loading Series..."
        view.hidesWhenStopped = true
        return view
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

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()

        setupLayout()
        loadSeries()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    // MARK: - Layout

    fileprivate func setupLayout() {

        view.backgroundColor = Color.white
        tabBar.isHidden = true // hiding temporarily, while the view loads
        delegate = self

        view.addSubview(activityIndicatorView)
        activityIndicatorView.snp.makeConstraints {
            $0.centerX.centerY.equalToSuperview()
        }
    }

    fileprivate func configureViewControllers() {
        guard let series = series else { return }

        var raceViewModels = [RaceViewModel]()
        if let races = series.races {
            raceViewModels += RaceViewModel.viewModels(with: races)
        }

        let controller = SeriesController(with: series)

        let raceListVC = RaceListViewController(raceViewModels, seriesId: seriesId)
        raceListVC.navigationItem.rightBarButtonItem = controller.navigationItems()

        var vcs = [UIViewController]()
        vcs += [SeriesDetailViewController(with: controller)]
        vcs += [raceListVC]
        vcs += [SeriesStandingsViewController(with: controller)]

        configureTabBarController(with: vcs, selectedIndex: initialSelectedIndex)

        title = vcs.first?.title
        tabBar.isHidden = false
        navigationItem.rightBarButtonItem = controller.navigationItems()
    }

    // MARK: - Data Update

    fileprivate func loadSeries() {
        setLoading(true)

        seriesApi.view(series: seriesId) { [weak self] series, error in
            guard let self = self else { return }
            self.setLoading(false)
            self.series = series

            if let error = error {
                self.handleError(error)
            } else {
                self.configureViewControllers()
            }
        }
    }

    fileprivate func setLoading(_ loading: Bool) {
        activityIndicatorView.isLoading = loading
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

    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {

        (tabBar as? RoundedSelectionTabBar)?.updateSelectionFrame(animated: true)

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
