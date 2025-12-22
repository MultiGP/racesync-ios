//
//  SearchViewController.swift
//  RaceSync
//
//  Created by Ignacio Romero Zurbuchen on 2025-12-09.
//  Copyright © 2025 MultiGP Inc. All rights reserved.
//

import UIKit
import SnapKit
import RaceSyncAPI
import EmptyDataSet_Swift
import ShimmerSwift

class SearchViewController: UIViewController, Shimmable {

    // MARK: - Private Variables

    lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(cellType: RaceTableViewCell.self)
        tableView.emptyDataSetSource = self
        tableView.tableFooterView = UIView()
        tableView.keyboardDismissMode = .interactive
        return tableView
    }()

    let shimmeringView: ShimmeringView = defaultShimmeringView()

    // MARK: - Private Variables

    fileprivate lazy var searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.delegate = self
        searchBar.searchBarStyle = .minimal
        searchBar.placeholder = "Search by name or id"
        searchBar.barTintColor = .white
        searchBar.isTranslucent = false
        searchBar.backgroundImage = UIImage()
        searchBar.tintColor = Color.blue
        searchBar.showsSearchResultsButton = false

        if let textField = searchBar.value(forKey: "searchField") as? UITextField {
            textField.returnKeyType = .done
        }

        return searchBar
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

    fileprivate let raceApi = RaceApi()
    fileprivate let userApi = UserApi()
    fileprivate let chapterApi = ChapterApi()

    fileprivate var searchResult = [RaceViewModel]()
    fileprivate let minQuery: Int = 3
    fileprivate var searchDebounceTimer: Timer?
    fileprivate let searchDebounceInterval: TimeInterval = 0.5

    fileprivate let emptyStateSearch = EmptyStateViewModel(.noSearchResults)

    fileprivate var isSearching: Bool {
        guard let text = searchBar.text else { return false }
        let query = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return query.count >= minQuery || query.containsEmoji
    }

    fileprivate enum Constants {
        static let padding: CGFloat = UniversalConstants.padding
        static let avatarImageSize = CGSize(width: 50, height: 50)
        static let headerViewHeight: CGFloat = 51
        static let searchBarHeight: CGFloat = 56
    }

    // MARK: - Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()

        configureNavigationItems()
        setupLayout()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        hideNavigationShadow()
        searchBar.becomeFirstResponder()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if let nc = navigationController, nc.viewControllers.count == 2 {
            hideNavigationShadow(false)
        }

        searchBar.resignFirstResponder()
    }

    deinit {
        invalidateSearchDebounce()
    }

    // MARK: - Layout

    fileprivate func setupLayout() {

        view.backgroundColor = Color.white

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
        title = "Search Race"

        navigationItem.leftBarButtonItem = UIBarButtonItem(image: ButtonImg.close, style: .done, target: self, action: #selector(didPressCloseButton))
    }

    fileprivate func hideNavigationShadow(_ hide: Bool = true) {
        guard let nc = navigationController else { return }

        // By masking to bounds, the shadow of a navigation bar is no longer visible
        // This trick only works when the backgroud of view behind the navigation bar is the same color
        // It cannot be used for transitioning to more complicated views.
        nc.navigationBar.layer.masksToBounds = hide

//        let appearance = UINavigationBarAppearance()
//        appearance.configureWithOpaqueBackground()
//        appearance.shadowColor = .clear
//
//        navigationController?.navigationBar.standardAppearance = appearance
//        navigationController?.navigationBar.scrollEdgeAppearance = appearance
    }

    // MARK: - Data

    fileprivate func startSearch(with text: String) {
        let query = text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        if query.count >= minQuery {
            guard !query.containsEmoji else { return }

            isLoadingList(true)
            searchResult = [RaceViewModel]()
            resetTableView()

            searchRaces(with: query) { [weak self] viewModels, cached, error in
                if let viewModels = viewModels {
                    self?.searchResult = viewModels
                } else {
                    self?.searchResult = [RaceViewModel]()
                }

                self?.resetTableView()
                self?.isLoadingList(false)
            }
        } else {
            searchResult = [RaceViewModel]()
            resetTableView()
        }

        invalidateSearchDebounce()
    }

    fileprivate func resetTableView() {
        tableView.setContentOffset(.zero, animated: false)
        tableView.reloadData()
    }

    fileprivate func invalidateSearchDebounce() {
        searchDebounceTimer?.invalidate()
        searchDebounceTimer = nil
    }

    fileprivate func searchRaces(with query: String, _ completion: @escaping RaceFeedControllerCompletionBlock<[RaceViewModel]>) {
        // TODO: Write a separate completion handler

        // Cancel any pending search requests
        cancelSearchRequests()

        let raceId = Int(query) != nil ? query : ""
        let raceName = Int(query) == nil ? query : ""

        raceApi.getRaces(with: [], raceId: raceId, name: raceName) { races, error in
            if let races = races {
                let sortedViewModels = RaceViewModel.sortedViewModels(with: races, sorting: .ascending)
                completion(sortedViewModels, false, nil)
            } else {
                completion(nil, false, error)
            }
        }
    }

    fileprivate func cancelSearchRequests() {
        raceApi.cancelSearchRequests()
        userApi.cancelSearchRequests()
        chapterApi.cancelSearchRequests()
    }

    fileprivate func raceViewModel(for index: Int) -> RaceViewModel? {
        if index >= 0, index < searchResult.count {
            return searchResult[index]
        }
        return nil
    }

    // MARK: - Actions

    @objc fileprivate func didPressCloseButton() {
        searchBar.resignFirstResponder()
        dismiss(animated: true)
    }
}

