//
//  ZippyqViewController.swift
//  RaceSync
//
//  Created by Ignacio Romero on 2026-07-27.
//  Copyright © 2026 MultiGP Inc. All rights reserved.
//

import UIKit
import SnapKit
import EmptyDataSet_Swift
import RaceSyncAPI

class ZippyqViewController: UIViewController, RaceTabbable {

    // MARK: - Public Variables
    
    /// UI-only override for App Store screenshots. Queue eligibility and API actions remain unchanged.
#if DEBUG
    static var forceDisplaySmartJoinHeader = false
#else
    static var forceDisplaySmartJoinHeader = false
#endif

    var race: Race {
        return raceController.race!
    }

    var raceController: RaceController

    // MARK: - Private Variables

    typealias SectionIdentifier = ZippyqSnapshotController.SectionIdentifier
    typealias ItemIdentifier = ZippyqSnapshotController.ItemIdentifier
    typealias DataSource = UICollectionViewDiffableDataSource<SectionIdentifier, ItemIdentifier>

    lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: makeCollectionViewLayout())
        collectionView.backgroundColor = Color.tableGroupedBackground
        collectionView.alwaysBounceVertical = true
        collectionView.contentInsetAdjustmentBehavior = .automatic
        collectionView.delegate = self
        collectionView.emptyDataSetDelegate = self
        collectionView.emptyDataSetSource = self
        
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
        
        if #available(iOS 26, *) {
            collectionView.topEdgeEffect.isHidden = true
        }
        return collectionView
    }()

    lazy var dataSource: DataSource = makeDataSource()

    weak var headerView: ZippyqHeaderView?
    let dataController: ZippyqDataController
    let snapshotController = ZippyqSnapshotController()
    var headerLayoutMetrics: ZippyqHeaderView.LayoutMetrics?
    var headerCollapseProgress: CGFloat = 0
    var headerCollapseTracking: HeaderCollapseTracking = .contentOffset
    var lastHeaderScrollOffset: CGFloat = 0
    var lastUserScrollTime: CFTimeInterval = 0
    var shouldDisplaySmartJoinHeader: Bool {
        return (dataController.canDisplaySmartJoinHeader && dataController.canJoinQueues) || Self.forceDisplaySmartJoinHeader
    }
    fileprivate var emptyStateError: EmptyStateViewModel?
    fileprivate let emptyStateNoRaceQueues = EmptyStateViewModel(.noRaceQueues)
    fileprivate var isJoiningNextRound = false
    fileprivate var isLoadingPastRounds = false

    fileprivate lazy var pastRoundsRefreshControl: UIRefreshControl = {
        let control = UIRefreshControl()
        control.backgroundColor = .clear
        control.tintColor = Color.refreshControl
        control.attributedTitle = NSAttributedString(
            string: "Load Past Rounds",
            attributes: [.foregroundColor: Color.refreshControl]
        )
        control.addTarget(self, action: #selector(loadMorePastRounds), for: .valueChanged)
        return control
    }()

    fileprivate lazy var activityIndicatorView: ActivityLoadingView = {
        let view = ActivityLoadingView(style: .medium)
        view.hidesWhenStopped = true
        return view
    }()

    enum HeaderCollapseTracking {
        case contentOffset
        case relativeOffset
        case suspended
    }

    enum Constants {
        static let fastUpwardScrollVelocity: CGFloat = -0.8
        static let runningRoundTransitionIdleInterval: CFTimeInterval = 5
        static let expandedRoundBottomMargin: CGFloat = UniversalConstants.padding
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
        setTitleActivityIndicatorVisible(false)
    }

    // MARK: - Layout

    fileprivate func setupLayout() {

        view.backgroundColor = collectionView.backgroundColor
        
        configureNavigationItems()
        _ = dataSource

        view.addSubview(collectionView)
        collectionView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        view.addSubview(activityIndicatorView)
        activityIndicatorView.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
    }

    fileprivate func configureNavigationItems() {
        switch dataController.roundsMode {
        case .zippyQ:
            title = "ZippyQ"
            tabBarItem = UITabBarItem(
                title: title,
                image: SystemImg.bulletList,
                selectedImage: SystemImg.bulletListFill
            )
        case .schedule:
            title = "Schedule"
            tabBarItem = UITabBarItem(title: title, image: SystemImg.flagCheckered, tag: 0)
        }
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

    func makeCollectionViewLayout() -> UICollectionViewLayout {
        let displaysHeader = shouldDisplaySmartJoinHeader
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
        if dataController.hasLoadedContent {
            displayContent()
        } else {
            setInitialLoading(true)
        }
        dataController.loadContent()
    }

    fileprivate func setInitialLoading(_ loading: Bool) {
        activityIndicatorView.title = dataController.roundsMode == .zippyQ
            ? "Loading ZippyQ..."
            : "Loading Schedule..."
        activityIndicatorView.isLoading = loading
        collectionView.isHidden = loading
    }

    fileprivate func displayContent(animatingRunningRoundChange: Bool = false,
                                    animatingPastRoundInsertion: Bool = false) {
        let previousRunningRoundId = snapshotController.runningRoundId
        let previouslyExpandedRoundIds = snapshotController.expandedRoundIds
        snapshotController.update(
            with: dataController.roundViewModels,
            expandsInitialRounds: dataController.shouldExpandInitialRounds,
            expandsRoundsContainingCurrentUser: dataController.allowsQueueActions,
            initialExpandedRoundIds: dataController.initialExpandedRoundIds
        )
        configurePastRoundsRefreshControl()
        configureHeaderView()

        let runningRoundId = snapshotController.runningRoundId
        let isRunningRoundChange = previousRunningRoundId != nil
            && runningRoundId != nil
            && previousRunningRoundId != runningRoundId
        if animatingPastRoundInsertion {
            applySnapshot(animatingDifferences: true)
            return
        }
        guard animatingRunningRoundChange, isRunningRoundChange, let runningRoundId else {
            applySnapshot(animatingDifferences: false, reloadingExistingItems: true)
            return
        }

        snapshotController.collapseRounds(withIds: snapshotController.pastRoundIds)
        snapshotController.expandRound(withId: runningRoundId)

        let expansionChangedRoundIds = previouslyExpandedRoundIds
            .symmetricDifference(snapshotController.expandedRoundIds)
        let updatedRoundIds = snapshotController.pastRoundIds
            .union([runningRoundId])
        animateVisibleRoundHeaders(
            withIds: updatedRoundIds,
            expansionChangedRoundIds: expansionChangedRoundIds
        )
        applySnapshot(animatingDifferences: true, reloadingExistingItems: true) { [weak self] in
            self?.scrollRoundToTop(withId: runningRoundId)
        }
    }

    fileprivate func configureHeaderView() {
        let displaysHeader = dataController.hasLoadedContent && shouldDisplaySmartJoinHeader
        let layoutDisplaysHeader = shouldDisplaySmartJoinHeader
        if let layout = collectionView.collectionViewLayout as? ZippyqCollectionViewLayout,
           layout.displaysHeader != layoutDisplaysHeader {
            collectionView.setCollectionViewLayout(makeCollectionViewLayout(), animated: false)
        }
        headerView?.isHidden = !displaysHeader
        if let headerView, displaysHeader {
            configure(headerView)
        }
    }

    func applySnapshot(animatingDifferences: Bool,
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
        if !dataController.hasLoadedContent {
            emptyStateError = nil
            collectionView.reloadEmptyDataSet()
            setInitialLoading(true)
        }
        dataController.loadContent(force: true)
    }

    // MARK: - Actions

    @objc fileprivate func loadMorePastRounds() {
        guard dataController.canLoadMorePastQueues else {
            pastRoundsRefreshControl.endRefreshing()
            configurePastRoundsRefreshControl()
            return
        }

        isLoadingPastRounds = true
        dataController.loadMorePastQueues()
    }

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

    func showUserProfile(_ user: User) {
        let viewController = UserViewController(with: user)
        navigationController?.pushViewController(viewController, animated: true)
    }
}

// MARK: - ZippyqDataControllerDelegate

extension ZippyqViewController: ZippyqDataControllerDelegate {

    func zippyqDataControllerDidStartNetworkActivity(_ controller: ZippyqDataController) {
        DispatchQueue.main.async { [weak self] in
            self?.setTitleActivityIndicatorVisible(true)
        }
    }

    func zippyqDataControllerDidEndNetworkActivity(_ controller: ZippyqDataController) {
        DispatchQueue.main.async { [weak self] in
            self?.setTitleActivityIndicatorVisible(false)
        }
    }

    func zippyqDataControllerDidUpdateContent(_ controller: ZippyqDataController) {
        let isInitialLoad = activityIndicatorView.isLoading
        emptyStateError = nil
        let hasBeenIdle = CACurrentMediaTime() - lastUserScrollTime
            >= Constants.runningRoundTransitionIdleInterval
        let canAnimateRunningRoundChange = !isInitialLoad
            && viewIfLoaded?.window != nil
            && !collectionView.isDragging
            && !collectionView.isDecelerating
            && hasBeenIdle
        let animatingPastRoundInsertion = isLoadingPastRounds
        isLoadingPastRounds = false
        displayContent(
            animatingRunningRoundChange: canAnimateRunningRoundChange,
            animatingPastRoundInsertion: animatingPastRoundInsertion
        )

        if pastRoundsRefreshControl.isRefreshing {
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                pastRoundsRefreshControl.endRefreshing()
                configurePastRoundsRefreshControl()
            }
        }

        if isInitialLoad {
            collectionView.layoutIfNeeded()
            if let metrics = headerView?.layoutMetrics {
                applyHeaderLayoutMetrics(metrics)
                collectionView.layoutIfNeeded()
            }
            collectionView.setContentOffset(
                CGPoint(x: 0, y: -collectionView.adjustedContentInset.top),
                animated: false
            )
        }

        setInitialLoading(false)
        collectionView.reloadEmptyDataSet()

        if isInitialLoad {
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                collectionView.layoutIfNeeded()
                if let roundId = dataController.initialScheduleScrollRoundId {
                    scrollRoundToTop(withId: roundId, animated: false)
                } else if dataController.shouldLimitPastQueues,
                   let runningRoundId = snapshotController.runningRoundId {
                    scrollRoundToTop(withId: runningRoundId, animated: false)
                }
                configurePastRoundsRefreshControl()
            }
        }
    }

    func zippyqDataController(_ controller: ZippyqDataController,
                              didFailToLoadContent error: NSError) {
        guard !controller.hasLoadedContent else { return }

        emptyStateError = EmptyStateViewModel(.error(error))
        setInitialLoading(false)
        collectionView.reloadEmptyDataSet()
    }
}

