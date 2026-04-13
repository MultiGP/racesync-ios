//
//  RaceListViewController.swift
//  RaceSync
//
//  Created by Ignacio Romero Zurbuchen on 2022-12-11.
//  Copyright © 2022 MultiGP Inc. All rights reserved.
//

import RaceSyncAPI
import EmptyDataSet_Swift
import SnapKit

/**
 Generic display of pre-loaded races.
 */
class RaceListViewController: UIViewController, ViewJoinable {

    // MARK: - Public Variables

    lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(cellType: RaceTableViewCell.self)
        tableView.emptyDataSetSource = self
        tableView.tableFooterView = UIView()
        return tableView
    }()

    // MARK: - Private Variables

    fileprivate var raceList: [RaceViewModel]
    fileprivate let raceApi = RaceApi()
    fileprivate let seriesApi = SeriesApi()

    fileprivate var seasonId: ObjectId?
    fileprivate var raceClass: RaceClass?
    fileprivate var raceName: String? // used for searching races with similar names
    fileprivate var series: Series?

    fileprivate let emptyStateNoRaces = EmptyStateViewModel(.noRaces)

    // MARK: - Initialization

    /**
     Displays a list of season races.

     - parameter raceViewModels: The pre-fetched view model list of races
     - parameter seasonId: The season id, to be used in case of refreshing the list (particularly needed for state updates like joining)
     */
    init(_ raceViewModels: [RaceViewModel], seasonId: ObjectId) {
        self.raceList = raceViewModels
        self.seasonId = seasonId
        super.init(nibName: nil, bundle: nil)
    }

    init(_ raceViewModels: [RaceViewModel], series: Series) {
        self.raceList = raceViewModels
        self.series = series
        super.init(nibName: nil, bundle: nil)
    }

    /**
     Displays a list of races filtered by class

     - parameter raceViewModels: The pre-fetched view model list of races
     - parameter raceClass: The season enum raw value, to be used in case of refreshing the list (particularly needed for state updates like joining)
     */
    init(_ raceViewModels: [RaceViewModel], raceClass: RaceClass) {
        self.raceList = raceViewModels
        self.raceClass = raceClass
        super.init(nibName: nil, bundle: nil)
        self.title = raceClass.title
    }

    init(_ raceViewModels: [RaceViewModel], raceName: String) {
        self.raceList = raceViewModels
        self.raceName = raceName
        super.init(nibName: nil, bundle: nil)
        self.title = raceName
    }

    init(_ raceViewModels: [RaceViewModel], title: String) {
        self.raceList = raceViewModels
        super.init(nibName: nil, bundle: nil)
        self.title = title
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()

        setupLayout()
        registerJoinable()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    deinit {
        unregisterJoinable()
    }

    // MARK: - Layout

    fileprivate func setupLayout() {

        configureNavigationItems()

        view.addSubview(tableView)
        tableView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(view.snp.bottom)
        }
    }

    fileprivate func configureNavigationItems() {
        if title == nil { title = "Races" }
        tabBarItem = UITabBarItem(title: title, image: SystemImg.flagCheckeredCrossed, selectedImage: nil)
    }

    // MARK: - Actions

    @objc fileprivate func didPressJoinButton(_ sender: JoinButton) {
        guard let objectId = sender.objectId, let race = raceList.race(withId: objectId) else { return }
        let state = sender.joinState

        toggleJoinButton(sender, forRace: race, raceApi: raceApi) { [weak self] (newState) in
            if state != newState {
                // reload races to reflect race changes, specially join counts
                self?.loadContent()
            }
        }
    }

    @objc fileprivate func didPressApproveButton(_ sender: ApproveButton) {
        guard let objectId = sender.objectId, let race = raceList.race(withId: objectId) else { return }
        guard let series = series else { return }

        toggleApprovalButton(sender, race: race, series: series)
    }

    @objc fileprivate func didPressRemoveButton(_ sender: ApproveButton) {
        guard let objectId = sender.objectId, let race = raceList.race(withId: objectId) else { return }
        guard let series = series else { return }

        handleRemoving(race: race, from: series, sender: sender)
    }

    fileprivate func openRaceDetail(_ viewModel: RaceViewModel) {
        let vc = RaceTabBarController(with: viewModel.race)
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }

    // MARK: - Data Update

    fileprivate func raceViewModel(for indexPath: IndexPath) -> RaceViewModel? {
        guard indexPath.row < raceList.count else { return nil }
        return raceList[indexPath.row]
    }

    // ViewJoinable
    func loadContent(forced: Bool = false) {
        if let seasonId = seasonId {
            raceApi.getRaces(seasonId: seasonId) { [weak self] (races, error) in
                if let races = races {
                    self?.raceList = RaceViewModel.sortedViewModels(with: races) // Keep the original order
                    self?.tableView.reloadData()
                } else if let _ = error {
                    // handle error ?
                }
            }
        } else if let raceClass = raceClass {
            raceApi.getRaces(with: [.upcoming], raceClass: raceClass) { [weak self] (races, error) in
                if let races = races {
                    self?.raceList = RaceViewModel.sortedViewModels(with: races, sorting: .descending)
                    self?.tableView.reloadData()
                } else if let _ = error {
                    // handle error ?
                }
            }
        } else if let raceName = raceName {
            raceApi.getRaces(name: raceName) { [weak self] (races, error) in
                if let races = races {
                    self?.raceList = RaceViewModel.sortedViewModels(with: races) // Keep the original order
                    self?.tableView.reloadData()
                } else if let _ = error {
                    // handle error ?
                }
            }
        } else if let series = series {
            seriesApi.view(series: series.id) { [weak self] newSeries, error in
                if let races = newSeries?.races {
                    self?.raceList = RaceViewModel.sortedViewModels(with: races, sorting: .ascending)
                    self?.tableView.reloadData()
                }
            }
        }
    }

    func toggleApprovalButton(_ button: ApproveButton, race: Race, series: Series) {

        button.isLoading = true
        let state = button.approveState

        switch state {
            case .notApproved:
                seriesApi.approve(series: series.id, raceId: race.id) { [weak self] (status, error) in
                    let newState = status ? .approved : state
                    self?.handleStateChange(state, newState: newState, in: button)
                }
            case .approved:
                let handler: AlertCompletionBlock = { [weak self] _ in
                    self?.seriesApi.unapprove(series: series.id, raceId: race.id) { [weak self] (status, error) in
                        let newState = status ? .notApproved : state
                        self?.handleStateChange(state, newState: newState, in: button)
                    }
                }

                ActionSheetUtil.presentDestructiveActionSheet(
                    withTitle: "Are you sure you want to unapprove this race?",
                    destructiveTitle: "Yes, Continue",
                    completion: handler,
                    cancel: { _ in
                        button.isLoading = false
                    })
            default:
                break
        }
    }

    fileprivate func handleRemoving(race: Race, from series: Series, sender: ApproveButton) {

        sender.isLoading = true

        let handler: AlertCompletionBlock = { _ in

            self.seriesApi.remove(race: race.id, from: series.id) { [weak self] status, error in
                if status == true {
                    // reload races to reflect changes, specially approval state
                    self?.loadContent()
                } else if let error = error {
                    AlertUtil.presentAlertMessage("\(error.localizedDescription)", title: "Error", delay: 0.5)
                } else {
                    AlertUtil.presentAlertMessage("Couldn't remove this race. Please try again later.", title: "Error", delay: 0.5)
                }
                sender.isLoading = false
            }
        }

        ActionSheetUtil.presentDestructiveActionSheet(
            withTitle: "Remove this race from the series?",
            destructiveTitle: "Yes, Remove",
            completion: handler,
            cancel: { _ in
                sender.isLoading = false
            }
        )
    }

    fileprivate func handleStateChange(_ oldState: ApproveState, newState: ApproveState, in button: ApproveButton, _ completion: ApproveStateCompletionBlock? = nil) {

        if oldState != newState {
            loadContent()
            RateMe.shared.userDidPerformEvent()
        } else {
            button.isLoading = false
        }

        completion?(newState)
    }
}

