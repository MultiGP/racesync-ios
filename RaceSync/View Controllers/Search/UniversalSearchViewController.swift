//
//  UniversalSearchViewController.swift
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

fileprivate typealias SearchResults = [Section : [Any]]
fileprivate typealias SearchResultsCompletionBlock = (_ results: SearchResults, _ error: NSError?) -> Void

class UniversalSearchViewController: UIViewController, Shimmable {

    // MARK: - Private Variables

    lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(cellType: RaceTableViewCell.self)
        tableView.register(cellType: AvatarTableViewCell.self)
        tableView.register(cellType: ChapterTableViewCell.self)
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

    fileprivate lazy var segmentedControl: UISegmentedControl = {
        let control = UISegmentedControl()
        control.addTarget(self, action: #selector(didChangeSegment), for: .valueChanged)
        control.isEnabled = false

        for section in Section.allCases {
            control.insertSegment(withTitle: section.title, at: section.index, animated: false)
        }
        return control
    }()


    fileprivate lazy var headerView: UIView = {
        let view = UIView()
        view.backgroundColor = Color.navigationBarColor
        view.tintColor = Color.blue

        let spacing = 10

        view.addSubview(searchBar)
        searchBar.snp.makeConstraints {
            $0.top.equalToSuperview()
            $0.leading.equalToSuperview().offset(Constants.padding)
            $0.trailing.equalToSuperview().offset(-Constants.padding)
            $0.height.equalTo(Constants.searchBarHeight)
        }

        view.addSubview(segmentedControl)
        segmentedControl.snp.makeConstraints {
            $0.top.equalTo(searchBar.snp.bottom).offset(spacing)
            $0.leading.equalTo(searchBar.snp.leading).offset(8)
            $0.trailing.equalTo(searchBar.snp.trailing).offset(-8)
            $0.bottom.equalToSuperview().offset(-spacing)
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

    fileprivate var searchResults = SearchResults()
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
        static let searchBarHeight: CGFloat = 56
        static let headerViewHeight: CGFloat = 110
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

        selectedSection = .races
    }

    fileprivate func configureNavigationItems() {
        title = "Universal Search"

        navigationItem.leftBarButtonItem = UIBarButtonItem(image: ButtonImg.close, style: .done, target: self, action: #selector(didPressCloseButton))
    }

    // MARK: - Data

    fileprivate func startSearch(with text: String) {
        let query = text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        if query.count >= minQuery {
            guard !query.containsEmoji else { return }

            isLoadingList(true)
            searchResults = SearchResults()
            resetTableView()

            search(with: query) { [weak self] results, error in
                self?.searchResults = results
                self?.resetTableView()
                self?.updateAllSegments()
                self?.isLoadingList(false)
            }
        } else {
            searchResults = SearchResults()
            resetTableView()
            updateAllSegments()
        }

        invalidateSearchDebounce()
    }

    fileprivate func search(with query: String, _ completion: @escaping SearchResultsCompletionBlock) {

        // Cancel any pending search requests
        cancelSearchRequests()

        let id = Int(query) != nil ? query : ""
        let name = Int(query) == nil ? query : ""

        var results = SearchResults()
        var firstError: NSError?

        let group = DispatchGroup()

        // Races
        group.enter()
        raceApi.getRaces(with: [], raceId: id, name: name) { objects, error in
            defer { group.leave() }

            if let races = objects {
                results[.races] = RaceViewModel.sortedViewModels(with: races, sorting: .ascending) as [Any]
            } else if let error = error, firstError == nil {
                firstError = error
            }
        }

        // Users
        group.enter()
        userApi.searchUser(with: query) { object, error in
            defer { group.leave() }

            if let user = object {
                results[.users] = UserViewModel.viewModels(with: [user])
            } else if let error = error, firstError == nil {
                firstError = error
            }
        }

        // Chapters
        group.enter()
        chapterApi.searchChapter(with: query) { object, error in
            defer { group.leave() }

            if let chapter = object {
                results[.chapters] = ChapterViewModel.viewModels(with: [chapter])
            } else if let error = error, firstError == nil {
                firstError = error
            }
        }

        // Single completion, once all three calls finished
        group.notify(queue: .main) {
            completion(results, firstError)
        }
    }

    fileprivate func cancelSearchRequests() {
        raceApi.cancelSearchRequests()
        userApi.cancelSearchRequests()
        chapterApi.cancelSearchRequests()
    }

    fileprivate var totalNumberOfItems: Int {
        Section.allCases.reduce(0) { total, section in
            total + (searchResults[section]?.count ?? 0)
        }
    }

    fileprivate func numberOfItems(in section: Section) -> Int {
        guard let objects = searchResults[section] else { return 0 }
        return objects.count
    }

    fileprivate func raceViewModel(for index: Int) -> RaceViewModel? {
        return viewModel(for: .races, at: index) as RaceViewModel?
    }

    fileprivate func userViewModel(for index: Int) -> UserViewModel? {
        return viewModel(for: .users, at: index) as UserViewModel?
    }

    fileprivate func chapterViewModel(for index: Int) -> ChapterViewModel? {
        return viewModel(for: .chapters, at: index) as ChapterViewModel?
    }

    fileprivate func viewModel<T>(for section: Section, at index: Int) -> T? {
        guard let results = searchResults[section] as? [T],
            results.indices.contains(index)
        else { return nil }
        return results[index]
    }

    fileprivate var selectedSectionIdx: Int {
        return segmentedControl.selectedSegmentIndex
    }

    fileprivate var selectedSection: Section {
        get {
            return Section(index: selectedSectionIdx)
        }
        set {
            segmentedControl.selectedSegmentIndex = newValue.index
        }
    }

    fileprivate func updateAllSegments() {
        Section.allCases.forEach { section in
            let count = searchResults[section]?.count ?? 0
            updateSegment(for: section, with: count)
        }
    }

    fileprivate func updateSegment(for section: Section, with count: Int) {
        var title = section.title(with: count)
        if !isSearching { title = section.title }

        segmentedControl.setTitle(title, forSegmentAt: section.index)
    }

    fileprivate func resetTableView() {
        segmentedControl.isEnabled = (totalNumberOfItems > 0)
        tableView.setContentOffset(.zero, animated: false)
        tableView.reloadData()
    }

    fileprivate func invalidateSearchDebounce() {
        searchDebounceTimer?.invalidate()
        searchDebounceTimer = nil
    }

    // MARK: - Actions

    @objc fileprivate func didChangeSegment() {
        resetTableView()
    }

    @objc fileprivate func didPressCloseButton() {
        searchBar.resignFirstResponder()
        dismiss(animated: true)
    }
}

extension UniversalSearchViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return Section.allCases.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard isSearching else { return 0 }

        if section == selectedSectionIdx {
            return numberOfItems(in: selectedSection)
        } else {
            return 0
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch selectedSection {
        case .races:    return raceTableViewCell(for: indexPath)
        case .users:    return userTableViewCell(for: indexPath)
        case .chapters: return chapterTableViewCell(for: indexPath)
        }
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

    func userTableViewCell(for indexPath: IndexPath) -> AvatarTableViewCell {
        let cell = tableView.dequeueReusableCell(forIndexPath: indexPath) as AvatarTableViewCell
        guard let viewModel = userViewModel(for: indexPath.row) else { return cell }

        cell.titleLabel.text = viewModel.displayName
        cell.avatarImageView.imageView.setImage(with: viewModel.pictureUrl, placeholderImage: PlaceholderImg.medium, size: Constants.avatarImageSize)
        cell.subtitleLabel.text = viewModel.fullName
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    func chapterTableViewCell(for indexPath: IndexPath) -> ChapterTableViewCell {
        let cell = tableView.dequeueReusableCell(forIndexPath: indexPath) as ChapterTableViewCell
        guard let viewModel = chapterViewModel(for: indexPath.row) else { return cell }

        cell.titleLabel.text = viewModel.titleLabel
        cell.subtitleLabel.text = viewModel.locationLabel
        cell.avatarImageView.imageView.setImage(with: viewModel.imageUrl, placeholderImage: PlaceholderImg.medium, size: Constants.avatarImageSize)
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UniversalConstants.cellHeight
    }
}

extension UniversalSearchViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        var vc: UIViewController?

        switch selectedSection {
        case .races:
            guard let vm = raceViewModel(for: indexPath.row) else { return }
            vc = RaceTabBarController(with: vm.race)
        case .users:
            guard let vm = userViewModel(for: indexPath.row) else { return }
            if let user = vm.user {
                vc = UserViewController(with: user)
            }
        case .chapters:
            guard let vm = chapterViewModel(for: indexPath.row) else { return }
            vc = ChapterViewController(with: vm.chapter)
        }

        if let vc = vc {
            vc.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(vc, animated: true)
        }
    }
}


extension UniversalSearchViewController: UISearchBarDelegate {

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

        if searchText.count > 0 {
            // Cancel the previous pending search
            invalidateSearchDebounce()

            // Start a new debounce timer
            searchDebounceTimer = Timer.scheduledTimer(withTimeInterval: searchDebounceInterval, repeats: false) { [weak self] _ in
                self?.startSearch(with: searchText)
            }
        } else {
            startSearch(with: searchText)
        }
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = nil
        searchBar.resignFirstResponder()
        resetTableView()
    }
}

extension UniversalSearchViewController: EmptyDataSetSource {

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

fileprivate enum Section: EnumTitle {
    case races, users, chapters

    var title: String { plural }

    init(index: Int) {
        self = Section.allCases[safe: index] ?? .races
    }

    // Dynamic index based on position in allCases
    var index: Int { Section.allCases.firstIndex(of: self) ?? 0 }

    func title(with count: Int) -> String {
        let word = (count == 1) ? singular : plural
        return "\(count) \(word)"
    }

    private var singular: String {
        switch self {
        case .races:    return "Race"
        case .users:    return "User"
        case .chapters: return "Chapter"
        }
    }

    private var plural: String { "\(singular)s" }
}