private extension ZippyqViewController {

    func configurePastRoundsRefreshControl() {
        guard !collectionView.isHidden else {
            collectionView.refreshControl = nil
            return
        }

        if dataController.canLoadMorePastQueues {
            if collectionView.refreshControl !== pastRoundsRefreshControl {
                collectionView.refreshControl = pastRoundsRefreshControl
            }
        } else if !pastRoundsRefreshControl.isRefreshing {
            collectionView.refreshControl = nil
        }
    }

    func setTitleActivityIndicatorVisible(_ visible: Bool) {
        (tabBarController as? RaceTabBarController)?
            .setTitleActivityIndicatorVisible(visible, for: self)
    }
}

// MARK: - EmptyDataSetSource

extension ZippyqViewController: EmptyDataSetSource {

    func title(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        return emptyStateError?.title ?? emptyStateNoRaceQueues.title
    }

    func description(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        return emptyStateError?.description ?? emptyStateNoRaceQueues.description
    }

    func buttonTitle(forEmptyDataSet scrollView: UIScrollView, for state: UIControl.State) -> NSAttributedString? {
        if emptyStateError != nil || dataController.roundsMode == .schedule {
            return nil
        }
        return emptyStateNoRaceQueues.buttonTitle(state)
    }

    func verticalOffset(forEmptyDataSet scrollView: UIScrollView) -> CGFloat {
        return -scrollView.adjustedContentInset.top
    }

