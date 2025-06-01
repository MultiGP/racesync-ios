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

    lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.emptyDataSetSource = self
        tableView.emptyDataSetDelegate = self
        tableView.tableFooterView = UIView()
        tableView.register(cellType: AvatarTableViewCell.self)
        tableView.keyboardDismissMode = .onDrag

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

    var shimmeringView: ShimmeringView = defaultShimmeringView()

    // MARK: - Private Variables

    fileprivate let standinApi = StandingApi()
    fileprivate let userApi = UserApi()

    fileprivate var standingViewModels = [StandingViewModel]()
    fileprivate var searchResult = [StandingViewModel]()

    fileprivate enum Constants {
        static let padding: CGFloat = UniversalConstants.padding
        static let cellHeight: CGFloat = 78 // UniversalConstants.cellHeight
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
            $0.height.equalTo(51)
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

        isLoadingList(true)

        standinApi.getStandings(for: .y2025) { (objects, error) in
            if let objects = objects {
                self.standingViewModels = StandingViewModel.viewModels(with: objects)
                self.enableSearchBar(objects.count > 0)
            }

            self.isLoadingList(false)
            self.tableView.reloadData()

            let indexPath = IndexPath(row: 0, section: 0)
            self.tableView.scrollToRow(at: indexPath, at: .top, animated: false)
        }
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
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.count >= 2 || trimmed.containsEmoji
    }

    func filterResults(query: String) -> [StandingViewModel] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 || trimmed.containsEmoji else { return [] }

        let normalizedQuery = trimmed.lowercased().folding(options: .diacriticInsensitive, locale: .current)

        return standingViewModels.filter { viewModel in
            let label = viewModel.titleLabel

            if trimmed.containsEmoji {
                // Emoji-based filtering
                return label.contains(trimmed)
            } else {
                // Word prefix filtering
                let words = label.lowercased()
                    .folding(options: .diacriticInsensitive, locale: .current)
                    .components(separatedBy: CharacterSet.alphanumerics.inverted)
                    .filter { !$0.isEmpty }

                return words.contains { $0.hasPrefix(normalizedQuery) }
            }
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

    func tableView(_ tableView: UITableView, titleForHeaderInSection sectionIdx: Int) -> String? {
        guard !isSearching || standingViewModels.count > 0 else { return nil }
        return "2025 Global Qualifier (Mar 29 - Aug 25)"
    }
}

extension StandingsViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard !isSearching else { return searchResult.count }
        return standingViewModels.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(forIndexPath: indexPath) as AvatarTableViewCell
        cell.avatarImageView.isHidden = true
        cell.backgroundColor = (indexPath.row % 2 == 0) ? Color.white : UIColor(hex: "f2f5f7")

        let viewModels = isSearching ? searchResult : standingViewModels
        let viewModel = viewModels[indexPath.row]
        cell.rankView.rank = viewModel.rank
        cell.titleLabel.text = viewModel.titleLabel
        cell.subtitleLabel.text = viewModel.subtitleLabel
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return Constants.cellHeight
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
        searchResult = filterResults(query: searchText)
        tableView.reloadData()
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = nil
        searchBar.resignFirstResponder()
        tableView.reloadData()
    }
}

extension StandingsViewController: EmptyDataSetSource {

//    func getEmptyStateViewModel() -> EmptyStateViewModel {
//        switch selectedRaceFilter {
//        case .joined:       return emptyStateJoinedRaces
//        case .nearby:       return emptyStateNearbyRaces
//        case .chapters:     return emptyStateChapterRaces
//        case .series:       return emptyStateSeriesRaces
//        default:            return EmptyStateViewModel(.noRaceResults)
//        }
//    }
//
//    func title(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
//        return getEmptyStateViewModel().title
//    }
//
//    func description(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
//        return getEmptyStateViewModel().description
//    }
//
//    func image(forEmptyDataSet scrollView: UIScrollView) -> UIImage? {
//        return nil
//    }
//
//    func buttonTitle(forEmptyDataSet scrollView: UIScrollView, for state: UIControl.State) -> NSAttributedString? {
//        return getEmptyStateViewModel().buttonTitle(state)
//    }
//
//    func verticalOffset(forEmptyDataSet scrollView: UIScrollView) -> CGFloat {
//        return -(navigationController?.navigationBar.frame.height ?? 0)
//    }
}

extension StandingsViewController: EmptyDataSetDelegate {

}
