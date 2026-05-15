//
//  SeriesStandingsViewController.swift
//  RaceSync
//
//  Created by Ignacio Romero Zurbuchen on 2025-10-01.
//  Copyright © 2025 MultiGP Inc. All rights reserved.
//

import UIKit
import SnapKit
import RaceSyncAPI
import EmptyDataSet_Swift

class SeriesStandingsViewController: UIViewController, Pinnable {

    // MARK: - Public Variables

    var seriesController: SeriesController

    var series: Series {
        get { return seriesController.series }
    }

    var seriesApi: SeriesApi {
        get { return seriesController.seriesApi }
    }

    lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.emptyDataSetSource = self
        tableView.register(cellType: AvatarTableViewCell.self)
        tableView.tableFooterView = UIView()

        let backgroundView = UIView()
        backgroundView.backgroundColor = Color.gray20
        tableView.backgroundView = backgroundView
        return tableView
    }()

    // MARK: - Private Variables

    fileprivate lazy var headerView: UIView = {
        let view = UIView()
        view.backgroundColor = Color.navigationBarColor
        view.tintColor = Color.blue

        let spacing: CGFloat = 10
        let width = UIScreen.main.bounds.width/8

        view.addSubview(segmentedControl)
        segmentedControl.snp.makeConstraints {
            $0.top.equalToSuperview().offset(spacing)
            $0.leading.equalToSuperview().offset(width)
            $0.trailing.equalToSuperview().offset(-width)
        }

        view.addSeparatorLine(.bottom)
        return view
    }()

    fileprivate lazy var segmentedControl: UISegmentedControl = {
        let control = UISegmentedControl(items: SeriesStandingsFilter.titles)
        control.selectedSegmentIndex = SeriesStandingsFilter.pilots.index
        control.addTarget(self, action: #selector(didChangeSegment), for: .valueChanged)
        return control
    }()

    var pinnedView: UIView?
    var cachedPinnedIndexPath: IndexPath?

    fileprivate var showsSegmentedControl: Bool {
        get {
            guard let pilotResults = series.pilotResults, let chapterResults = series.chapterResults else { return false }
            return (pilotResults.count > 0 && chapterResults.count > 0)
        }
    }

    fileprivate var selectedFilter: SeriesStandingsFilter {
        SeriesStandingsFilter(index: segmentedControl.selectedSegmentIndex) ?? .pilots
    }

    fileprivate var chapterApi = ChapterApi()
    fileprivate var userApi = UserApi()
    fileprivate var myUserId: ObjectId? {
        get { return APIServices.shared.myUser?.id }
    }

    fileprivate let emptyStateSeriesResults = EmptyStateViewModel(.noSeriesResults)

    fileprivate enum Constants {
        static let padding: CGFloat = UniversalConstants.padding
        static let cellHeight: CGFloat = 86
        static let headerViewHeight: CGFloat = 51
    }

    // MARK: - Initialization

    init(with controller: SeriesController) {
        self.seriesController = controller
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()

        setupLayout()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if showsSegmentedControl {
            hideNavigationShadow()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if showsSegmentedControl {
            hideNavigationShadow(false)
        }
    }

    // MARK: - Layout

    fileprivate func setupLayout() {

        configureNavigationItems()

        registerPinnedView(viewType: AvatarTableViewCell.self)

        if showsSegmentedControl {
            view.addSubview(headerView)
            headerView.snp.makeConstraints {
                $0.top.equalTo(view.safeAreaLayoutGuide.snp.top)
                $0.height.equalTo(Constants.headerViewHeight)
                $0.leading.trailing.equalToSuperview()
            }
        }

        view.addSubview(tableView)
        tableView.snp.makeConstraints {
            if showsSegmentedControl {
                $0.top.equalTo(headerView.snp.bottom)
            } else {
                $0.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            }

            $0.width.equalTo(UIScreen.main.bounds.width)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }
    }

    fileprivate func configureNavigationItems() {

        if showsSegmentedControl {
            title = "Leaderboards"
        } else {
            title = "Leaderboard"
        }

        tabBarItem = UITabBarItem(title: title, image: SystemImg.trophy, selectedImage: SystemImg.trophyFill)

        navigationItem.rightBarButtonItems = seriesController.navigationItems()
    }

    // MARK: - Data Update

    fileprivate func viewModel(at indexPath: IndexPath) -> SeriesResultViewModel? {
        return viewModels()[indexPath.row]
    }

    fileprivate func viewModels() -> [SeriesResultViewModel] {
        if showsSegmentedControl && selectedFilter == .chapters {
            return seriesController.chapterResultViewModels
        }
        return seriesController.pilotResultViewModels
    }

    // MARK: - Pinnable

    func canPinView() -> Bool {
        return myUserId != nil
    }

    func pinnedViewIndexPath() -> IndexPath? {
        guard let userId = myUserId else { return nil }

        if let cached = cachedPinnedIndexPath {
            return cached
        }

        let viewModels = viewModels()
        guard let index = viewModels.firstIndex(where: { $0.pilotId == userId }) else {
            return nil
        }

        let indexPath = IndexPath(row: index, section: 0)
        cachedPinnedIndexPath = indexPath
        return indexPath
    }

    // MARK: - Actions

    @objc fileprivate func didChangeSegment() {
        tableView.setContentOffset(.zero, animated: false)
        tableView.reloadData()
    }

    func showUserProfile(forUserAt indexPath: IndexPath, from cell: AvatarTableViewCell) {
        guard let viewModel = viewModel(at: indexPath), let id = viewModel.pilotId else { return }

        cell.isLoading = true

        userApi.getUser(with: id) { [weak self] (user, error) in
            if let user = user {
                let vc = UserViewController(with: user)
                self?.navigationController?.pushViewController(vc, animated: true)
            } else if let _ = error {
                // handle error
            }
            cell.isLoading = false
        }
    }

    func showChapterProfile(forUserAt indexPath: IndexPath, from cell: AvatarTableViewCell) {
        guard let viewModel = viewModel(at: indexPath), let id = viewModel.chapterId else { return }

        cell.isLoading = true

        chapterApi.getChapter(with: id) { [weak self] (chapter, error) in
            if let chapter = chapter {
                let vc = ChapterViewController(with: chapter)
                self?.navigationController?.pushViewController(vc, animated: true)
            } else if let _ = error {
                // handle error
            }
            cell.isLoading = false
        }
    }
}

extension SeriesStandingsViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) as? AvatarTableViewCell else { return }
        tableView.deselectRow(at: indexPath, animated: true)

        if showsSegmentedControl && selectedFilter == .chapters {
            showChapterProfile(forUserAt: indexPath, from: cell)
        } else {
            showUserProfile(forUserAt: indexPath, from: cell)
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if viewModels().count > 0 {
            return series.scoreTypeString
        }
        return nil
    }
}

