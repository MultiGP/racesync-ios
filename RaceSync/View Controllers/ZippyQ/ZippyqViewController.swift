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
        return raceController.race!
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
    
    fileprivate let zippyqController: ZippyqController
    fileprivate var expandedQueueKeys = Set<String>()
    fileprivate var hasInitializedExpandedQueues = false

    fileprivate var roundViewModels: [ZippyqRoundViewModel] {
        return zippyqController.roundViewModels
    }
    
    fileprivate enum Constants {
        static let cellHeight: CGFloat = 60
    }
    
    // MARK: - Initialization
    
    init(with controller: RaceController) {
        self.raceController = controller
        self.zippyqController = ZippyqController(raceController: controller)
        super.init(nibName: nil, bundle: nil)

        zippyqController.delegate = self
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupLayout()
        configureNavigationItems()
        zippyqController.loadContent()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        zippyqController.loadContent()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        zippyqController.startPolling()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        zippyqController.stopPolling()
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

    fileprivate func updateContent() {
        initializeExpandedQueuesIfNeeded()
        tableView.reloadData()
    }
    
    // RaceTabbable
    func reloadContent() {
        zippyqController.loadContent(force: true)
    }
    
    // MARK: - Actions

    @objc fileprivate func didTapAddMe(_ sender: FrequencyActionButton) {
        guard let viewModel = frequencyViewModel(for: sender) else {
            sender.isLoading = false
            return
        }

        zippyqController.addPilot(slot: viewModel.slot, cycle: viewModel.cycle,
                                 heat: viewModel.heat) { [weak self, weak sender] error in
            self?.completeAction(sender, error: error)
        }
    }

    @objc fileprivate func didTapSwitch(_ sender: FrequencyActionButton) {
        guard let viewModel = frequencyViewModel(for: sender) else {
            sender.isLoading = false
            return
        }

        zippyqController.addPilot(slot: viewModel.slot, cycle: viewModel.cycle,
                                 heat: viewModel.heat) { [weak self, weak sender] error in
            self?.completeAction(sender, error: error)
        }
    }

    @objc fileprivate func didTapRemove(_ sender: FrequencyActionButton) {
        guard let viewModel = frequencyViewModel(for: sender) else {
            sender.isLoading = false
            return
        }

        zippyqController.removePilot(slot: viewModel.slot, cycle: viewModel.cycle,
                                    heat: viewModel.heat) { [weak self, weak sender] error in
            self?.completeAction(sender, error: error)
        }
    }

    fileprivate func completeAction(_ actionButton: FrequencyActionButton?, error: NSError?) {
        actionButton?.isLoading = false

        if let error {
            let title = actionButton?.action?.failureTitle ?? "Error"
            AlertUtil.presentAlertMessage(error.localizedDescription, title: title, delay: 0.25)
        }
    }

    fileprivate func showUserProfile(_ user: User) {
        let viewController = UserViewController(with: user)
        navigationController?.pushViewController(viewController, animated: true)
    }
}

// MARK: - ZippyqControllerDelegate

extension ZippyqViewController: ZippyqControllerDelegate {

    func zippyqControllerDidUpdateContent(_ controller: ZippyqController) {
        updateContent()
    }
}

// MARK: - Queue State

private extension ZippyqViewController {

    func initializeExpandedQueuesIfNeeded() {
        guard !hasInitializedExpandedQueues else { return }

        for round in roundViewModels where round.badge == .live /*|| round.badge == .upNext */ {
            expandedQueueKeys.insert(round.id)
        }
        hasInitializedExpandedQueues = true
    }

    func isQueueExpanded(at section: Int) -> Bool {
        return expandedQueueKeys.contains(roundViewModels[section].id)
    }

    func toggleQueue(at section: Int) {

        let key = roundViewModels[section].id
        var scrollToSection: Bool = false

        if expandedQueueKeys.contains(key) {
            expandedQueueKeys.remove(key)
        } else {
            expandedQueueKeys.insert(key)
            scrollToSection = true
        }

        tableView.reloadSections(IndexSet(integer: section), with: .automatic)
        if scrollToSection { tableView.scrollToRow(at: IndexPath(row: 0, section: section), at: .top, animated: true) }
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
        header.subtitle = viewModel.heatLabel
        header.subtitleContext = viewModel.scoringFormatLabel
        header.contextualText = viewModel.contextualLabel
        header.isExpanded = isQueueExpanded(at: section)
        header.avatarImageUrls = viewModel.avatarImageUrls
        header.textPill.text = viewModel.badge.title
        header.textPill.titleLabel.textColor = viewModel.badge.titleColor
        header.textPill.backgroundColor = viewModel.badge.backgroundColor
        header.didTapView = { [weak self] in
            self?.toggleQueue(at: section)
        }
        return header
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let viewModel = roundViewModels[section]
        let displaysMetadata = isQueueExpanded(at: section)
            && (viewModel.heatLabel != nil || viewModel.scoringFormatLabel != nil)
        return displaysMetadata ? CollapsableHeaderView.headerHeightWithSubtitle : CollapsableHeaderView.headerHeight
    }
}