extension RaceListViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        if let viewModel = raceViewModel(for: indexPath) {
            openRaceDetail(viewModel)
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return RaceTableViewCell.height
    }
}

extension RaceListViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return raceList.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return raceTableViewCell(for: indexPath)
    }

    func raceTableViewCell(for indexPath: IndexPath) -> RaceTableViewCell {
        guard let viewModel = raceViewModel(for: indexPath) else { return RaceTableViewCell() }
        let cell = tableView.dequeueReusableCell(forIndexPath: indexPath) as RaceTableViewCell

        cell.dateLabel.text = viewModel.startDateLabel //"Saturday Sept 14 @ 9:00 AM"
        cell.titleLabel.text = viewModel.titleLabel
        cell.subtitleLabel.text = viewModel.locationLabel
        cell.avatarImageView.imageView.setImage(with: viewModel.imageUrl, placeholderImage: PlaceholderImg.medium)

        // reset
        resetRaceTableViewCell(cell: cell)

        // Special feature for the Series' owner
        if let series = series, series.canBeEdited {
            let state = viewModel.approveState
            cell.approveButton.type = .race
            cell.approveButton.approveState = state

            if !viewModel.race.isFinalized {
                cell.approveButton.objectId = viewModel.race.id
                cell.approveButton.addTarget(self, action: #selector(didPressApproveButton), for: .touchUpInside)

                if state == .notApproved {
                    cell.removeButton.isHidden = false
                    cell.removeButton.objectId = viewModel.race.id
                    cell.removeButton.addTarget(self, action: #selector(didPressRemoveButton), for: .touchUpInside)
                }
            } else {
                cell.approveButton.approveState = .completed
            }
        } else {
            cell.joinButton.joinState = viewModel.joinState
            cell.joinButton.type = .race
            cell.joinButton.objectId = viewModel.race.id
            cell.joinButton.addTarget(self, action: #selector(didPressJoinButton), for: .touchUpInside)

            cell.memberBadgeView.count = viewModel.participantCount
            cell.memberBadgeView.isHidden = false
        }
        return cell
    }

    func resetRaceTableViewCell(cell: RaceTableViewCell) {
        cell.joinButton.isHidden = true
        cell.memberBadgeView.isHidden = true
        cell.approveButton.isHidden = true
        cell.removeButton.isHidden = true
        cell.accessoryType = .none

        cell.joinButton.objectId = nil
        cell.approveButton.objectId = nil
        cell.removeButton.objectId = nil
        cell.memberBadgeView.count = 0
    }
}

extension RaceListViewController: EmptyDataSetSource {

    func title(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        return emptyStateNoRaces.title
    }

    func description(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        return emptyStateNoRaces.description
    }

    func backgroundColor(forEmptyDataSet scrollView: UIScrollView) -> UIColor? {
        return Color.white
    }
}
