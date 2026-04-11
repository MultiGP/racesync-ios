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
        get { return seriesController.series! }
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

    fileprivate var myUserId: ObjectId? {
        get { return APIServices.shared.myUser?.id }
    }

    var pinnedView: UIView?
    var cachedPinnedIndexPath: IndexPath?

    fileprivate var userApi = UserApi()

    fileprivate let emptyStateSeriesResults = EmptyStateViewModel(.noSeriesResults)

    fileprivate enum Constants {
        static let padding: CGFloat = UniversalConstants.padding
        static let cellHeight: CGFloat = 86
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
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    // MARK: - Layout

    fileprivate func setupLayout() {

        configureNavigationItems()

        registerPinnedView(viewType: AvatarTableViewCell.self)

        view.addSubview(tableView)
        tableView.snp.makeConstraints {
            $0.top.bottom.leading.trailing.equalToSuperview()
        }
    }

    fileprivate func configureNavigationItems() {
        title = "Leaderboard"
        tabBarItem = UITabBarItem(title: title, image: SystemImg.trophy, selectedImage: SystemImg.trophyFill)

        navigationItem.rightBarButtonItem = seriesController.navigationItems()
    }

    // MARK: - Data Update

    fileprivate func result(at indexPath: IndexPath) -> SeriesResult? {
        guard let results = series.pilotResults else { return nil }
        return results[indexPath.row]
    }

    // MARK: - Pinnable

    func canPinView() -> Bool {
        return myUserId != nil
    }

    func pinnedViewIndexPath() -> IndexPath? {
        guard let userId = myUserId, let results = series.pilotResults else { return nil }

        if let cached = cachedPinnedIndexPath {
            return cached
        }

        guard let index = results.firstIndex(where: { $0.pilotId == userId }) else {
            return nil
        }

        let indexPath = IndexPath(row: index, section: 0)
        cachedPinnedIndexPath = indexPath
        return indexPath
    }

    // MARK: - Actions

    func showUserProfile(forUserAt indexPath: IndexPath, from cell: AvatarTableViewCell) {
        guard let result = result(at: indexPath), let pilotId = result.pilotId else { return }

        cell.isLoading = true

        userApi.getUser(with: pilotId) { [weak self] (user, error) in
            if let user = user {
                let vc = UserViewController(with: user)
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

        showUserProfile(forUserAt: indexPath, from: cell)
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if let results = series.pilotResults, results.count > 0 {
            return series.scoreTypeString
        }
        return nil
    }
}

extension SeriesStandingsViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let results = series.pilotResults {
            return results.count
        }
        return 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(forIndexPath: indexPath) as AvatarTableViewCell
        configure(cell, forRowAt: indexPath)
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return Constants.cellHeight
    }

    func configure<T>(_ view: T, forRowAt indexPath: IndexPath) where T : UITableViewCell {
        guard let cell = view as? AvatarTableViewCell, let result = result(at: indexPath) else { return }

        // TODO: Convert to View Model
        let flag = FlagEmojiGenerator.flag(country: result.country)

        cell.rankView.rank = Int32(indexPath.row + 1)
        cell.titleLabel.text = "\(result.displayName) \(flag)"
        cell.subtitleLabel.text = nil
        cell.textPill.text = nil
        cell.avatarImageView.imageView.setImage(with: result.imageUrl, placeholderImage: PlaceholderImg.medium)
        cell.accessoryView = nil

        if series.scoreType == .fastest3laps, let time = result.time {
            cell.subtitleLabel.text = "\(TimeUtil.lapTimeFormat(seconds: time))"
        } else if series.scoreType == .collegiate {
            cell.textPill.text = result.score
            cell.textPill.style = .text

            if let time = result.time {
                cell.subtitleLabel.text = "\(TimeUtil.lapTimeFormat(seconds: time))"
            }
        } else {
            cell.subtitleLabel.text = "Elo: \(result.eloScore)"

            let unit = (result.score == "1") ? "pt" : "pts"
            cell.textPill.text = "\(result.score) \(unit)"
            cell.textPill.style = .text
        }

        if let pilotId = result.pilotId, let userId = myUserId, pilotId == userId {
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
        guard let results = series.pilotResults, results.count > 0 else { return }
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
