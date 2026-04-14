//
//  StandingsViewController.swift
//  RaceSync
//
//  Created by Ignacio Romero Zurbuchen on 2025-05-31.
//  Copyright © 2025 MultiGP Inc. All rights reserved.
//

import UIKit
import SnapKit
import RaceSyncAPI
import ShimmerSwift
import EmptyDataSet_Swift
import Presentr

class StandingsViewController: UIViewController, Shimmable, Pinnable {

    // MARK: - Public Variables

    lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.emptyDataSetSource = self
        tableView.emptyDataSetDelegate = self
        tableView.register(cellType: AvatarTableViewCell.self)
        tableView.keyboardDismissMode = .onDrag
        tableView.verticalScrollIndicatorInsets = UIEdgeInsets(top: -1, left: 0, bottom: 0, right: 0)
        tableView.refreshControl = self.refreshControl
        tableView.tableFooterView = UIView()

        let backgroundView = UIView()
        backgroundView.backgroundColor = Color.gray20
        tableView.backgroundView = backgroundView
        return tableView
    }()

    var shimmeringView: ShimmeringView = defaultShimmeringView()
    var isRootTabBar: Bool = false

    // MARK: - Private Variables

    fileprivate lazy var searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.delegate = self
        searchBar.searchBarStyle = .minimal
        searchBar.placeholder = "Filter pilots"
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

    fileprivate lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.backgroundColor = Color.gray20
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

        view.addSeparatorLine(.bottom)
        return view
    }()

    fileprivate lazy var toolbar: UIView = {
        let view = UIView()
        view.backgroundColor = Color.navigationBarColor
        view.addSeparatorLine()
        return view
    }()

    fileprivate lazy var headerSectionView: UIView = {

        let isEmpty = standingsController.isEmpty(for: season)

        let view = UIView()
        view.backgroundColor = Color.clear
        view.isUserInteractionEnabled = true

        if !isEmpty {
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = 2

            let label = UILabel()
            label.attributedText = NSAttributedString(string: headerTitle, attributes: [.paragraphStyle: paragraphStyle])
            label.font = .systemFont(ofSize: 13)
            label.textColor = UIColor(hex: "3D3D42").withAlphaComponent(0.6) //Color.gray20
            label.textAlignment = .left
            label.numberOfLines = 2

            view.addSubview(label)
            label.snp.makeConstraints {
                $0.centerY.equalToSuperview()
                $0.leading.equalToSuperview().offset(20)
            }
        }

        let buttonTitle = isEmpty ? "View Past Standings" : "Past Standings"

        let button = CustomButton(type: .system)
        button.setTitle(buttonTitle, for: .normal)
        button.titleLabel?.textAlignment = .right
        button.titleLabel?.font = .boldSystemFont(ofSize: 15)
        button.titleLabel?.numberOfLines = 2
        button.addTarget(self, action: #selector(showPastStandings), for: .touchUpInside)
        button.semanticContentAttribute = .forceRightToLeft
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: 6, bottom: 0, right: -6)
        button.tintColor = Color.blue
        button.hitTestEdgeInsets = UIEdgeInsets(proportionally: -10)

        let baseImage = SystemImg.chevronRight?.withRenderingMode(.alwaysTemplate)
        let config = UIImage.SymbolConfiguration(scale: .small)
        let resizedImage = baseImage?.applyingSymbolConfiguration(config)?.withTintColor(button.tintColor)
        button.setImage(resizedImage, for: .normal)

        view.addSubview(button)
        button.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.trailing.equalToSuperview().offset(-20)
        }

        return view
    }()

    fileprivate var headerTitle: String {
        get {
            if isRootTabBar {
                return "\(season.rawValue) MultiGP Global Qualifier\nFastest 3 Consecutive Laps".uppercased()
            } else {
                return "Fastest 3 Consecutive Laps  - \(season.pilotCount) pilots"
            }
        }
    }

    fileprivate let standingsController = StandingsController()
    fileprivate var filteredViewModels = [StandingViewModel]()
    fileprivate let season: StandingSeason
    fileprivate let userApi = UserApi()
    fileprivate let raceApi = RaceApi()

    // Pinnable variables
    var pinnedView: UIView?
    var cachedPinnedIndexPath: IndexPath?

    fileprivate let minQuery: Int = 2
    fileprivate let emptyStateSearch = EmptyStateViewModel(.noSearchResults)
    fileprivate var emptyStateError: EmptyStateViewModel? = nil
    fileprivate var presenter: Presentr?

    fileprivate var myUserId: ObjectId? {
        get { return APIServices.shared.myUser?.id }
    }

    fileprivate var myProfileUrl: String? {
        get { return APIServices.shared.myUser?.profilePictureUrl }
    }

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

        NotificationCenter.default.addObserver(self, selector: #selector(userDidTakeScreenshot), name: UIApplication.userDidTakeScreenshotNotification, object: nil )
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if !standingsController.didFetchStandings(for: season) {
            isLoadingList(true)
        } else {
            tableView.reloadData()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        hideNavigationShadow()

        if !standingsController.didFetchStandings(for: season) {
            loadContent()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        hideNavigationShadow(false)
    }

    // MARK: - Initialization

    init(with season: StandingSeason) {
        self.season = season
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Layout

    fileprivate func setupLayout() {

        configureNavigationItems()
        enableSearchBar(false)

        registerPinnedView(viewType: AvatarTableViewCell.self)

        view.addSubview(headerView)
        headerView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            $0.height.equalTo(Constants.headerViewHeight)
            $0.leading.trailing.equalToSuperview()
        }

        if !isRootTabBar {
            view.addSubview(toolbar)
            toolbar.snp.makeConstraints {
                $0.leading.trailing.equalToSuperview()
                $0.bottom.equalTo(view.snp.bottom)
                $0.height.equalTo(64)
            }
        }

        view.addSubview(tableView)
        tableView.snp.makeConstraints {
            $0.top.equalTo(headerView.snp.bottom)
            $0.leading.trailing.equalToSuperview()

            if !isRootTabBar {
                $0.bottom.equalTo(toolbar.snp.top)
                tableView.refreshControl = nil // a user doesn't need to reload this data, since it won't update
            } else {
                $0.bottom.equalTo(view.snp.bottom)
            }
        }

        view.addSubview(shimmeringView)
        shimmeringView.snp.makeConstraints {
            $0.top.equalTo(tableView.snp.top)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(view.snp.bottom)
        }
    }

    fileprivate func configureNavigationItems() {

    }

    // MARK: - Data Update

    fileprivate func loadContent() {

        if !refreshControl.isRefreshing {
            isLoadingList(true)
        }

        standingsController.fetchStandings(for: season) { objects, error in
            if let objects = objects {
                self.enableSearchBar(objects.count > 0)
            } else if let error = error {
                self.emptyStateError = EmptyStateViewModel(.error(error))
            }

            if self.refreshControl.isRefreshing {
                self.refreshControl.endRefreshing()
            } else {
                self.isLoadingList(false)
            }

            self.resetTableView()
        }
    }

    fileprivate func standingViewModel(at indexPath: IndexPath) -> StandingViewModel? {
        if isSearching {
            return filteredViewModels[indexPath.row]
        } else {
            return standingsController.viewModel(at: indexPath.row, for: season)
        }
    }



    // MARK: - Search

    fileprivate func enableSearchBar(_ enable: Bool) {
        if #available(iOS 16.4, *) {
            searchBar.alpha = enable ? 1.0 : 0.5
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

    fileprivate func currentDataSource() -> [StandingViewModel] {
        return isSearching ? filteredViewModels : standingsController.viewModels(for: season)
    }

    // MARK: - Cell Pinning

    func canPinView() -> Bool {
        guard let userId = myUserId else { return false }
        guard currentDataSource().firstIndex(where: { $0.standing.pilotId == userId }) != nil
        else { return false }
        return true
    }

    func pinnedViewIndexPath() -> IndexPath? {
        guard let userId = myUserId else { return nil }

        if let cachedPinnedIndexPath { return cachedPinnedIndexPath }

        guard let index = currentDataSource().firstIndex(where: { $0.standing.pilotId == userId }) else {
            return nil
        }

        let indexPath = IndexPath(row: index, section: 0)
        cachedPinnedIndexPath = indexPath
        return indexPath
    }

    // MARK: - Personal Standing Badge

    fileprivate func shouldPresentMyStandingBadge(_ indexPath: IndexPath) {
        guard let viewModel = standingViewModel(at: indexPath) else { return }

        let frame = CGRect(origin: .zero, size: CGSize(width: 540, height: 720))
        let badgeView = StandingBadgeView(frame: frame)

        badgeView.configureView(with: viewModel, imageUrl: myProfileUrl) { image in
            self.presentMyStandingBadge(with: image)
        }
    }

    fileprivate func presentMyStandingBadge(with image: UIImage) {
        let size = CGSize(width: 360, height: 480)
        let options: [ImageExportOptions] = [.shareto]
        let vc = ImageExportViewController(with: image, size: size, contentMode: .scaleAspectFit, options: options)

        let presenter = Presentr(presentationType: .fullScreen)
        presenter.blurBackground = false
        presenter.backgroundOpacity = 0.65
        presenter.transitionType = .crossDissolve
        presenter.dismissTransitionType = .crossDissolve
        presenter.dismissAnimated = true
        presenter.dismissOnSwipe = false
        presenter.backgroundTap = .dismiss
        presenter.outsideContextTap = .passthrough

        customPresentViewController(presenter, viewController: vc, animated: true)
        self.presenter = presenter
    }

    @objc fileprivate func userDidTakeScreenshot() {
        guard isRootTabBar else { return }

        // only trigger when this view is visible
        guard let view = viewIfLoaded, view.window != nil else { return }
        guard let cachedIndexPath = cachedPinnedIndexPath else { return }
        shouldPresentMyStandingBadge(cachedIndexPath)
    }

    fileprivate func resetTableView() {
        tableView.refreshControl = (!isRootTabBar || isSearching) ? nil : refreshControl
        tableView.setContentOffset(.zero, animated: false)
        tableView.reloadData()

        // resets it each time, so it can be recalculated
        invalidatePinnedView()
    }

    // MARK: - Actions

    fileprivate func showUserProfile(forUserAt indexPath: IndexPath, from cell: AvatarTableViewCell) {
        guard let viewModel = standingViewModel(at: indexPath) else { return }
        guard !viewModel.standing.pilotId.isEmpty else { return }

        cell.isLoading = true

        userApi.getUser(with: viewModel.standing.pilotId) { [weak self] (user, error) in
            if let user = user {
                let vc = UserViewController(with: user)
                self?.navigationController?.pushViewController(vc, animated: true)
            } else if let _ = error {
                // handle error
            }
            cell.isLoading = false
        }
    }

    fileprivate func showSeasonSchedule() {

        // show loading indicator

        let filters: [RaceListFilters] = [.upcoming, .series]
        let year = season.year

        raceApi.getRaces(with: filters, startDate: "\(year)") { [weak self]  (races, error) in

            if let races = races {
                let title = "\(year) GQ Schedule"
                let sortedViewModels = RaceViewModel.sortedViewModels(with: races, sorting: .descending)
                let vc = RaceListViewController(sortedViewModels, title: title)
                self?.navigationController?.pushViewController(vc, animated: true)
            } else if let _ = error {
                // handle error
            }
        }
    }

    @objc fileprivate func didPullRefreshControl() {
        loadContent()
    }

    @objc fileprivate func showPastStandings() {

        let standingsListVC = StandingsListViewController(with: season)
        standingsListVC.title = "Past GQ Standings"
        navigationController?.pushViewController(standingsListVC, animated: true)
    }
}

extension StandingsViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) as? AvatarTableViewCell else { return }
        tableView.deselectRow(at: indexPath, animated: true)

        // Present the standing badge instead, if it's me
        if isRootTabBar, let cachedIndexPath = cachedPinnedIndexPath, indexPath == cachedIndexPath {
            shouldPresentMyStandingBadge(indexPath)
            return
        } else {
            showUserProfile(forUserAt: indexPath, from: cell)
        }

    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard !standingsController.isEmpty(for: season) else {
            return nil
        }

        guard !isSearching else {
            if filteredViewModels.isEmpty { return nil }
            let count = filteredViewModels.count
            return count == 1 ? "Found \(count) Pilot" : "Found \(count) Pilots"
        }

        if !standingsController.isEmpty(for: season) {
            return headerTitle
        } else {
            return nil
        }
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard !shimmeringView.isShimmering else {
            return nil
        }
        guard isRootTabBar && !isSearching else {
            return nil
        }

        return headerSectionView
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if !isRootTabBar || isSearching {
            return 40
        } else {
            return 60 // 2 lines
        }
    }
}

