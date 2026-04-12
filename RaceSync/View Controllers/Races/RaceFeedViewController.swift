//
//  RaceFeedViewController.swift
//  RaceSync
//
//  Created by Ignacio Romero Zurbuchen on 2019-11-14.
//  Copyright © 2019 MultiGP Inc. All rights reserved.
//

import UIKit
import RaceSyncAPI
import SnapKit
import ShimmerSwift
import EmptyDataSet_Swift
import CoreLocation

/**
 Main view of the application, displaying lists of races filtered by different toggles. This view is very specific to that use case.
 For a more generic display of races, use RaceListViewController.
 */
class RaceFeedViewController: UIViewController, ViewJoinable, Shimmable, RaceEditable {

    // MARK: - Public Variables

    lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.emptyDataSetSource = self
        tableView.emptyDataSetDelegate = self
        tableView.register(cellType: RaceTableViewCell.self)
        tableView.refreshControl = self.refreshControl
        tableView.tableFooterView = UIView()
        tableView.contentInsetAdjustmentBehavior = .always

        for direction in [UISwipeGestureRecognizer.Direction.left, UISwipeGestureRecognizer.Direction.right] {
            let gesture = UISwipeGestureRecognizer(target: self, action: #selector(didSwipeHorizontally(_:)))
            gesture.direction = direction
            tableView.addGestureRecognizer(gesture)
        }

        let longPress = UILongPressGestureRecognizer(target: self,action: #selector(didLongPress(_:)))
        longPress.minimumPressDuration = 0.3
        longPress.delaysTouchesBegan = true
        tableView.addGestureRecognizer(longPress)

        return tableView
    }()

    var shimmeringView: ShimmeringView = defaultShimmeringView()
    var raceController: RaceController?

    // MARK: - Private Variables

    fileprivate lazy var headerView: UIView = {
        let view = UIView()
        view.backgroundColor = Color.navigationBarColor
        view.tintColor = Color.blue

        let spacing = 10

        view.addSubview(searchButton)
        searchButton.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.leading.equalToSuperview().offset(Constants.padding)
            $0.width.equalTo(30)
        }

        view.addSubview(filterButton)
        filterButton.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.trailing.equalToSuperview().offset(-Constants.padding)
            $0.width.equalTo(30)
        }

        view.addSubview(segmentedControl)
        segmentedControl.snp.makeConstraints {
            $0.top.equalToSuperview().offset(spacing)
            $0.leading.equalTo(searchButton.snp.trailing).offset(spacing)
            $0.trailing.equalTo(filterButton.snp.leading).offset(-spacing)
            $0.bottom.equalToSuperview().offset(-spacing)
        }

