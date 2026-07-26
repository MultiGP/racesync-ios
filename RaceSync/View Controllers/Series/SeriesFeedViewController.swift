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
        tableView.backgroundColor = Color.gray20
        tableView.contentInsetAdjustmentBehavior = .always
        tableView.dataSource = self
        tableView.delegate = self
        tableView.emptyDataSetSource = self
        tableView.register(cellType: SimpleTableViewCell.self)
        tableView.tableHeaderView = self.sliderHeaderView
        tableView.tableFooterView = UIView()
        tableView.refreshControl = self.refreshControl
        return tableView
    }()

    var shimmeringView: ShimmeringView = defaultShimmeringView()

    // MARK: - Private Variables

    fileprivate lazy var headerView: UIView = {
        let view = UIView()
        view.backgroundColor = Color.barBackground
        view.tintColor = Color.blue

        let spacing: CGFloat = 10
        let buttonWidth: CGFloat = 30

        view.addSubview(searchButton)
        searchButton.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.leading.equalToSuperview().offset(Constants.padding)
            $0.width.equalTo(buttonWidth)
        }

        view.addSubview(segmentedControl)
        segmentedControl.snp.makeConstraints {
            let trailing = spacing+buttonWidth+Constants.padding // To keep it proportionally centered
            $0.top.equalToSuperview().offset(spacing)
            $0.leading.equalTo(searchButton.snp.trailing).offset(spacing)
            $0.trailing.equalToSuperview().offset(-trailing)
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

    fileprivate lazy var searchButton: CustomButton = {
        let button = CustomButton(type: .system)
        button.addTarget(self, action: #selector(didPressSearchButton), for: .touchUpInside)
        button.setImage(SystemImg.search, for: .normal)
        return button
    }()

    fileprivate lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.backgroundColor = Color.gray20
        refreshControl.tintColor = Color.blue
        refreshControl.addTarget(self, action: #selector(didPullRefreshControl), for: .valueChanged)
        return refreshControl
    }()

    fileprivate lazy var sliderHeaderView: SliderTableViewHeaderView = {
        let view = SliderTableViewHeaderView()
        view.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        view.backgroundColor = Color.gray20
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

        hideNavigationShadow()

        if feedCount() == 0 {
            isLoadingList(true)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // reload whenever we transition back
        if feedCount() == 0 || animated {
            loadContent(forced: true)
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

    // MARK: - Actions

    @objc fileprivate func didChangeSegment() {
        tableView.reloadData()

        AppPrefs.lastSelectedSeriesFilter = selectedFilter
    }

    @objc fileprivate func didPressSearchButton(_ sender: Any) {
        let vc = UniversalSearchViewController()
        let nc = NavigationController(rootViewController: vc)
        present(nc, animated: true)
    }

    fileprivate func openSeriesDetail(_ viewModel: SeriesViewModel, animated: Bool = true) {
        let vc = SeriesTabBarController(with: viewModel.series.id)
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: animated)
    }

    @objc fileprivate func didPullRefreshControl() {
        loadContent(forced: true)
    }

    // MARK: - Data Update

    fileprivate func loadContent(forced: Bool = false) {

        if !refreshControl.isRefreshing {
            isLoadingList(true)
        }

        seriesFeedController.viewModels(for: selectedFilter, forceFetch: forced) { [weak self] objects, cached, error in
            guard let s = self else { return }

            if let error = error {
                print("SeriesFeedController loadContent error : \(error.debugDescription)")
                return
            }

            s.isLoadingList(false)

            if s.refreshControl.isRefreshing && !cached { // don't dismiss the refresh control from cache callbacks
                s.refreshControl.endRefreshing()
            }

            let slider = s.sliderHeaderView
            let count = slider.delegate?.sliderNumberOfItems(slider) ?? 0

            if slider.numberOfItems == 0 && count > 0 {
                slider.reloadData()
            } else if count == 0 { // Hiding the slider if nothing to show
                s.tableView.tableHeaderView = nil
            }

            s.tableView.reloadData()
        }
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
