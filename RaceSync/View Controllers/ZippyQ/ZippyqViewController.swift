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

    fileprivate typealias SectionIdentifier = ZippyqSnapshotController.SectionIdentifier
    fileprivate typealias ItemIdentifier = ZippyqSnapshotController.ItemIdentifier
    fileprivate typealias DataSource = UICollectionViewDiffableDataSource<SectionIdentifier, ItemIdentifier>

    fileprivate lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: makeCollectionViewLayout())
        collectionView.register(cellType: ZippyqFrequencyCollectionViewCell.self)
        collectionView.register(
            ZippyqCollapsableHeaderView.self,
            forSupplementaryViewOfKind: ZippyqCollectionViewLayout.roundHeaderElementKind,
            withReuseIdentifier: ZippyqCollapsableHeaderView.identifier
        )
        collectionView.register(
            ZippyqHeaderView.self,
            forSupplementaryViewOfKind: ZippyqCollectionViewLayout.headerElementKind,
            withReuseIdentifier: ZippyqHeaderView.identifier
        )
        collectionView.backgroundColor = .systemGroupedBackground
        collectionView.alwaysBounceVertical = true
        collectionView.contentInsetAdjustmentBehavior = .automatic
        if #available(iOS 26, *) {
            collectionView.topEdgeEffect.isHidden = true
        }
        collectionView.delegate = self
        return collectionView
    }()

    fileprivate lazy var dataSource: DataSource = makeDataSource()
    fileprivate weak var headerView: ZippyqHeaderView?
    fileprivate let dataController: ZippyqDataController
    fileprivate let snapshotController = ZippyqSnapshotController()
    fileprivate var headerLayoutMetrics: ZippyqHeaderView.LayoutMetrics?
    fileprivate var headerCollapseProgress: CGFloat = 0
    fileprivate var usesRelativeHeaderCollapseProgress = false
    fileprivate var lastHeaderScrollOffset: CGFloat = 0
    fileprivate var isJoiningNextRound = false

    fileprivate enum Constants {
        static let fastUpwardScrollVelocity: CGFloat = -0.8
    }

    // MARK: - Initialization

    init(with controller: RaceController) {
        self.raceController = controller
        self.dataController = ZippyqDataController(raceController: controller)
        super.init(nibName: nil, bundle: nil)

        dataController.delegate = self
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()

        setupLayout()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        refreshView()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        dataController.startPolling()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        dataController.stopPolling()
    }

    // MARK: - Layout

    fileprivate func setupLayout() {
        
        configureNavigationItems()
        _ = dataSource

        view.addSubview(collectionView)
        collectionView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide)
            $0.leading.trailing.bottom.equalToSuperview()
        }
    }

    fileprivate func configureNavigationItems() {

        title = "ZippyQ"
        tabBarItem = UITabBarItem(title: title, image: SystemImg.bulletList, selectedImage: SystemImg.bulletListFill)
        navigationItem.rightBarButtonItems = raceController.navigationItems()
    }

    fileprivate func configureHeaderInteractions(_ headerView: ZippyqHeaderView) {

        headerView.didSelectFrequency = { [weak self] frequency in
            self?.dataController.toggleSelectedFrequency(frequency)
            self?.configureHeaderView()
        }
        headerView.didTapJoinNextRound = { [weak self] in
            self?.joinNextRound()
        }
    }

    fileprivate func makeCollectionViewLayout() -> UICollectionViewLayout {
        let displaysHeader = dataController.canJoinQueues
        let expandedHeaderHeight = headerLayoutMetrics?.expandedHeight ?? ZippyqHeaderView.initialLayoutHeight
        let compactHeaderHeight = headerLayoutMetrics?.compactHeight ?? expandedHeaderHeight
        return ZippyqCollectionViewLayout(
            displaysHeader: displaysHeader,
            expandedHeaderHeight: expandedHeaderHeight,
            compactHeaderHeight: compactHeaderHeight,
            headerCollapseProgress: headerCollapseProgress
        ) { [weak self] sectionIndex in
            guard let self else { return nil }
            let sections = dataSource.snapshot().sectionIdentifiers
            guard sections.indices.contains(sectionIndex),
                  let viewModel = snapshotController.roundViewModel(for: sections[sectionIndex]) else {
                return nil
            }
            return ZippyqCollectionViewLayout.RoundSectionConfiguration(
                viewModel: viewModel,
                isExpanded: snapshotController.isRoundExpanded(withId: viewModel.id)
            )
        }
    }

    // MARK: - Data Update

    fileprivate func refreshView() {
        displayContent()
        dataController.loadContent()
    }

    fileprivate func displayContent() {
        snapshotController.update(with: dataController.roundViewModels)
        configureHeaderView()
        applySnapshot(animatingDifferences: false, reloadingExistingItems: true)
    }

    fileprivate func configureHeaderView() {
        let displaysHeader = dataController.canJoinQueues
        if let layout = collectionView.collectionViewLayout as? ZippyqCollectionViewLayout,
           layout.displaysHeader != displaysHeader {
            collectionView.setCollectionViewLayout(makeCollectionViewLayout(), animated: false)
        }
        headerView?.isHidden = !displaysHeader
        if let headerView, displaysHeader {
            configure(headerView)
        }
    }

    fileprivate func applySnapshot(animatingDifferences: Bool,
                                   reloadingExistingItems: Bool = false,
                                   completion: (() -> Void)? = nil) {
        var snapshot = snapshotController.makeSnapshot()
        if reloadingExistingItems {
            let currentItems = Set(dataSource.snapshot().itemIdentifiers)
            snapshot.reloadItems(snapshot.itemIdentifiers.filter(currentItems.contains))
        }

        collectionView.collectionViewLayout.invalidateLayout()
        dataSource.apply(snapshot, animatingDifferences: animatingDifferences) { [weak self] in
            self?.configureVisibleRoundHeaders()
            completion?()
        }
    }

    // RaceTabbable
    func reloadContent() {
        dataController.loadContent(force: true)
    }

    // MARK: - Actions

    fileprivate func joinNextRound() {
        guard !isJoiningNextRound else { return }

        isJoiningNextRound = true
        configureHeaderView()
        dataController.joinNextRound { [weak self] recommendation, error in
            guard let self else { return }

            isJoiningNextRound = false
            configureHeaderView()
            if let error {
                AlertUtil.presentAlertMessage(error.localizedDescription, title: "Unable to Join", delay: 0.25)
            } else if let recommendation {
                presentJoinConfirmation(for: recommendation)
            }
        }
    }

    fileprivate func presentJoinConfirmation(for recommendation: ZippyqSmartJoinRecommendation) {
        let viewModel = dataController.joinConfirmationViewModel(for: recommendation)

        AlertUtil.presentAlertMessage(
            viewModel.message,
            title: viewModel.title,
            okTitle: "View Round",
            cancelTitle: "OK",
            delay: 0.25
        ) { [weak self] _ in
            self?.expandAndScrollToRound(cycle: recommendation.cycle, heat: recommendation.heat)
        }
    }

    fileprivate func performQueueAction(_ actionButton: FrequencyActionButton,
                                        viewModel: ZippyqFrequencyViewModel) {
        let completion: (NSError?) -> Void = { [weak self, weak actionButton] error in
            self?.completeAction(actionButton, error: error)
        }
        switch viewModel.action {
        case .addMe, .switch:
            dataController.addPilot(
                slot: viewModel.slot,
                cycle: viewModel.cycle,
                heat: viewModel.heat,
                completion: completion
            )
        case .remove:
            dataController.removePilot(
                slot: viewModel.slot,
                cycle: viewModel.cycle,
                heat: viewModel.heat,
                completion: completion
            )
        case nil:
            actionButton.isLoading = false
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

// MARK: - ZippyqDataControllerDelegate

extension ZippyqViewController: ZippyqDataControllerDelegate {

    func zippyqDataControllerDidUpdateContent(_ controller: ZippyqDataController) {
        displayContent()
    }
}

// MARK: - Collection Data Source

private extension ZippyqViewController {

    func makeDataSource() -> DataSource {
        let dataSource = DataSource(collectionView: collectionView) { [weak self] collectionView, indexPath, identifier in
            guard let self,
                  let viewModel = snapshotController.frequencyViewModel(for: identifier) else {
                return nil
            }

            let cell: ZippyqFrequencyCollectionViewCell = collectionView.dequeueReusableCell(forIndexPath: indexPath)
            let allowsQueueActions = dataController.canJoinQueues
            cell.configure(
                with: viewModel,
                showsTopSeparator: indexPath.item > 0,
                allowsQueueActions: allowsQueueActions
            )
            if allowsQueueActions {
                cell.didTapAction = { [weak self] actionButton in
                    self?.performQueueAction(actionButton, viewModel: viewModel)
                }
            } else {
                cell.didTapAction = nil
            }
            return cell
        }

        dataSource.supplementaryViewProvider = { [weak self] collectionView, kind, indexPath in
            guard let self else { return nil }

            if kind == ZippyqCollectionViewLayout.headerElementKind {
                let header = collectionView.dequeueReusableSupplementaryView(
                    ofKind: kind,
                    withReuseIdentifier: ZippyqHeaderView.identifier,
                    for: indexPath
                ) as? ZippyqHeaderView
                self.headerView = header
                if let header {
                    configure(header)
                }
                return header
            }

            guard kind == ZippyqCollectionViewLayout.roundHeaderElementKind else { return nil }
            let sections = dataSource.snapshot().sectionIdentifiers
            guard sections.indices.contains(indexPath.section),
                  let viewModel = snapshotController.roundViewModel(for: sections[indexPath.section]) else {
                return nil
            }

            let header = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: ZippyqCollapsableHeaderView.identifier,
                for: indexPath
            ) as? ZippyqCollapsableHeaderView
            configure(header, with: viewModel)
            return header
        }
        return dataSource
    }

    func configure(_ header: ZippyqHeaderView) {
        let displaysHeader = dataController.canJoinQueues
        header.isHidden = !displaysHeader
        header.collapseProgress = headerCollapseProgress
        header.didResolveLayoutMetrics = { [weak self] metrics in
            self?.applyHeaderLayoutMetrics(metrics)
        }
        header.isLoading = isJoiningNextRound
        configureHeaderInteractions(header)
        if displaysHeader {
            header.configure(with: dataController.headerViewModel)
        }
    }

    func configure(_ header: ZippyqCollapsableHeaderView?, with viewModel: ZippyqRoundViewModel) {
        guard let header else { return }
        header.configure(
            with: viewModel,
            isExpanded: snapshotController.isRoundExpanded(withId: viewModel.id)
        )
        header.didTapView = { [weak self] in
            self?.toggleRound(withId: viewModel.id)
        }
    }

    func configureVisibleRoundHeaders() {
        let indexPaths = collectionView.indexPathsForVisibleSupplementaryElements(
            ofKind: ZippyqCollectionViewLayout.roundHeaderElementKind
        )
        let sections = dataSource.snapshot().sectionIdentifiers
        for indexPath in indexPaths where sections.indices.contains(indexPath.section) {
            let header = collectionView.supplementaryView(
                forElementKind: ZippyqCollectionViewLayout.roundHeaderElementKind,
                at: indexPath
            ) as? ZippyqCollapsableHeaderView
            if let viewModel = snapshotController.roundViewModel(for: sections[indexPath.section]) {
                configure(header, with: viewModel)
            }
        }
    }

}

// MARK: - Round State

private extension ZippyqViewController {

    func toggleRound(withId roundId: String) {
        let isExpanding = !snapshotController.isRoundExpanded(withId: roundId)
        setVisibleRoundHeader(withId: roundId, expanded: isExpanding)
        snapshotController.toggleRound(withId: roundId)
        applySnapshot(animatingDifferences: true) { [weak self] in
            self?.scrollRoundToTop(withId: roundId)
        }
    }

    func expandAndScrollToRound(cycle: Int32, heat: Int32) {
        let roundId = "\(cycle):\(heat)"
        snapshotController.expandRound(withId: roundId)
        applySnapshot(animatingDifferences: true) { [weak self] in
            self?.scrollRoundToTop(withId: roundId)
        }
    }

    func setVisibleRoundHeader(withId roundId: String, expanded: Bool) {
        let sectionIdentifier = SectionIdentifier.round(roundId)
        guard let section = dataSource.snapshot().indexOfSection(sectionIdentifier) else { return }
        let header = collectionView.supplementaryView(
            forElementKind: ZippyqCollectionViewLayout.roundHeaderElementKind,
            at: IndexPath(item: 0, section: section)
        ) as? ZippyqCollapsableHeaderView
        header?.setExpanded(expanded, animated: true)
    }

    func scrollRoundToTop(withId roundId: String) {
        let sectionIdentifier = SectionIdentifier.round(roundId)
        guard let section = dataSource.snapshot().indexOfSection(sectionIdentifier) else { return }

        collectionView.layoutIfNeeded()
        let headerIndexPath = IndexPath(item: 0, section: section)
        guard let headerAttributes = collectionView.layoutAttributesForSupplementaryElement(
            ofKind: ZippyqCollectionViewLayout.roundHeaderElementKind,
            at: headerIndexPath
        ), let layout = collectionView.collectionViewLayout as? ZippyqCollectionViewLayout,
           let targetOffset = layout.targetContentOffset(forRoundHeaderAt: headerAttributes.frame.minY) else {
            return
        }
        collectionView.setContentOffset(targetOffset, animated: true)
    }
}

// MARK: - UICollectionViewDelegate

extension ZippyqViewController: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        guard let identifier = dataSource.itemIdentifier(for: indexPath),
              let user = snapshotController.frequencyViewModel(for: identifier)?.user else {
            return
        }
        showUserProfile(user)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard dataController.canJoinQueues, headerCollapseRange > 0 else { return }

        let offset = scrollView.contentOffset.y + scrollView.adjustedContentInset.top
        if offset <= 0 {
            usesRelativeHeaderCollapseProgress = false
            setHeaderCollapseProgress(0)
        } else if usesRelativeHeaderCollapseProgress {
            let delta = offset - lastHeaderScrollOffset
            setHeaderCollapseProgress(headerCollapseProgress + delta / headerCollapseRange)
            if headerCollapseProgress >= 1, delta > 0 {
                usesRelativeHeaderCollapseProgress = false
            }
        } else {
            setHeaderCollapseProgress(offset / headerCollapseRange)
        }
        lastHeaderScrollOffset = offset
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        lastHeaderScrollOffset = scrollView.contentOffset.y + scrollView.adjustedContentInset.top
    }

    func scrollViewWillEndDragging(_ scrollView: UIScrollView,
                                   withVelocity velocity: CGPoint,
                                   targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        guard headerCollapseRange > 0 else { return }

        let currentOffset = scrollView.contentOffset.y + scrollView.adjustedContentInset.top
        let projectedOffset = targetContentOffset.pointee.y + scrollView.adjustedContentInset.top

        if velocity.y < Constants.fastUpwardScrollVelocity, headerCollapseProgress > 0 {
            usesRelativeHeaderCollapseProgress = true
            lastHeaderScrollOffset = currentOffset
            let requiredDistance = headerCollapseProgress * headerCollapseRange
            let projectedDistance = max(0, currentOffset - projectedOffset)
            if projectedDistance < requiredDistance {
                targetContentOffset.pointee.y -= requiredDistance - projectedDistance
            }
            return
        }

        if usesRelativeHeaderCollapseProgress {
            let projectedProgress = headerCollapseProgress
                + (projectedOffset - currentOffset) / headerCollapseRange
            let targetProgress: CGFloat = projectedProgress >= 0.5 ? 1 : 0
            targetContentOffset.pointee.y += (targetProgress - projectedProgress) * headerCollapseRange
            return
        }

        guard projectedOffset > 0, projectedOffset < headerCollapseRange else { return }

        let targetProgress: CGFloat = projectedOffset >= headerCollapseRange / 2 ? 1 : 0
        targetContentOffset.pointee.y = targetProgress * headerCollapseRange
            - scrollView.adjustedContentInset.top
    }
}

private extension ZippyqViewController {

    var headerCollapseRange: CGFloat {
        return headerLayoutMetrics?.collapseRange ?? 0
    }

    var expandedHeaderHeight: CGFloat {
        return headerLayoutMetrics?.expandedHeight ?? ZippyqHeaderView.initialLayoutHeight
    }

    func setHeaderCollapseProgress(_ progress: CGFloat) {
        guard dataController.canJoinQueues else { return }

        let progress = min(max(progress, 0), 1)
        guard progress != headerCollapseProgress else { return }
        headerCollapseProgress = progress
        headerView?.collapseProgress = headerCollapseProgress
        (collectionView.collectionViewLayout as? ZippyqCollectionViewLayout)?
            .headerCollapseProgress = headerCollapseProgress
    }

    func applyHeaderLayoutMetrics(_ metrics: ZippyqHeaderView.LayoutMetrics) {
        guard headerLayoutMetrics != metrics else { return }
        headerLayoutMetrics = metrics
        collectionView.setCollectionViewLayout(makeCollectionViewLayout(), animated: false)
    }
}
