//
//  ZippyqViewController.swift
//  RaceSync
//
//  Created by Ignacio Romero on 2026-07-27.
//  Copyright © 2026 MultiGP Inc. All rights reserved.
//

import UIKit
import SnapKit
import RaceSyncAPI

class ZippyqViewController: UIViewController, RaceTabbable {
    
    // MARK: - Public Variables
    
    var raceController: RaceController
    
    var race: Race {
        get { return raceController.race! }
    }
    
    // MARK: - Private Variables
    
    fileprivate lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.register(cellType: AvatarTableViewCell.self)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.tableFooterView = UIView()
        return tableView
    }()
    
    fileprivate let zippyqAPI = ZippyqApi()
    fileprivate var queues = [ZippyQueue]()
    fileprivate var stats = ZippyqPilotCollection()
    fileprivate var frequencies = [Frequency]()
    fileprivate var revisionHash: ZippyqRevisionHash?
    
    fileprivate let refreshInterval: TimeInterval = 10.0
    fileprivate var refreshTimer: Timer?
    fileprivate let isPollEnabled: Bool = true
    
    fileprivate enum Constants {
        static let padding: CGFloat = UniversalConstants.padding
        static let cellHeight: CGFloat = 60
        static let avatarSize: CGFloat = 38
    }
    
    // MARK: - Initialization
    
    init(with controller: RaceController) {
        self.raceController = controller
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        refreshTimer?.invalidate()
    }
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupLayout()
        configureNavigationItems()
        loadContent()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if revisionHash == nil {
            loadContent()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        startPolling()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        stopPolling()
    }
    
    // MARK: - Layout
    
    fileprivate func setupLayout() {
        
        view.addSubview(tableView)
        tableView.snp.makeConstraints {
            $0.top.leading.trailing.bottom.equalToSuperview()
        }
    }
    
    fileprivate func configureNavigationItems() {
        title = "ZippyQ"
        tabBarItem = UITabBarItem(title: title, image: SystemImg.bulletList, selectedImage: SystemImg.bulletListFill)
        
        navigationItem.rightBarButtonItems = raceController.navigationItems()
    }
    
    // MARK: - Data Update
    
    fileprivate func loadRevision() {
        
        zippyqAPI.getRevision(for: race.id, revision: revisionHash) { [weak self] hash, error in
            if error != nil {
                // Handle error
            } else {
                self?.loadContent(with: hash?.value)
            }
        }
    }
    
    fileprivate func loadContent(with hash: ZippyqRevisionHash? = nil) {
        
        if let hash = hash, hash == revisionHash {
            Clog.log("NO need to fetch ZippyQ content")
            return // no need to reload
        }
        
        revisionHash = hash // saving for later use
        
        zippyqAPI.getQueues(for: race.id) { [weak self] response, error in
            if let queues = response?.queues, let stats = response?.pilotStats, let frequencies = response?.frequencies {
                self?.queues = queues
                self?.stats = stats
                self?.frequencies = frequencies
                self?.tableView.reloadData()
            } else if error != nil {
                // Handle error
            }
        }
    }
    
    fileprivate func startPolling() {
        guard isPollEnabled, refreshTimer == nil else { return }

        refreshTimer = Timer.scheduledTimer(withTimeInterval: refreshInterval, repeats: true) { [weak self] _ in
            self?.loadRevision()
        }
    }

    fileprivate func stopPolling() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }

    // RaceTabbable
    func reloadContent() {
        loadContent()
    }
}

// MARK: - UITableView DataSource

extension ZippyqViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return queues.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return frequencies.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return avatarTableViewCell(for: indexPath)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return Constants.cellHeight
    }

    func avatarTableViewCell(for indexPath: IndexPath) -> AvatarTableViewCell {
        let cell = tableView.dequeueReusableCell(forIndexPath: indexPath) as AvatarTableViewCell
        configure(cell, forRowAt: indexPath)
        return cell
    }
    
    func configure<T>(_ view: T, forRowAt indexPath: IndexPath) where T : UITableViewCell {
        guard let cell = view as? AvatarTableViewCell else { return }
        
        let queue = queues[indexPath.section]
        let frequency = frequencies[indexPath.row]
        let entry = queue.entries.first { $0.frequency?.frequency == frequency.frequency }
        
        cell.titleLabel.textColor = Color.black
        cell.subtitleLabel.textColor = Color.gray300
        cell.rankView.titleLabel.textColor = Color.blue
        cell.rankView.titleLabel.text = frequency.channelLabel
        cell.rankView.isHidden = false
        //cell.avatarSize = Constants.avatarSize
        cell.backgroundView?.backgroundColor = Color.white
        cell.selectedBackgroundView?.backgroundColor = Color.gray50
        cell.accessoryType = .none
        cell.textPill.text = entry?.fastest3Laps
        cell.textPill.style = .text
        
        if let entry, let user = entry.user, let stat = stats[user.id] {
            let viewModel = UserViewModel(with: user)
            
            cell.avatarImageView.imageView.setImage(with: viewModel.pictureUrl, placeholderImage: PlaceholderImg.medium)
            cell.titleLabel.text = viewModel.username
            cell.subtitleLabel.text = "Pack \(stat.usedCount) of \(race.maxZippyqDepth)"
            
        } else {
            cell.avatarImageView.imageView.setImage(with: nil, placeholderImage: PlaceholderImg.medium)
            cell.titleLabel.text = nil
            cell.subtitleLabel.text = "Unassigned"
        }
    }
}

// MARK: - UITableView Delegate

extension ZippyqViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let queue = queues[section]
        var text = "Round \(queue.cycle)"
        
        if queue.status == .running {
            text += " (Live)".uppercased()
        }
        else if queue.status == .queued && section == 1 {
            text += " (Up Next)".uppercased()
        }
        
        if queue.status == .running {
            text += " \(queue.entries.count) Racing"
        }
        else if queue.status == .queued {
            text += " \(queue.entries.count) Waiting"
        }
        
        return text
    }
}
