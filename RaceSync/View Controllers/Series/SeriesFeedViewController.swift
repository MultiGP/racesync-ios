//
//  SeriesFeedViewController.swift
//  RaceSync
//
//  Created by Ignacio Romero Zurbuchen on 2025-09-07.
//  Copyright © 2025 MultiGP Inc. All rights reserved.
//

import UIKit
import SnapKit
import RaceSyncAPI
import ShimmerSwift
import EmptyDataSet_Swift

class SeriesFeedViewController: UIViewController, Shimmable {

    // MARK: - Public Variables

    lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.backgroundView = UIView()
        tableView.backgroundView?.backgroundColor = Color.clear
        tableView.backgroundColor = Color.gray50
        tableView.contentInsetAdjustmentBehavior = .always
        tableView.dataSource = self
        tableView.delegate = self
        tableView.emptyDataSetSource = self
        tableView.register(cellType: SimpleTableViewCell.self)
        tableView.tableHeaderView = self.sliderHeaderView
        tableView.tableFooterView = UIView()
//        tableView.refreshControl = self.refreshControl
        return tableView
    }()

    var shimmeringView: ShimmeringView = defaultShimmeringView()

    // MARK: - Private Variables

    fileprivate lazy var headerView: UIView = {
        let view = UIView()
        view.backgroundColor = Color.navigationBarColor
        view.tintColor = Color.blue

        let spacing = 10

        view.addSubview(segmentedControl)
        segmentedControl.snp.makeConstraints {
            $0.top.equalToSuperview().offset(spacing)
            $0.leading.equalToSuperview().offset(spacing*5)
            $0.trailing.equalToSuperview().offset(-spacing*5)
            $0.centerX.equalToSuperview()
        }

        view.addSeparatorLine(.bottom)
        return view
    }()

    fileprivate lazy var segmentedControl: UISegmentedControl = {
        let control = UISegmentedControl(items: SeriesFilter.titles)
        control.selectedSegmentIndex = AppPrefs.lastSelectedSeriesFilter.index
        control.addTarget(self, action: #selector(didChangeSegment), for: .valueChanged)
        return control
    }()

    fileprivate lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.backgroundColor = Color.gray50
        refreshControl.tintColor = Color.blue
        refreshControl.addTarget(self, action: #selector(didPullRefreshControl), for: .valueChanged)
        return refreshControl
    }()

    fileprivate lazy var sliderHeaderView: SliderTableViewHeaderView = {
        let view = SliderTableViewHeaderView()
        view.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        view.backgroundColor = Color.gray50
        view.autoScrollInterval = 5.0
        view.delegate = self
        return view
    }()

    fileprivate var isLoading: Bool {
        shimmeringView.isShimmering
    }

    fileprivate var selectedFilter: SeriesFilter {
        get {
            let title: String = segmentedControl.titleForSelectedSegment()!
            return SeriesFilter(title: title)!
        }
    }

    fileprivate func feedCount(for filter: SeriesFilter? = nil) -> Int {
        let filter = filter ?? selectedFilter
        return seriesFeedController.viewModelsCount(for: filter)
    }

    func feedViewModel(at index: Int, filter: SeriesFilter? = nil) -> SeriesViewModel? {

        let filter = filter ?? selectedFilter
        guard let list = seriesFeedController.viewModels(for: filter) else { return nil }
        if index >= 0, index < list.count {
            return list[index]
        }
        return nil
    }

    fileprivate let seriesFeedController = SeriesFeedController()
    fileprivate let sliderFilter: SeriesFilter = .regionals

    fileprivate let emptyStateSeries = EmptyStateViewModel(.noSeries)
    fileprivate let emptyStateJoinedSeries = EmptyStateViewModel(.noJoinedSeries)
    fileprivate let emptyStateComingSoon = EmptyStateViewModel(.comingSoon)

    fileprivate enum Constants {
        static let padding: CGFloat = UniversalConstants.padding
        static let cellHeight: CGFloat = 100
        static let headerViewHeight: CGFloat = 51
    }

    // MARK: - Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()

        setupLayout()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if feedCount() == 0 {
            isLoadingList(true)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        hideNavigationShadow()

        if feedCount() == 0 {
            loadContent()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }

    // MARK: - Layout

    fileprivate func setupLayout() {
        
        configureNavigationItems()

        view.addSubview(headerView)
        headerView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            $0.height.equalTo(Constants.headerViewHeight)
            $0.leading.trailing.equalToSuperview()
        }

        view.addSubview(tableView)
        tableView.snp.makeConstraints {
            $0.top.equalTo(headerView.snp.bottom)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(view.snp.bottom)
        }

        view.addSubview(shimmeringView)
        shimmeringView.snp.makeConstraints {
            $0.top.equalTo(tableView.snp.top)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(tableView.snp.bottom)
        }
    }

    fileprivate func configureNavigationItems() {
        title = "Series"
        tabBarItem = UITabBarItem(title: title, image: SystemImg.stack, selectedImage: SystemImg.stackFill)
    }

    // MARK: - Data Update

    fileprivate func loadContent() {

        if !refreshControl.isRefreshing {
            isLoadingList(true)
        }

        seriesFeedController.viewModels(for: selectedFilter) { objects, error in
            if self.refreshControl.isRefreshing {
                self.refreshControl.endRefreshing()
            } else {
                self.isLoadingList(false)
            }

            let slider = self.sliderHeaderView

            // Hiding the slider if nothing to show
            if slider.delegate?.sliderNumberOfItems(slider) ?? 0 > 0 {
                self.tableView.tableHeaderView = slider
                slider.reloadData()
            } else {
                self.tableView.tableHeaderView = nil
            }
        }
    }

    // MARK: - Actions

    fileprivate func openSeriesDetail(_ viewModel: SeriesViewModel, animated: Bool = true) {
        let vc = SeriesTabBarController(with: viewModel.series.id)
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: animated)
    }

    @objc fileprivate func didChangeSegment() {
        tableView.reloadData()

        AppPrefs.lastSelectedSeriesFilter = selectedFilter
    }

    @objc fileprivate func didPullRefreshControl() {
        loadContent()
    }
}

extension SeriesFeedViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        if let viewModel = feedViewModel(at: indexPath.row) {
            openSeriesDetail(viewModel)
        }
    }
}

extension SeriesFeedViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return feedCount()
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(forIndexPath: indexPath) as SimpleTableViewCell

        if let viewModel = feedViewModel(at: indexPath.row) {
            SimpleTableViewCell.configure(cell, with: viewModel)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return Constants.cellHeight
    }
}

extension SeriesFeedViewController: SliderTableViewHeaderViewDelegate {

    func sliderNumberOfItems(_ slider: SliderTableViewHeaderView) -> Int {
        return isLoading ? 0 : feedCount(for: sliderFilter)
    }

    func slider(_ slider: SliderTableViewHeaderView, imageFor view: UIImageView, at index: Int) {
        guard let viewModel = feedViewModel(at: index, filter: sliderFilter) else { return }
        view.setImage(with: viewModel.imageUrl, placeholderImage: PlaceholderImg.seriesMedium)
    }

    func slider(_ slider: SliderTableViewHeaderView, didSelectImageAt index: Int) {
        guard let viewModel = feedViewModel(at: index, filter: sliderFilter) else { return }
        openSeriesDetail(viewModel)
    }
}

extension SeriesFeedViewController: EmptyDataSetSource {

    func title(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        return emptyStateSeries.title
    }

    func description(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        return emptyStateSeries.description
    }

    func backgroundColor(forEmptyDataSet scrollView: UIScrollView) -> UIColor? {
        return Color.white
    }
}
