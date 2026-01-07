//
//  SeriesViewController.swift
//  RaceSync
//
//  Created by Ignacio Romero Zurbuchen on 2025-09-07.
//  Copyright © 2025 MultiGP Inc. All rights reserved.
//

import UIKit
import SnapKit
import RaceSyncAPI
import ShimmerSwift

class SeriesViewController: UIViewController, Shimmable {

    // MARK: - Public Variables

    lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.backgroundView = UIView()
        tableView.backgroundView?.backgroundColor = Color.clear
        tableView.backgroundColor = Color.gray50
        tableView.contentInsetAdjustmentBehavior = .always
        tableView.dataSource = self
        tableView.delegate = self
//        tableView.emptyDataSetSource = self
//        tableView.emptyDataSetDelegate = self
        tableView.register(cellType: SimpleTableViewCell.self)
        tableView.tableHeaderView = self.sliderHeaderView
        tableView.refreshControl = self.refreshControl
        tableView.tableFooterView = UIView()
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

        let separatorLine = UIView()
        separatorLine.backgroundColor = Color.gray100
        view.addSubview(separatorLine)
        separatorLine.snp.makeConstraints {
            $0.height.equalTo(0.5)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(view.snp.bottom)
        }
        return view
    }()

    fileprivate lazy var segmentedControl: UISegmentedControl = {
        let items = ["My Series", "Popular", "All Series"]
        let control = UISegmentedControl(items: items)
        control.selectedSegmentIndex = 0
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
        view.delegate = self
        return view
    }()

    fileprivate var isLoading: Bool {
        shimmeringView.isShimmering
    }

    fileprivate let seriesApi = SeriesApi()
    fileprivate var seriesViewModels = [SeriesViewModel]()

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

        if seriesViewModels.count == 0 {
            isLoadingList(true)
        } else {
            tableView.reloadData()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if seriesViewModels.count == 0 {
            loadContent()
        }
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
        tabBarItem.isEnabled = APIServices.shared.settings.isDev
    }

    // MARK: - Data Update

    fileprivate func loadContent() {

        if !refreshControl.isRefreshing {
            isLoadingList(true)
        }

        seriesApi.getSeries { objects, error in
            if let objects = objects {
                self.seriesViewModels = SeriesViewModel.viewModels(with: objects)
            } else if error != nil {
                // self.emptyStateError = EmptyStateViewModel(.errorStandings)
            }

            if self.refreshControl.isRefreshing {
                self.refreshControl.endRefreshing()
            } else {
                self.isLoadingList(false)
            }

            self.tableView.reloadData()

            self.tableView.tableHeaderView = self.sliderHeaderView
            self.sliderHeaderView.reloadData()
        }
    }

    fileprivate func seriesViewModel(at index: Int) -> SeriesViewModel? {
        return seriesViewModels[index]
    }

    // MARK: - Actions

    fileprivate func showSeries(for index: Int) {
        guard let viewModel = seriesViewModel(at: index) else { return }

        let vc = SeriesTabBarController(with: viewModel.series.id)
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc fileprivate func didChangeSegment() {
//        seriesApi.cancelAll()
    }

    @objc fileprivate func didPullRefreshControl() {
        loadContent()
    }

    // MARK: - Cell Configuration

    func configure<T>(_ cell: T, forRowAt indexPath: IndexPath) where T : SimpleTableViewCell {
        guard let viewModel = seriesViewModel(at: indexPath.row) else { return }

        cell.titleLabel.text = viewModel.titleLabel
        cell.titleLabel.numberOfLines = 2
        cell.subtitleLabel.text = viewModel.typeLabel
        cell.accessoryType = .disclosureIndicator

        let ratio = CGFloat(16.0/9.0)
        let height = Constants.cellHeight - Constants.padding*2
        let size = CGSize(width: height * ratio, height: height)
        cell.imageRatio = ratio
        cell.iconImageView.setImage(with: viewModel.imageUrl, placeholderImage: PlaceholderImg.small, size: size)
        cell.iconImageView.contentMode = .scaleAspectFill
        cell.iconImageView.layer.cornerRadius = 6
        cell.iconImageView.layer.masksToBounds = true
    }
}

extension SeriesViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        showSeries(for: indexPath.row)
    }
}

extension SeriesViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return seriesViewModels.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(forIndexPath: indexPath) as SimpleTableViewCell
        configure(cell, forRowAt: indexPath)
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return Constants.cellHeight
    }
}

extension SeriesViewController: SliderTableViewHeaderViewDelegate {

    func sliderNumberOfItems(_ slider: SliderTableViewHeaderView) -> Int {
        return isLoading ? 0 : seriesViewModels.count
    }

    func slider(_ slider: SliderTableViewHeaderView, imageFor view: UIImageView, at index: Int) {
        guard let viewModel = seriesViewModel(at: index) else { return }
        view.setImage(with: viewModel.imageUrl, placeholderImage: PlaceholderImg.medium)
    }

    func slider(_ slider: SliderTableViewHeaderView, didSelectImageAt index: Int) {
        showSeries(for: index)
    }
}