    func backgroundColor(forEmptyDataSet scrollView: UIScrollView) -> UIColor? {
        return collectionView.backgroundColor
    }
}

// MARK: - EmptyDataSetDelegate

extension ZippyqViewController: EmptyDataSetDelegate {

    func emptyDataSetShouldDisplay(_ scrollView: UIScrollView) -> Bool {
        if emptyStateError != nil { return true }

        return dataController.hasLoadedContent
            && dataController.roundViewModels.isEmpty
    }

    func emptyDataSetShouldAllowScroll(_ scrollView: UIScrollView) -> Bool {
        return dataController.hasLoadedContent
    }

    func emptyDataSet(_ scrollView: UIScrollView, didTapButton button: UIButton) {
        guard dataController.roundsMode == .zippyQ else { return }
        raceController.showZippyqWeb()
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
            let previousItemIsCurrentUser = snapshotController.frequencyViewModel(
                inRoundWithId: identifier.roundId,
                at: indexPath.item - 1
            )?.isCurrentUser == true
            cell.configure(
                with: viewModel,
                showsTopSeparator: indexPath.item > 0
                    && !viewModel.isCurrentUser
                    && !previousItemIsCurrentUser,
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

        let displaysHeader = dataController.hasLoadedContent && shouldDisplaySmartJoinHeader
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

    func configure(_ header: ZippyqCollapsableHeaderView?,
                   with viewModel: ZippyqRoundViewModel,
                   animatingExpansion: Bool = false) {
        guard let header else { return }
        header.configure(
            with: viewModel,
            isExpanded: snapshotController.isRoundExpanded(withId: viewModel.id),
            animatingExpansion: animatingExpansion
        )
        header.didTapView = { [weak self] in
            if viewModel.isExpandable {
                self?.toggleRound(withId: viewModel.id)
            } else {
                self?.scrollRoundToTop(withId: viewModel.id)
            }
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

    func animateVisibleRoundHeaders(withIds roundIds: Set<String>,
                                    expansionChangedRoundIds: Set<String>) {
        let sections = dataSource.snapshot().sectionIdentifiers
        let layout = collectionView.collectionViewLayout as? ZippyqCollectionViewLayout
        for indexPath in collectionView.indexPathsForVisibleSupplementaryElements(
            ofKind: ZippyqCollectionViewLayout.roundHeaderElementKind
        ) where sections.indices.contains(indexPath.section) {
            guard let viewModel = snapshotController.roundViewModel(for: sections[indexPath.section]),
                  roundIds.contains(viewModel.id) else { continue }

            let header = collectionView.supplementaryView(
                forElementKind: ZippyqCollectionViewLayout.roundHeaderElementKind,
                at: indexPath
            ) as? ZippyqCollapsableHeaderView
            configure(header, with: viewModel, animatingExpansion: true)

            if expansionChangedRoundIds.contains(viewModel.id) {
                layout?.prepareAccordionTransition(forSection: indexPath.section)
            }
        }
    }
}
