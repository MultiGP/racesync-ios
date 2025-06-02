//
//  StandingsViewController.swift
//  RaceSync
//
//  Created by Ignacio Romero Zurbuchen on 2020-03-05.
//  Copyright © 2020 MultiGP Inc. All rights reserved.
//

import UIKit
import SnapKit
import RaceSyncAPI
import ShimmerSwift
import EmptyDataSet_Swift

class StandingsViewController: UIViewController, Shimmable {

    // MARK: - Public Variables

    lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.emptyDataSetSource = self
        tableView.tableFooterView = UIView()
        tableView.register(cellType: AvatarTableViewCell.self)
        tableView.keyboardDismissMode = .onDrag
        tableView.verticalScrollIndicatorInsets = UIEdgeInsets(top: -1, left: 0, bottom: 0, right: 0)
        tableView.refreshControl = self.refreshControl

        let backgroundView = UIView()
        backgroundView.backgroundColor = Color.gray20
        tableView.backgroundView = backgroundView

        return tableView
    }()

    fileprivate lazy var searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.delegate = self
        searchBar.searchBarStyle = .minimal
        searchBar.placeholder = "Filter pilots"
        searchBar.barTintColor = .white
        searchBar.isTranslucent = false
        searchBar.backgroundImage = UIImage()
        searchBar.tintColor = Color.blue
        return searchBar
    }()

    fileprivate lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.backgroundColor = Color.white
        refreshControl.tintColor = Color.blue
        refreshControl.addTarget(self, action: #selector(didPullRefreshControl), for: .valueChanged)
        return refreshControl
    }()

    fileprivate lazy var headerView: UIView = {
        let view = UIView()
        view.backgroundColor = Color.navigationBarColor
        view.tintColor = Color.blue

        view.addSubview(searchBar)
        searchBar.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.leading.equalToSuperview().offset(Constants.padding)
            $0.trailing.equalToSuperview().offset(-Constants.padding)
            $0.height.equalTo(Constants.searchBarHeight)
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

    var shimmeringView: ShimmeringView = defaultShimmeringView()

    // MARK: - Private Variables

    fileprivate let standinApi = StandingApi()
    fileprivate let userApi = UserApi()

    fileprivate var standingViewModels = [StandingViewModel]()
    fileprivate var searchResult = [StandingViewModel]()
    fileprivate var pinnedView: UIView?

    fileprivate let minQuery: Int = 2
    fileprivate let emptyStateSearch = EmptyStateViewModel(.noSearchResults)
    fileprivate var emptyStateError: EmptyStateViewModel? = nil

    fileprivate enum Constants {
        static let padding: CGFloat = UniversalConstants.padding
        static let cellHeight: CGFloat = 80
        static let headerViewHeight: CGFloat = 51
        static let searchBarHeight: CGFloat = 56
    }

    // MARK: - Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()

        setupLayout()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if standingViewModels.count == 0 {
            loadStandings()
        } else {
            tableView.reloadData()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    // MARK: - Layout

    fileprivate func setupLayout() {

        configureNavigationItems()
        enableSearchBar(false)

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
        title = "Standings"
        tabBarItem = UITabBarItem(title: "Standings", image: UIImage(systemName:"trophy"), selectedImage: UIImage(systemName:"trophy.fill"))
    }

    // MARK: - Data Update

    func loadStandings() {

        if !refreshControl.isRefreshing {
            isLoadingList(true)
        }

        standinApi.getStandings(for: .y2025) { (objects, error) in
            if let objects = objects {
                self.standingViewModels = StandingViewModel.viewModels(with: objects)
                self.enableSearchBar(objects.count > 0)
            } else if error != nil {
                self.emptyStateError = EmptyStateViewModel(.errorStandings)
            }

            if self.refreshControl.isRefreshing {
                self.refreshControl.endRefreshing()
            } else {
                self.isLoadingList(false)
            }

            self.tableView.reloadData()
            self.layoutPinnedCell()
        }
    }

    fileprivate var pinnedCellIndexPath: IndexPath? {
        get {
            guard let myUser = APIServices.shared.myUser else { return nil }

            if isSearching, searchResult.count > 0 {
                if let index = searchResult.firstIndex(where: { $0.standing.userId == myUser.id }) {
                    return IndexPath(row: index, section: 0)
                }
            } else if !isSearching, standingViewModels.count > 0 {
                if let index = standingViewModels.firstIndex(where: { $0.standing.userId == myUser.id }) {
                    return IndexPath(row: index, section: 0)
                }
            }
            return nil
        }
    }

    @objc fileprivate func didPullRefreshControl() {
        loadStandings()
    }

    // MARK: - Search

    fileprivate func enableSearchBar(_ enable: Bool) {
        if #available(iOS 16.4, *) {
            searchBar.isEnabled = enable
        } else {
            searchBar.alpha = enable ? 1.0 : 0.5
            searchBar.isUserInteractionEnabled = enable
        }
    }

    fileprivate var isSearching: Bool {
        guard let text = searchBar.text else { return false }
        let query = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return query.count >= minQuery || query.containsEmoji
    }

    func filterResults(with text: String) -> [StandingViewModel] {
        let query = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard query.count >= minQuery || query.containsEmoji else { return [] }

        let normalizedQuery = query.lowercased().folding(options: .diacriticInsensitive, locale: .current)

        return standingViewModels.filter { viewModel in
            let label = viewModel.titleLabel

            if query.containsEmoji {
                return label.contains(query)
            } else {
                let words = label.lowercased()
                    .folding(options: .diacriticInsensitive, locale: .current)
                    .components(separatedBy: CharacterSet.alphanumerics.inverted)
                    .filter { !$0.isEmpty }
                return words.contains { $0.hasPrefix(normalizedQuery) }
            }
        }
    }

    // MARK: - Cell Pinning

    func layoutPinnedCell() {
        guard let indexPath = pinnedCellIndexPath else { return }
        guard let _ = tableView.superview else { return }

        let cellRect = tableView.rectForRow(at: indexPath)
        let topInset = tableView.contentInset.top
        let bottomInset = tableView.contentInset.bottom
        let contentOffsetY = tableView.contentOffset.y
        let visibleHeight = tableView.bounds.height - topInset - bottomInset
        let tabBarHeight = tabBarController?.tabBar.frame.size.height ?? 0

        let targetTopOffsetY = cellRect.minY - topInset
        let targetBottomOffsetY = cellRect.maxY + tabBarHeight - visibleHeight

        let cellHeight = tableView.delegate?.tableView?(tableView, heightForRowAt: indexPath) ?? cellRect.height
        let cellWidth = tableView.frame.width

        let topPinY = tableView.frame.minY
        let bottomPinY = tableView.frame.maxY - bottomInset - cellHeight - tabBarHeight

        // Pin to top
        if contentOffsetY >= targetTopOffsetY {
            showPinnedCell(at: topPinY, indexPath: indexPath, size: CGSize(width: cellWidth, height: cellHeight))

        // Pin to bottom
        } else if contentOffsetY <= targetBottomOffsetY {
            showPinnedCell(at: bottomPinY, indexPath: indexPath, size: CGSize(width: cellWidth, height: cellHeight))
        } else {
            removePinnedCell()
        }
    }

    fileprivate func showPinnedCell(at y: CGFloat, indexPath: IndexPath, size: CGSize) {
        if pinnedView == nil {
            let snapshot = createSnapshotFromCell(forRowAt: indexPath)
            pinnedView = snapshot
            pinnedView?.frame = CGRect(origin: CGPoint(x: 0, y: y), size: size)
            pinnedView?.layer.zPosition = 999
        } else {
            pinnedView?.frame.origin.y = y
        }

        if let pinnedView = pinnedView, pinnedView.superview == nil {
            view.insertSubview(pinnedView, aboveSubview: tableView)
        }
    }

    fileprivate func createSnapshotFromCell(forRowAt indexPath: IndexPath) -> UIView? {
        let cell = AvatarTableViewCell(style: .default, reuseIdentifier: nil)
        configure(tableViewCell: cell, forRowAt: indexPath)

        let cellWidth = tableView.bounds.width
        let cellHeight = tableView.delegate?.tableView?(tableView, heightForRowAt: indexPath) ?? tableView.rowHeight
        cell.frame = CGRect(x: 0, y: 0, width: cellWidth, height: cellHeight)

        cell.contentView.setNeedsLayout()
        cell.contentView.layoutIfNeeded()

        cell.setNeedsLayout()
        cell.layoutIfNeeded()

        // Create a snapshot of the cell’s current rendered content
        let snapshot = cell.snapshotView(afterScreenUpdates: true)
        snapshot?.clipsToBounds = true
        snapshot?.tag = indexPath.row

        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapPinnedCell(_:)))
        snapshot?.addGestureRecognizer(tap)

        return snapshot
    }

    @objc fileprivate func didTapPinnedCell(_ gesture: UITapGestureRecognizer) {
        guard let indexPath = pinnedCellIndexPath else { return }
        tableView.scrollToRow(at: indexPath, at: .middle, animated: true)
    }

    fileprivate func removePinnedCell() {
        guard let view = pinnedView else { return }

        if view.superview != nil {
            view.removeFromSuperview()
        }
    }
}