extension SeriesStandingsViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModels().count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(forIndexPath: indexPath) as AvatarTableViewCell
        configure(cell, forRowAt: indexPath)
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let viewModel = viewModel(at: indexPath) else { return 0 }

        if series.scoreType == .collegiate && viewModel.type == .chapter {
            return Constants.cellHeight*1.25 // higher cell since collegiate chapter names are longer
        } else {
            return Constants.cellHeight
        }
    }

    func configure<T>(_ view: T, forRowAt indexPath: IndexPath) where T : UITableViewCell {
        guard let cell = view as? AvatarTableViewCell, let viewModel = viewModel(at: indexPath) else { return }

        cell.rankView.rank = Int32(indexPath.row + 1)
        cell.titleLabel.text = viewModel.titleLabel
        cell.subtitleLabel.text = viewModel.subtitleLabel
        cell.avatarImageView.imageView.setImage(with: viewModel.imageUrl, placeholderImage: PlaceholderImg.medium)

        if !viewModel.scoreLabel.isEmpty {
            cell.textPill.text = viewModel.scoreLabel
            cell.textPill.style = .text
        }

        if viewModel.subtitleLabel == SeriesResultViewModel.emptyLabel {
            cell.rankView.rank = 0
        }

        if series.scoreType == .collegiate && viewModel.type == .chapter {
            cell.titleLabel.numberOfLines = 2
        }

        if viewModel.pilotId == myUserId {
            cell.titleLabel.textColor = Color.white
            cell.subtitleLabel.textColor = Color.gray20
            cell.rankView.titleLabel.textColor = Color.gray20
            cell.backgroundColor = Color.gray200
            cell.selectedBackgroundView?.backgroundColor = Color.gray300
        } else {
            cell.titleLabel.textColor = Color.black
            cell.subtitleLabel.textColor = Color.gray300
            cell.rankView.titleLabel.textColor = Color.gray300
            cell.backgroundColor = (indexPath.row % 2 == 0) ? Color.white : Color.gray20
            cell.selectedBackgroundView?.backgroundColor = Color.gray50
        }
    }
}

extension SeriesStandingsViewController: UIScrollViewDelegate {

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard viewModels().count > 0 else { return }
        layoutPinnedView()
    }
}

extension SeriesStandingsViewController: EmptyDataSetSource {

    func title(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        return emptyStateSeriesResults.title
    }

    func description(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        return emptyStateSeriesResults.description
    }

    func backgroundColor(forEmptyDataSet scrollView: UIScrollView) -> UIColor? {
        return Color.white
    }
}

fileprivate enum SeriesStandingsFilter: EnumTitle {
    case pilots, chapters

    var title: String {
        switch self {
        case .pilots:       return "Individual"
        case .chapters:     return "Chapters"
        }
    }

    var index: Int {
        Self.allCases.firstIndex(of: self)!
    }

    init?(index: Int) {
        guard index >= 0, index < Self.allCases.count else { return nil }
        self = Self.allCases[index]
    }
}
