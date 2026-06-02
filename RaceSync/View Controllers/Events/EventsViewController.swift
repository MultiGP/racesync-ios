//
//  EventsViewController.swift
//  RaceSync
//
//  Created by Ignacio Romero on 2026-04-26.
//  Copyright © 2026 MultiGP Inc. All rights reserved.
//

import UIKit
import SnapKit
import RaceSyncAPI
import ShimmerSwift
import EmptyDataSet_Swift

class EventsViewController: UIViewController, Shimmable {

    // MARK: - Public Variables

    lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.emptyDataSetSource = self
        tableView.emptyDataSetDelegate = self
        tableView.tableFooterView = UIView()
        tableView.backgroundView = UIView()
        tableView.backgroundView?.backgroundColor = Color.clear
        tableView.backgroundColor = Color.gray50
        tableView.contentInsetAdjustmentBehavior = .always
        tableView.register(cellType: EventSessionTableViewCell.self)
        tableView.refreshControl = refreshControl
        return tableView
    }()

    var shimmeringView: ShimmeringView = defaultShimmeringView()

    // MARK: - Private Variables

    fileprivate lazy var refreshControl: UIRefreshControl = {
        let rc = UIRefreshControl()
        rc.backgroundColor = Color.gray50
        rc.tintColor = Color.blue
        rc.addTarget(self, action: #selector(didPullRefreshControl), for: .valueChanged)
        return rc
    }()

    fileprivate lazy var headerView: EventHeaderView = {
        let view = EventHeaderView(
            dates: eventsController.ios26Dates,
            timezone: MGPEventTimeZone!,
            filters: EventSessionFilter.allCases.map { ($0.title, $0.image) }
        )
        view.delegate = self
        view.selectFilter(titled: eventsController.selectedFilter.title)
        view.isEnabled = false
        return view
    }()

    fileprivate let eventsController = EventsController()
    fileprivate var selectedSessions = [EventSession]()

    fileprivate lazy var timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        f.locale = Locale(identifier: USLocale)
        f.timeZone = MGPEventTimeZone
        return f
    }()
    
    fileprivate let emptyStateNoEvents = EmptyStateViewModel(.noEvents)
    fileprivate var emptyStateError: EmptyStateViewModel?

    fileprivate enum Constants {
        static let padding: CGFloat = UniversalConstants.padding
        static let headerViewHeight: CGFloat = 120
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupLayout()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        hideNavigationShadow()

        if !eventsController.didFetchEvents() {
            isLoadingList(true)
        } else {
            tableView.reloadData()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if !eventsController.didFetchEvents() {
            loadContent()
        }
    }

    // MARK: - Layout

    fileprivate func setupLayout() {
        configureNavigationItems()

        view.addSubview(headerView)
        headerView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(Constants.headerViewHeight)
        }

        view.addSubview(tableView)
        tableView.snp.makeConstraints {
            $0.top.equalTo(headerView.snp.bottom)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalToSuperview()
        }

        view.addSubview(shimmeringView)
        shimmeringView.snp.makeConstraints {
            $0.top.equalTo(tableView.snp.top)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalToSuperview()
        }
    }

    fileprivate func configureNavigationItems() {
        title = "IO26"
        tabBarItem = UITabBarItem(title: title, image: SystemImg.globe, selectedImage: SystemImg.globeFill)
        tabBarItem.isEnabled = true
    }

    // MARK: - Data

    fileprivate func loadContent(forced: Bool = false) {
        if !refreshControl.isRefreshing {
            isLoadingList(true)
        }
        
        eventsController.fetchIO26Event(forced) { [weak self] event, error in
            guard let self else { return }
            
            if let error {
                handleError(error)
            } else {
                selectedSessions = eventsController.reloadSessions()
                headerView.isEnabled = (event != nil)
            }
            
            if refreshControl.isRefreshing {
                refreshControl.endRefreshing()
                tableView.reloadData()
            } else {
                isLoadingList(false)
            }
        }
    }

    // MARK: - Actions

    @objc fileprivate func didTapStarButton(_ sender: UIButton) {
        guard sender.tag < selectedSessions.count, let date = eventsController.selectedDate else { return }
        let bucketlist = eventsController.bucketlist
        let session = selectedSessions[sender.tag]
        
        if bucketlist.contains(session, for: date) {
            bucketlist.delete(session, for: date)
            NotificationScheduler.shared.cancel(for: session)
        } else {
            bucketlist.save(session, for: date)
            NotificationScheduler.shared.schedule(for: session)
        }
        
        // Trigger haptic feedback to emphasize the action
        HapticEngine.shared.trigger()
        
        let delay = eventsController.selectedFilter == .mySchedule ? 0.3 : 0

        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + delay) { [weak self] in
            guard let sessions = self?.eventsController.reloadSessions() else { return }
            self?.selectedSessions = sessions
            
            let indexPath = IndexPath(row: sender.tag, section: 0)
            
            self?.tableView.beginUpdates()
            if self?.eventsController.selectedFilter == .mySchedule {
                self?.tableView.deleteRows(at: [indexPath], with: .automatic) // must delete the row in this unique case
            } else {
                self?.tableView.reloadRows(at: [indexPath], with: .automatic)
            }
            self?.tableView.endUpdates()
            
            // Needed for updating the button's tags. There must be another way
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1) {
                self?.tableView.reloadData()
            }
        }
    }
    
    fileprivate func openRaceDetail(_ raceId: ObjectId) {
        let vc = RaceTabBarController(with: raceId, selectedTab: .details)
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc fileprivate func didPullRefreshControl() {
        loadContent(forced: true)
    }
    
    // MARK: - Error Handling

    fileprivate func handleError(_ error: NSError) {
        emptyStateError = EmptyStateViewModel(.error(error))
        tableView.reloadEmptyDataSet()
    }
}