extension StandingsViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard !standingsController.isEmpty(for: season) else {
            return 0
        }

        return currentDataSource().count
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
        guard let cell = view as? AvatarTableViewCell,
              let viewModel = standingViewModel(at: indexPath) else { return }

        cell.rankView.rank = viewModel.rank
        cell.titleLabel.text = viewModel.titleLabel
        cell.subtitleLabel.text = viewModel.subtitleLabel
        cell.avatarImageView.isHidden = true
        cell.accessoryView = nil

        if let userId = myUserId, viewModel.standing.pilotId == userId {
            cell.titleLabel.textColor = Color.white
            cell.subtitleLabel.textColor = Color.gray20
            cell.rankView.titleLabel.textColor = Color.gray20
            cell.backgroundColor = Color.gray200
            cell.selectedBackgroundView?.backgroundColor = Color.gray300

            if isRootTabBar {
                let image = ButtonImg.share?.withTintColor(.white)
                let imageView = UIImageView(image: image)
                imageView.tintColor = .white
                cell.accessoryView = imageView
            }
        } else {
            cell.titleLabel.textColor = Color.black
            cell.subtitleLabel.textColor = Color.gray300
            cell.rankView.titleLabel.textColor = Color.gray300
            cell.backgroundColor = (indexPath.row % 2 == 0) ? Color.white : Color.gray20
            cell.selectedBackgroundView?.backgroundColor = Color.gray50
        }
    }
}