extension StandingsViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) as? AvatarTableViewCell else { return }
        cell.isLoading = true

        let viewModels = isSearching ? searchResult : standingViewModels
        let viewModel = viewModels[indexPath.row]
        guard !viewModel.standing.userId.isEmpty else { return }

        userApi.getUser(with: viewModel.standing.userId) { [weak self] (user, error) in
            if let user = user {
                let vc = UserViewController(with: user)
                self?.navigationController?.pushViewController(vc, animated: true)
            } else if let _ = error {
                // handle error
            }
            cell.isLoading = false
        }

        tableView.deselectRow(at: indexPath, animated: true)
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard !(isSearching && searchResult.isEmpty), !standingViewModels.isEmpty else {
            return nil
        }
        return "2025 MultiGP Global Qualifier (Mar 29 - Aug 25)"
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 35
    }
}

extension StandingsViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard !isSearching else { return searchResult.count }
        return standingViewModels.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(forIndexPath: indexPath) as AvatarTableViewCell
        configure(tableViewCell: cell, forRowAt: indexPath)
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return Constants.cellHeight
    }

    func configure(tableViewCell cell: AvatarTableViewCell, forRowAt indexPath: IndexPath) {

        cell.avatarImageView.isHidden = true

        let viewModels = isSearching ? searchResult : standingViewModels
        let viewModel = viewModels[indexPath.row]
        cell.rankView.rank = viewModel.rank
        cell.titleLabel.text = viewModel.titleLabel
        cell.subtitleLabel.text = viewModel.subtitleLabel

        if let myUser = APIServices.shared.myUser, viewModel.standing.userId == myUser.id {
            cell.backgroundColor = UIColor(hex: "898b8c")
            cell.titleLabel.textColor = Color.white
            cell.subtitleLabel.textColor = Color.gray20
            cell.rankView.titleLabel.textColor = Color.gray20
        } else {
            cell.backgroundColor = (indexPath.row % 2 == 0) ? Color.white : UIColor(hex: "f7f9fa")
            cell.titleLabel.textColor = Color.black
            cell.subtitleLabel.textColor = Color.gray300
            cell.rankView.titleLabel.textColor = Color.gray300
        }
    }
}