extension EventsViewController: EventHeaderViewDelegate {

    func headerView(_ headerView: EventHeaderView, didSelectDate date: Date) {
        eventsController.selectedDate = date
        selectedSessions = eventsController.reloadSessions()
        
        tableView.setContentOffset(.zero, animated: false)
        tableView.reloadData()
    }

    func headerView(_ headerView: EventHeaderView, didSelectFilter title: String) {
        eventsController.selectedFilter = EventSessionFilter(title: title) ?? .all
        selectedSessions = eventsController.reloadSessions()
        
        tableView.setContentOffset(.zero, animated: false)
        tableView.reloadData()
        
        AppplicationPreferences.lastSelectedEventFilter = eventsController.selectedFilter
    }
}

extension EventsViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        eventsController.io26Event != nil ? 1 : 0
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        selectedSessions.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(forIndexPath: indexPath) as EventSessionTableViewCell
        configure(cell, forRowAt: indexPath)
        return cell
    }

    func configure<T: UITableViewCell>(_ view: T, forRowAt indexPath: IndexPath) {
        guard let cell = view as? EventSessionTableViewCell,
              indexPath.row < selectedSessions.count else { return }

        let session = selectedSessions[indexPath.row]
        let track = eventsController.track(for: session)

        cell.backgroundColor = Color.white
        cell.titleLabel.text = session.activity
        cell.titleLabel.textColor = Color.black
        cell.subtitleLabel.text = track?.name
        cell.subtitleLabel.textColor = eventsController.color(for: track)
        cell.sideView.backgroundColor = eventsController.color(for: track)
        cell.iconView.tintColor = cell.subtitleLabel.textColor
        cell.startTimeLabel.text = session.startTime.map { timeFormatter.string(from: $0) }
        cell.endTimeLabel.text = session.endTime.map   { timeFormatter.string(from: $0) }
        
        cell.starButton.addTarget(self, action: #selector(didTapStarButton(_:)), for: .touchUpInside)
        cell.isFavorite = eventsController.bucketlist.contains(session, for: eventsController.selectedDate)
        cell.starButton.tag = indexPath.row
    }
}

extension EventsViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let session = selectedSessions[indexPath.row]
        if let raceId = session.raceId {
            openRaceDetail(raceId)
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        EventSessionTableViewCell.cellHeight
    }
}

extension EventsViewController: EmptyDataSetSource {

    func title(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        
        if emptyStateError != nil {
            return emptyStateError?.title
        } else {
            return emptyStateNoEvents.title
        }
    }

    func description(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        
        if let error = emptyStateError { return error.description }
        let filter = eventsController.selectedFilter

        if filter == .mySchedule { return emptyStateNoEvents.description }

        let suffix = filter == .all ? "" : " for \(filter.title)"
        return EmptyStateViewModel.attributtedStringForDescription(
            "There are no events scheduled this day\(suffix)."
        )
    }

    func image(forEmptyDataSet scrollView: UIScrollView) -> UIImage? {
        return nil
    }

    func verticalOffset(forEmptyDataSet scrollView: UIScrollView) -> CGFloat {
        return -Constants.headerViewHeight
    }

    func backgroundColor(forEmptyDataSet scrollView: UIScrollView) -> UIColor? {
        return Color.white
    }
}

extension EventsViewController: EmptyDataSetDelegate {

    func emptyDataSetShouldAllowScroll(_ scrollView: UIScrollView) -> Bool {
        return false
    }
}