extension StandingsViewController: UIScrollViewDelegate {

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        layoutPinnedView()
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

    func searchBar(_ searchBar: UISearchBar, textDidChange text: String) {

        // Matches leading parts of any word, with robust tokenization and several insensitive cases
        filteredViewModels = standingsController.filter(with: text, length: minQuery, for: season)
        resetTableView()
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = nil
        searchBar.resignFirstResponder()
        resetTableView()
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
        } else if standingsController.isEmpty(for: season) {
            let text = "There are no results for the \(season.year) Global Qualifier yet."
            return EmptyStateViewModel.attributtedStringForDescription(text)
        }
        return nil
    }

    func image(forEmptyDataSet scrollView: UIScrollView) -> UIImage? {
        guard !shimmeringView.isShimmering, !isSearching else { return nil }

        if isRootTabBar && standingsController.isEmpty(for: season) {
            return UIImage(named: "logo_gq_large")
        }
        return nil
    }

    func buttonTitle(forEmptyDataSet scrollView: UIScrollView, for state: UIControl.State) -> NSAttributedString? {
        guard !shimmeringView.isShimmering, !isSearching else { return nil }

        if isRootTabBar && standingsController.isEmpty(for: season) {
            let text = "Open The Season Schedule"
            return EmptyStateViewModel.attributtedStringForButton(text, state: .normal)
        }
        return nil
    }

    func backgroundColor(forEmptyDataSet scrollView: UIScrollView) -> UIColor?{
        guard !shimmeringView.isShimmering, !isSearching else { return nil }

        if isRootTabBar && standingsController.isEmpty(for: season) {
            return Color.white
        }
        return nil
    }

    func verticalOffset(forEmptyDataSet scrollView: UIScrollView) -> CGFloat {
        guard let tbc = tabBarController else { return 0 }
        return -tbc.tabBar.frame.height
    }

    func spaceHeight(forEmptyDataSet scrollView: UIScrollView) -> CGFloat {
        return 20
    }
}

extension StandingsViewController: EmptyDataSetDelegate {

    func emptyDataSetShouldAllowScroll(_ scrollView: UIScrollView) -> Bool {
        return false
    }

    func emptyDataSet(_ scrollView: UIScrollView, didTapButton button: UIButton) {
        showSeasonSchedule()
    }
}
