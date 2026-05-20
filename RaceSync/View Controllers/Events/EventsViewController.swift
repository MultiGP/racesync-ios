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

class EventsViewController: UIViewController, Shimmable {

    // MARK: - Public Variables

    lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.backgroundView = UIView()
        tableView.backgroundView?.backgroundColor = Color.clear
        tableView.backgroundColor = Color.gray50
        tableView.contentInsetAdjustmentBehavior = .always
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(cellType: EventSessionTableViewCell.self)
        tableView.tableFooterView = UIView()
        tableView.refreshControl = self.refreshControl
        return tableView
    }()

    var shimmeringView: ShimmeringView = defaultShimmeringView()

    // MARK: - Private Variables

    fileprivate lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.backgroundColor = Color.gray50
        refreshControl.tintColor = Color.blue
        refreshControl.addTarget(self, action: #selector(didPullRefreshControl), for: .valueChanged)
        return refreshControl
    }()
    
    fileprivate lazy var headerScrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.alwaysBounceHorizontal = true
        scrollView.isUserInteractionEnabled = false
        scrollView.alpha = 0.7
        return scrollView
    }()
    
    fileprivate lazy var headerView: UIView = {
        let view = UIView()
        view.backgroundColor = Color.navigationBarColor
        view.tintColor = Color.blue
        
        view.addSubview(headerScrollView)
        headerScrollView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 12
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.layoutMargins = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
        
        headerScrollView.addSubview(stackView)
        stackView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.height.equalToSuperview()
            // Min width fits 5 buttons, expands if more
            $0.width.greaterThanOrEqualTo(view.snp.width)
        }

        for date in eventsController.ios26Dates {
            let button = UIButton(type: .system)
            button.titleLabel?.numberOfLines = 2
            button.titleLabel?.textAlignment = .center
            button.setAttributedTitle(attributedTitle(for: date), for: .normal)
            button.addTarget(self, action: #selector(didTapDateButton(_:)), for: .touchUpInside)
            button.contentEdgeInsets = UIEdgeInsets(top: 6, left: 8, bottom: 6, right: 8)
            button.backgroundColor = Color.gray20
            button.tag = eventsController.ios26Dates.firstIndex(of: date)!

            if #available(iOS 26, *) {
                var config = UIButton.Configuration.glass()
                button.configuration = config
            } else {
                button.layer.cornerRadius = 8
                button.layer.cornerCurve = .continuous
                button.layer.borderWidth = 1
                button.layer.borderColor = Color.gray50.cgColor
            }

            stackView.addArrangedSubview(button)
            
            if date == selectedDate {
                selectedButton = button
            }
        }

        view.addSeparatorLine(.bottom)
        
        return view
    }()

    fileprivate func attributedTitle(for date: Date) -> NSAttributedString {
        let f = DateFormatter()
        f.timeZone = MGPEventTimeZone

        f.dateFormat = "EEE"
        let dayName = f.string(from: date) // "Wed"

        f.dateFormat = "MMM d"
        let dayDate = f.string(from: date) // "Jun 10"

        let result = NSMutableAttributedString()
        result.append(NSAttributedString(string: dayName + "\n", attributes: [
            .font: UIFont.systemFont(ofSize: 12, weight: .semibold)
        ]))
        result.append(NSAttributedString(string: dayDate, attributes: [
            .font: UIFont.systemFont(ofSize: 11, weight: .regular)
        ]))
        return result
    }
    
    private func select(_ button: UIButton?) {
        guard let button else { return }
        
        if #available(iOS 26, *) {
            button.isSelected = true
        } else {
            button.setTitleColor(Color.white, for: .normal)
            button.backgroundColor = Color.blue
            button.layer.borderColor = Color.blue.cgColor
        }
        
        selectedButton = button
        
        if let date = selectedDate {
            selectedSessions = eventsController.io26MergedSessions(for: date, with: .scheduled)
        }
    }

    private func deselectButton() {
        guard let button = selectedButton else { return }
        
        if #available(iOS 26, *) {
            button.isSelected = false
        } else {
            button.setTitleColor(Color.blue, for: .normal)
            button.backgroundColor = Color.gray20
            button.layer.borderColor = Color.gray50.cgColor
        }
        
        selectedButton = nil
    }
    
    fileprivate let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        f.timeZone = MGPEventTimeZone
        return f
    }()
    
    fileprivate let eventsController = EventsController()
    fileprivate var selectedSessions: [MGPEventSession]?
    fileprivate var favedSessions = Set<MGPEventSession>()

    fileprivate var selectedDate: Date?
    fileprivate var selectedButton: UIButton?

    fileprivate enum Constants {
        static let padding: CGFloat = UniversalConstants.padding
        static let headerViewHeight: CGFloat = 60
    }

    // MARK: - Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()

        selectedDate = eventsController.ios26Dates.first
        
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

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }

    // MARK: - Layout

    fileprivate func setupLayout() {
        
        configureNavigationItems()
        
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
            $0.bottom.equalTo(view.snp.bottom)
        }
    }

    fileprivate func configureNavigationItems() {
        title = "IO26"
        tabBarItem = UITabBarItem(title: title, image: SystemImg.globe, selectedImage: SystemImg.globeFill)
        tabBarItem.isEnabled = true
    }

    // MARK: - Data Update

    fileprivate func loadContent() {

        if !refreshControl.isRefreshing {
            isLoadingList(true)
        }
        
        eventsController.fetchIO26Event { event, error in
            
            let enabled = event != nil
            self.headerScrollView.isUserInteractionEnabled = enabled
            self.headerScrollView.alpha = enabled ? 1 : 0.7
            
            if enabled {
                self.select(self.selectedButton)
            }
            
            if self.refreshControl.isRefreshing {
                self.refreshControl.endRefreshing()
                self.tableView.reloadData()
            } else {
                self.isLoadingList(false)
            }
        }
    }
        
    fileprivate func resetTableView() {
        tableView.setContentOffset(.zero, animated: false)
        tableView.reloadData()
    }
    
    // MARK: - Actions

    @objc fileprivate func didPullRefreshControl() {
        loadContent()
    }
    
    @objc private func didTapDateButton(_ button: UIButton) {
        let newDate = eventsController.ios26Dates[button.tag] as Date
        
        if newDate == selectedDate {
            return
        }
        
        deselectButton()
        selectedDate = newDate
        select(button)

        tableView.reloadData()
    }
}