extension StandingsViewController: UIScrollViewDelegate {

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        layoutPinnedCell()
    }
}

extension StandingsViewController: ScrollToTop {
    
    func scrollToTop() {
        tableView.setContentOffset(.zero, animated: true)
    }
}

extension StandingsViewController: UISearchBarDelegate {

    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        searchBar.setShowsCancelButton(true, animated: true)
        return true
    }

    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {

    }

    func searchBarShouldEndEditing(_ searchBar: UISearchBar) -> Bool {
        return true
    }

    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(false, animated: true)
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {

        // Matches leading parts of any word, with robust tokenization and several insensitive cases
        searchResult = filterResults(with: searchText)

        tableView.setContentOffset(.zero, animated: false)
        tableView.reloadData()
        layoutPinnedCell()
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = nil
        searchBar.resignFirstResponder()
        tableView.reloadData()
        layoutPinnedCell()
    }
}

extension StandingsViewController: EmptyDataSetSource {

    func title(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        guard !shimmeringView.isShimmering else { return nil }

        if emptyStateError != nil {
            return emptyStateError?.title
        } else if isSearching {
            return emptyStateSearch.title
        }
        return nil
    }

    func description(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        guard !shimmeringView.isShimmering else { return nil }

        if emptyStateError != nil {
            return emptyStateError?.description
        } else if isSearching {
            return emptyStateSearch.description
        }
        return nil
    }

    func verticalOffset(forEmptyDataSet scrollView: UIScrollView) -> CGFloat {
        return -(navigationController?.navigationBar.frame.height ?? 0)
    }
}