        view.addSeparatorLine(.bottom)
        return view
    }()

    fileprivate lazy var segmentedControl: UISegmentedControl = {
        let control = UISegmentedControl()
        control.addTarget(self, action: #selector(didChangeSegment), for: .valueChanged)
        return control
    }()

    fileprivate lazy var searchButton: CustomButton = {
        let button = CustomButton(type: .system)
        button.addTarget(self, action: #selector(didPressSearchButton), for: .touchUpInside)
        button.setImage(SystemImg.search, for: .normal)
        button.isHidden = !isRaceSearchEnabled
        return button
    }()

    fileprivate lazy var filterButton: CustomButton = {
        let button = CustomButton(type: .system)
        button.addTarget(self, action: #selector(didPressFilterButton), for: .touchUpInside)
        button.setImage(ButtonImg.filter, for: .normal)
        return button
    }()

    fileprivate lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.backgroundColor = Color.white
        refreshControl.tintColor = Color.blue
        refreshControl.addTarget(self, action: #selector(didPullRefreshControl), for: .valueChanged)
        return refreshControl
    }()

    fileprivate var selectedRaceFilter: RaceFilter {
        get {
            let title: String = segmentedControl.titleForSelectedSegment()!
            return RaceFilter.filters(with: [title]).first!
        }
    }

    func raceViewModel(for index: Int) -> RaceViewModel? {
        guard let list = raceFeedController.viewModels(for: selectedRaceFilter) else { return nil }
        if index >= 0, index < list.count {
            return list[index]
        }
        return nil
    }

    fileprivate var feedCount: Int {
        get { return raceFeedController.viewModelsCount(for: selectedRaceFilter) }
    }

    fileprivate let raceFeedController: RaceFeedController
    fileprivate let raceApi = RaceApi()

    fileprivate let presenter = Appearance.defaultPresenter()
    fileprivate var formNavigationController: NavigationController?

    fileprivate let emptyStateJoinedRaces = EmptyStateViewModel(.noJoinedRaces)
    fileprivate let emptyStateChapterRaces = EmptyStateViewModel(.noJoinedRaces)
    fileprivate let emptyStateNearbyRaces = EmptyStateViewModel(.noNearbydRaces)
    fileprivate let emptyStateSeriesRaces = EmptyStateViewModel(.noSeriesRaces)

    fileprivate let isRaceSearchEnabled: Bool = true

    fileprivate enum Constants {
        static let padding: CGFloat = UniversalConstants.padding
    }

    // MARK: - Initialization

    init(_ filters: [RaceFilter], selectedFilter: RaceFilter) {
        self.raceFeedController = RaceFeedController(filters)

        super.init(nibName: nil, bundle: nil)

        let idx = filters.firstIndex(of: selectedFilter)
        self.segmentedControl.setItems(filters.compactMap { $0.title })
        self.segmentedControl.selectedSegmentIndex = idx ?? 0
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()

        setupLayout()
        registerJoinable()

        APIServices.shared.settings.add(self)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if feedCount == 0 {
            isLoadingList(true)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // reload whenever we transition back
        if feedCount == 0 || animated {
            loadContent(forced: true)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }

    deinit {
        unregisterJoinable()
    }

    // MARK: - Layout

    fileprivate func setupLayout() {

        configureNavigationItems()

        view.addSubview(headerView)
        headerView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide.snp.top)
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
        title = "Races"
        tabBarItem = UITabBarItem(title: title, image: SystemImg.flagCheckeredCrossed, selectedImage: nil)
    }

    // MARK: - Actions

    @objc fileprivate func didChangeSegment() {
        // Cancelling previous API requests to avoid overlaps
        raceApi.cancelSearchRequests()

        // This should be triggered just once, when first requesting access to the user's location
        // and display the shimmer while retrieving the location and loading the nearby races.
        let locationManager = LocationManager.shared
        if selectedRaceFilter == .nearby, !locationManager.didRequestAuthorization {
            isLoadingList(true)
            locationManager.requestsAuthorization { [weak self] (error) in
                self?.loadContent()
            }
        } else {
            loadContent(forced: true)
        }

        AppPrefs.lastSelectedRaceFilter = selectedRaceFilter
    }

    @objc fileprivate func didPressSearchButton(_ sender: Any) {
        let vc = UniversalSearchViewController()
        let nc = NavigationController(rootViewController: vc)
        present(nc, animated: true)
    }

    @objc fileprivate func didPressFilterButton(_ sender: Any) {
        let vc = RaceFeedMenuViewController()
        let nc = NavigationController(rootViewController: vc)

        customPresentViewController(presenter, viewController: nc, animated: true)
    }

    @objc fileprivate func didPressJoinButton(_ sender: JoinButton) {
        let list = raceFeedController.viewModels(for: selectedRaceFilter)
        guard let objectId = sender.objectId, let race = list?.race(withId: objectId) else { return }
        let state = sender.joinState

        toggleJoinButton(sender, forRace: race, raceApi: raceApi) { [weak self] (newState) in
            if state != newState {
                // reload races to reflect race changes, specially join counts
                self?.loadContent(forced: true)
            }
        }
    }

    @objc fileprivate func didPullRefreshControl() {
        loadContent(forced: true)
    }

    @objc fileprivate func didSwipeHorizontally(_ gesture: UIGestureRecognizer) {
        guard let gesture = gesture as? UISwipeGestureRecognizer else { return }

        var newIndex = segmentedControl.selectedSegmentIndex

        if gesture.direction == .left {
            newIndex += 1
        } else if gesture.direction == .right {
            newIndex -= 1
        }

        guard newIndex >= 0 && newIndex <= segmentedControl.numberOfSegments else { return }
        segmentedControl.setSelectedSegment(newIndex)
    }

    @objc func didLongPress(_ gesture: UIGestureRecognizer) {
        handleLongPress(gesture)
    }

    fileprivate func openRaceDetail(_ viewModel: RaceViewModel) {
        let vc = RaceTabBarController(with: viewModel.race)
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }

    fileprivate func selectSegment(_ filter: RaceFilter) {

        let idx = raceFeedController.raceFilters.firstIndex(of: filter) ?? 0
        segmentedControl.setSelectedSegment(idx)
    }

    // MARK: - Data Update

    // ViewJoinable
    func loadContent(forced: Bool = false) {
        let selectedList = selectedRaceFilter

        if raceFeedController.shouldShowShimmer(for: selectedList) {
            isLoadingList(true)
        }

        raceFeedController.viewModels(for: selectedList, forceFetch: forced) { [weak self] (viewModels, cached, error) in
            guard let strongSelf = self else { return }

            strongSelf.isLoadingList(false)

            if let _ = viewModels, selectedList == strongSelf.selectedRaceFilter {

                if strongSelf.refreshControl.isRefreshing, !cached {
                    strongSelf.refreshControl.endRefreshing()
                }

                strongSelf.tableView.reloadData()
            } else {
                print("getMyRaces error : \(error.debugDescription)")
            }
        }
    }
}

extension RaceFeedViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        if let viewModel = raceViewModel(for: indexPath.row) {
            openRaceDetail(viewModel)
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return RaceTableViewCell.height
    }
}

extension RaceFeedViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return feedCount
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(forIndexPath: indexPath) as RaceTableViewCell
        guard let viewModel = raceViewModel(for: indexPath.row) else { return cell }

        cell.titleLabel.text = viewModel.titleLabel
        cell.dateLabel.text = viewModel.dateLabel //"Saturday Sept 14 @ 9:00 AM"
        cell.joinButton.type = .race
        cell.joinButton.objectId = viewModel.race.id
        cell.joinButton.joinState = viewModel.joinState
        cell.joinButton.addTarget(self, action: #selector(didPressJoinButton), for: .touchUpInside)
        cell.memberBadgeView.count = viewModel.participantCount
        cell.avatarImageView.imageView.setImage(with: viewModel.imageUrl, placeholderImage: PlaceholderImg.medium)

        if selectedRaceFilter == .joined {
            cell.subtitleLabel.text = viewModel.locationLabel
        } else if selectedRaceFilter == .nearby {
            cell.subtitleLabel.text = viewModel.distanceLabel
        } else {
            cell.subtitleLabel.text = viewModel.chapterLabel
        }

        return cell
    }
}

extension RaceFeedViewController: APISettingsDelegate {

    func didUpdate(settings: APISettingsType, with value: Any) {

        switch settings {
        case .raceFeedFilters:
            updateSegmentedControl()
            raceFeedController.invalidateDataSource()
            loadContent(forced: true)
        case .searchRadius:
            raceFeedController.invalidateDataSource()
            loadContent(forced: true)
        case .measurement:
            loadContent() // simple refresh
        default:
            break
        }
    }

    func updateSegmentedControl() {
        let settings = APIServices.shared.settings
        self.segmentedControl.removeAllSegments()
        self.segmentedControl.setItems(settings.raceFeedFilters.compactMap { $0.title })
        self.segmentedControl.selectedSegmentIndex = 0
    }
}

extension RaceFeedViewController: ScrollToTop {

    func scrollToTop() {
        tableView.setContentOffset(.zero, animated: true)
    }
}

extension RaceFeedViewController: EmptyDataSetSource {

    func getEmptyStateViewModel() -> EmptyStateViewModel {
        switch selectedRaceFilter {
        case .joined:       return emptyStateJoinedRaces
        case .nearby:       return emptyStateNearbyRaces
        case .chapters:     return emptyStateChapterRaces
        case .series:       return emptyStateSeriesRaces
        default:            return EmptyStateViewModel(.noRaceResults)
        }
    }

    func title(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        return getEmptyStateViewModel().title
    }

    func description(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        return getEmptyStateViewModel().description
    }

    func image(forEmptyDataSet scrollView: UIScrollView) -> UIImage? {
        return nil
    }

    func buttonTitle(forEmptyDataSet scrollView: UIScrollView, for state: UIControl.State) -> NSAttributedString? {
        return getEmptyStateViewModel().buttonTitle(state)
    }

    func verticalOffset(forEmptyDataSet scrollView: UIScrollView) -> CGFloat {
        return -(navigationController?.navigationBar.frame.height ?? 0)
    }
}

extension RaceFeedViewController: EmptyDataSetDelegate {

    func emptyDataSetShouldAllowScroll(_ scrollView: UIScrollView) -> Bool {
        return true
    }

    func emptyDataSet(_ scrollView: UIScrollView, didTapButton button: UIButton) {

        if selectedRaceFilter == .joined {
            selectSegment(.nearby)
        } else if selectedRaceFilter == .chapters {
            //
        } else if selectedRaceFilter == .nearby {
            didPressFilterButton(button)
        }
    }
}