extension EventsViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        guard let _ = eventsController.io26Event else {
            return 0
        }
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let sessions = selectedSessions, sessions.count > 0 else {
            return 0
        }
        return sessions.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(forIndexPath: indexPath) as EventSessionTableViewCell
        configure(cell, forRowAt: indexPath)
        return cell
    }

    func configure<T>(_ view: T, forRowAt indexPath: IndexPath) where T : UITableViewCell {
        guard let sessions = selectedSessions, sessions.count > 0 else { return }
        guard let cell = view as? EventSessionTableViewCell else { return }
        
        let session = sessions[indexPath.row]
        let track = eventsController.track(for: session)
        
        cell.titleLabel.text = "\(session.activity)"
        cell.titleLabel.textColor = Color.black

        cell.subtitleLabel.text = track?.name
        cell.subtitleLabel.textColor = eventsController.color(for: track)
        cell.iconView.tintColor = cell.subtitleLabel.textColor

        if let startTime = session.startTime {
            cell.startTimeLabel.text = timeFormatter.string(from: startTime)
        }
        
        if let endTime = session.endTime {
            cell.endTimeLabel.text = timeFormatter.string(from: endTime)
        }

        cell.backgroundColor = (indexPath.row % 2 == 0) ? Color.white : Color.gray20
        
        let starImage = favedSessions.contains(session) ? SystemImg.starFill : SystemImg.star
        let starColor = favedSessions.contains(session) ? Color.yellow : Color.gray100
        cell.accessoryView = UIImageView(image: starImage)
        cell.accessoryView?.tintColor = starColor
    }
}

extension EventsViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let sessions = selectedSessions, sessions.count > 0 else { return }

//        guard let cell = tableView.cellForRow(at: indexPath) as? EventSessionTableViewCell else { return }
//        tableView.deselectRow(at: indexPath, animated: true)

        let session = sessions[indexPath.row]

        if favedSessions.contains(session) {
            favedSessions.remove(session)
        } else {
            favedSessions.insert(session)
        }
        
        tableView.reloadRows(at: [indexPath], with: .none)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return EventSessionTableViewCell.cellHeight
    }
}