extension SearchViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        guard let viewModel = raceViewModel(for: indexPath.row) else { return }

        let vc = RaceTabBarController(with: viewModel.race)
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard searchResult.count > 0 else { return nil }
        return "\(searchResult.count) race\(searchResult.count > 1 ? "s": "") found"
    }
}

extension SearchViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard isSearching else { return 0 }
        return searchResult.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return raceTableViewCell(for: indexPath)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return RaceTableViewCell.height
    }

    func raceTableViewCell(for indexPath: IndexPath) -> RaceTableViewCell {
        let cell = tableView.dequeueReusableCell(forIndexPath: indexPath) as RaceTableViewCell
        guard let viewModel = raceViewModel(for: indexPath.row) else { return cell }

        cell.dateLabel.text = viewModel.startDateLabel //"Saturday Sept 14 @ 9:00 AM"
        cell.titleLabel.text = viewModel.titleLabel
        cell.subtitleLabel.text = viewModel.chapterLabel
        cell.joinButton.isHidden = true
        cell.memberBadgeView.isHidden = true
        cell.avatarImageView.imageView.setImage(with: viewModel.imageUrl, placeholderImage: PlaceholderImg.medium, size: Constants.avatarImageSize)
        cell.accessoryType = .disclosureIndicator
        return cell
    }
}

extension SearchViewController: UISearchBarDelegate {

    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        return true
    }

    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {

    }

    func searchBarShouldEndEditing(_ searchBar: UISearchBar) -> Bool {
        return true
    }

    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {

    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        guard !searchText.trimmingCharacters(in: .whitespaces).isEmpty else {
            return
        }

        // Cancel the previous pending search
        invalidateSearchDebounce()

        // Start a new debounce timer
        searchDebounceTimer = Timer.scheduledTimer(withTimeInterval: searchDebounceInterval, repeats: false) { [weak self] _ in
            self?.startSearch(with: searchText)
        }
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = nil
        searchBar.resignFirstResponder()
        resetTableView()
    }
}

extension SearchViewController: EmptyDataSetSource {

    func title(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        if isSearching {
            return emptyStateSearch.title
        }
        return nil
    }

    func verticalOffset(forEmptyDataSet scrollView: UIScrollView) -> CGFloat {
        return -scrollView.frame.height/10
    }
}
