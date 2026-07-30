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
        tableView.register(cellType: ZippyqFrequencyTableViewCell.self)
        tableView.register(CollapsableHeaderView.self, forHeaderFooterViewReuseIdentifier: CollapsableHeaderView.identifier)
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate = self
        tableView.tableFooterView = UIView()
        return tableView
    }()
    
    fileprivate let zippyqAPI = ZippyqApi()
    fileprivate var roundViewModels = [ZippyqRoundViewModel]()
    fileprivate var revisionHash: ZippyqRevisionHash?
    fileprivate var expandedQueueKeys = Set<String>()
    fileprivate var hasInitializedExpandedQueues = false
    
    fileprivate let refreshInterval: TimeInterval = 10.0
    fileprivate var refreshTimer: Timer?
    fileprivate let isPollEnabled: Bool = true
    
    fileprivate enum Constants {
        static let cellHeight: CGFloat = 60
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
                let nextQueuedIndex = queues.firstIndex(where: { $0.status == .queued })
                self?.roundViewModels = queues.enumerated().map { index, queue in
                    ZippyqRoundViewModel(
                        with: queue,
                        frequencies: frequencies,
                        pilotStats: stats,
                        maximumPackCount: self?.race.maxZippyqDepth ?? 0,
                        isUpNext: index == nextQueuedIndex
                    )
                }
                self?.initializeExpandedQueuesIfNeeded()
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

// MARK: - Queue State

private extension ZippyqViewController {

    func initializeExpandedQueuesIfNeeded() {
        guard !hasInitializedExpandedQueues else { return }

        if let nextRound = roundViewModels.first(where: { $0.badge == .upNext }) {
            expandedQueueKeys.insert(nextRound.id)
        }
        hasInitializedExpandedQueues = true
    }

    func isQueueExpanded(at section: Int) -> Bool {
        return expandedQueueKeys.contains(roundViewModels[section].id)
    }

    func toggleQueue(at section: Int) {

        let key = roundViewModels[section].id
        var scroll: Bool = false

        if expandedQueueKeys.contains(key) {
            expandedQueueKeys.remove(key)
        } else {
            expandedQueueKeys.insert(key)
            scroll = true
        }

        tableView.reloadSections(IndexSet(integer: section), with: .automatic)
        if scroll { tableView.scrollToRow(at: IndexPath(row: 0, section: section), at: .top, animated: true) }
    }
}

// MARK: - UITableView DataSource

extension ZippyqViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return roundViewModels.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return isQueueExpanded(at: section) ? roundViewModels[section].frequencyViewModels.count : 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return frequencyTableViewCell(for: indexPath)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return Constants.cellHeight
    }

    fileprivate func frequencyTableViewCell(for indexPath: IndexPath) -> ZippyqFrequencyTableViewCell {
        let cell = tableView.dequeueReusableCell(forIndexPath: indexPath) as ZippyqFrequencyTableViewCell
        let viewModel = roundViewModels[indexPath.section].frequencyViewModels[indexPath.row]
        cell.configure(with: viewModel, showsTopSeparator: indexPath.row > 0)
        configureActionButton(for: cell)
        return cell
    }

    fileprivate func configureActionButton(for cell: ZippyqFrequencyTableViewCell) {
        cell.actionButton.removeTarget(nil, action: nil, for: .touchUpInside)

        switch cell.actionButton.action {
        case .addMe:
            cell.actionButton.addTarget(self, action: #selector(didTapAddMe(_:)), for: .touchUpInside)
        case .switch:
            cell.actionButton.addTarget(self, action: #selector(didTapSwitch(_:)), for: .touchUpInside)
        case .remove:
            cell.actionButton.addTarget(self, action: #selector(didTapRemove(_:)), for: .touchUpInside)
        case nil:
            break
        }
    }

    fileprivate func frequencyViewModel(for actionButton: FrequencyActionButton) -> ZippyqFrequencyViewModel? {
        let location = actionButton.convert(CGPoint(x: actionButton.bounds.midX, y: actionButton.bounds.midY), to: tableView)
        guard let indexPath = tableView.indexPathForRow(at: location) else { return nil }
        return roundViewModels[indexPath.section].frequencyViewModels[indexPath.row]
    }

    @objc fileprivate func didTapAddMe(_ sender: FrequencyActionButton) {
        guard let viewModel = frequencyViewModel(for: sender) else { return }
        Clog.log("Add me to \(viewModel.channelLabel)")
    }

    @objc fileprivate func didTapSwitch(_ sender: FrequencyActionButton) {
        guard let viewModel = frequencyViewModel(for: sender) else { return }
        Clog.log("Switch to \(viewModel.channelLabel)")
    }

    @objc fileprivate func didTapRemove(_ sender: FrequencyActionButton) {
        guard let viewModel = frequencyViewModel(for: sender) else { return }
        Clog.log("Remove me from \(viewModel.channelLabel)")
    }

    fileprivate func showUserProfile(_ user: User) {
        let viewController = UserViewController(with: user)
        navigationController?.pushViewController(viewController, animated: true)
    }
}

// MARK: - UITableView Delegate

extension ZippyqViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let viewModel = roundViewModels[indexPath.section].frequencyViewModels[indexPath.row]
        guard let user = viewModel.user else { return }

        showUserProfile(user)
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let viewModel = roundViewModels[section]
        guard let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: CollapsableHeaderView.identifier) as? CollapsableHeaderView else { return nil }

        header.title = viewModel.titleLabel
        header.contextualText = viewModel.contextualLabel
        header.isExpanded = isQueueExpanded(at: section)
        header.textPill.text = viewModel.badge.title
        header.textPill.titleLabel.textColor = viewModel.badge == .live ? Color.light : Color.blue
        header.textPill.backgroundColor = viewModel.badge == .live ? Color.green : Color.yellow
        header.didTapView = { [weak self] in
            self?.toggleQueue(at: section)
        }
        return header
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CollapsableHeaderView.headerHeight
    }
}
