//
//  RacePilotsViewController.swift
//  RaceSync
//
//  Created by Ignacio Romero Zurbuchen on 2019-11-15.
//  Copyright © 2019 MultiGP Inc. All rights reserved.
//

import UIKit
import EmptyDataSet_Swift
import RaceSyncAPI

class RacePilotsViewController: UIViewController, ViewJoinable, RaceTabbable, Pinnable {

    // MARK: - Public Variables

    var raceController: RaceController

    var race: Race {
        get { return raceController.race! }
    }

    var raceApi: RaceApi {
        get { return raceController.raceApi }
    }

    // MARK: - Private Variables

    lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.emptyDataSetDelegate = self
        tableView.emptyDataSetSource = self
        tableView.register(cellType: FormTableViewCell.self)
        tableView.register(cellType: AvatarTableViewCell.self)
        tableView.refreshControl = self.refreshControl
        tableView.tableFooterView = UIView()
        tableView.backgroundColor = Color.gray50
        
        let longPress = UILongPressGestureRecognizer(target: self,action: #selector(didLongPress(_:)))
        longPress.minimumPressDuration = 0.3
        longPress.delaysTouchesBegan = true
        tableView.addGestureRecognizer(longPress)
        
        return tableView
    }()

    fileprivate lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.backgroundColor = Color.gray50
        refreshControl.tintColor = Color.blue
        refreshControl.addTarget(self, action: #selector(didPullRefreshControl), for: .valueChanged)
        return refreshControl
    }()

    fileprivate var userApi = UserApi()
    fileprivate var userViewModels = [UserViewModel]()

    fileprivate let emptyStateNoPilots = EmptyStateViewModel(.noRacePilots)
    fileprivate var didTapCell: Bool = false
    fileprivate var externalResultSection: Int = 0

    // Pinnable variables
    var pinnedView: UIView?
    var cachedPinnedIndexPath: IndexPath?
    fileprivate var didShowPinnedView = false

    fileprivate var myUserId: ObjectId? {
        get { return APIServices.shared.myUser?.id }
    }

    func showingExternalResults() -> Bool {
        return race.canShowResults && race.liveTimeEventUrl != nil
    }

    fileprivate enum Constants {
        static let padding: CGFloat = UniversalConstants.padding
        static let cellHeight: CGFloat = UniversalConstants.cellHeight
        static let buttonSpacing: CGFloat = 12
    }

    // MARK: - Initialization

    init(with controller: RaceController) {
        self.raceController = controller
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()

        setupLayout()
        configureNavigationItems()
        loadContent()
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

        view.backgroundColor = Color.white

        registerPinnedView(viewType: AvatarTableViewCell.self)

        view.addSubview(tableView)
        tableView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.width.equalTo(UIScreen.main.bounds.width)
        }
    }

    fileprivate func configureNavigationItems() {

        if race.canShowResults {
            title = "Race Results"
            tabBarItem = UITabBarItem(title: "Results", image: SystemImg.medal, selectedImage: SystemImg.medalFill)
        } else {
            title = "Racing Pilots"
            tabBarItem = UITabBarItem(title: "Pilots", image: SystemImg.person, selectedImage: SystemImg.personFill)
        }
        
        navigationItem.rightBarButtonItems = raceController.navigationItems()
    }

    // MARK: - Actions

    func showUserProfile(forUserAt indexPath: IndexPath) {
        let viewModel = userViewModels[indexPath.row]
        let cell = tableView.cellForRow(at: indexPath) as! AvatarTableViewCell

        guard canInteract(with: cell) else { return }
        setLoading(cell, loading: true)

        // needs to search for a User since we don't have its id
        userApi.searchUser(with: viewModel.username) { [weak self] (user, error) in
            if let user = user {
                let vc = UserViewController(with: user)
                self?.navigationController?.pushViewController(vc, animated: true)
            } else if let _ = error {
                // handle error
            }
            self?.setLoading(cell, loading: false)
        }
    }

    func setLoading(_ cell: AvatarTableViewCell, loading: Bool) {
        cell.isLoading = loading
        didTapCell = loading
    }

    @objc fileprivate func didPullRefreshControl() {
        reloadRace()
    }

    func canInteract(with cell: AvatarTableViewCell) -> Bool {
        guard !cell.isLoading else { return false }
        guard !didTapCell else { return false }
        return true
    }
    
    @objc func didLongPress(_ gesture: UIGestureRecognizer) {
        let location = gesture.location(in: tableView)
        guard let indexPath = tableView.indexPathForRow(at: location) else { return }

        guard gesture.state == .began else {
            tableView.deselectRow(at: indexPath, animated: true)
            return
        }

        tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
        guard race.canBeEdited else { return }

        let viewModel = userViewModels[indexPath.row]
        let deselect = { [weak self] in self?.tableView.deselectRow(at: indexPath, animated: true) }

        ActionSheetUtil.presentDestructiveActionSheet(
            withTitle: "Remove \(viewModel.username) from this race?",
            destructiveTitle: "Yes, Remove",
            completion: { [weak self] _ in
                guard let self else { return }
                raceApi.forceResign(race: race.id, pilotId: viewModel.userId) { status, error in
                    if let error {
                        AlertUtil.presentAlertMessage(
                            "Couldn't remove this pilot from the race. Please try again later. \(error.localizedDescription)",
                            title: "Error", delay: 0.5)
                    } else {
                        self.reloadRace()
                    }
                    deselect()
                }
            },
            cancel: { _ in deselect() }
        )
    }

    // MARK: - Data Update

    // ViewJoinable
    func loadContent(forced: Bool = false) {
        userViewModels = raceController.raceUserViewModels()
        resetTableView()
    }

    // RaceTabbable
    func reloadContent() {
        loadContent(forced: true)
    }

    fileprivate func reloadRace() {
        raceController.reloadRace()
    }

    func resetTableView() {
        tableView.reloadData()
        invalidatePinnedView()

        tableView.setContentOffset(CGPoint(x: 0, y: -tableView.adjustedContentInset.top), animated: false)

        if refreshControl.isRefreshing {
            refreshControl.endRefreshing()
        }
    }

    // MARK: - Pinnable

    func canPinView() -> Bool {
        return myUserId != nil
    }

    func pinnedViewIndexPath() -> IndexPath? {
        guard race.canShowResults, let userId = myUserId else { return nil }

        if let cached = cachedPinnedIndexPath {
            return cached
        }

        let section = showingExternalResults() ? 1 : 0
        guard let index = userViewModels.firstIndex(where: { $0.userId == userId }) else {
            return nil
        }

        let indexPath = IndexPath(row: index, section: section)
        cachedPinnedIndexPath = indexPath
        return indexPath
    }
}

extension RacePilotsViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        if showingExternalResults(), indexPath.section == externalResultSection {
            guard let url = race.liveTimeEventUrl else { return }
            WebViewController.open(url)
        } else {
            showUserProfile(forUserAt: indexPath)
        }

        tableView.deselectRow(at: indexPath, animated: true)
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {

        if (showingExternalResults() && section == externalResultSection) {
            return nil
        }

        if race.canShowResults {
            return "\(race.scoringFormat.title)"
        } else {
            return nil
        }
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard userViewModels.count > 0 else { return 0 }
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let visibleIndexPaths = tableView.indexPathsForVisibleRows else { return }

        // Best spot to lay the pinned view for the first time
        if indexPath == visibleIndexPaths.max() && !didShowPinnedView {
            DispatchQueue.main.async {
                self.invalidatePinnedView()
                self.didShowPinnedView = true
            }
        }
    }
}

extension RacePilotsViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return showingExternalResults() ? 2 : 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if showingExternalResults(), section == externalResultSection {
            return 1
        } else {
            return userViewModels.count
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if showingExternalResults(), indexPath.section == externalResultSection {
            return formTableViewCell(for: indexPath)
        } else {
            return avatarTableViewCell(for: indexPath)
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if showingExternalResults(), indexPath.section == externalResultSection {
            return UniversalConstants.cellFormHeight
        } else {
            return Constants.cellHeight
        }
    }

    func avatarTableViewCell(for indexPath: IndexPath) -> AvatarTableViewCell {
        let cell = tableView.dequeueReusableCell(forIndexPath: indexPath) as AvatarTableViewCell
        configure(cell, forRowAt: indexPath)
        return cell
    }

    func formTableViewCell(for indexPath: IndexPath) -> FormTableViewCell {
        let cell = tableView.dequeueReusableCell(forIndexPath: indexPath) as FormTableViewCell

        cell.textLabel?.text = nil
        cell.detailImage = nil

        guard let url = race.liveTimeEventUrl, let web = AppWeb(url: url) else { return cell }

        cell.textLabel?.text = "View full results on"
        cell.detailImage = web.image
        
        if cell.detailImage == nil {
            cell.detailTextLabel?.text = URL(string: url)?.rootDomain ?? ""
        }

        return cell
    }

    func configure<T>(_ view: T, forRowAt indexPath: IndexPath) where T : UITableViewCell {
        guard let cell = view as? AvatarTableViewCell else { return }

        let viewModel = userViewModels[indexPath.row]

        cell.avatarImageView.imageView.setImage(with: viewModel.pictureUrl, placeholderImage: PlaceholderImg.medium)
        cell.titleLabel.text = viewModel.username
        cell.subtitleLabel.text = ResultEntryViewModel.noResultPlaceholder
        cell.rankView.rank = nil
        cell.textPill.text = nil
        cell.textPill.style = .badge
        cell.titleLabel.textColor = Color.black
        cell.subtitleLabel.textColor = Color.gray300
        cell.rankView.titleLabel.textColor = Color.gray300
        cell.backgroundColor = (indexPath.row % 2 == 0) ? Color.white : Color.gray20
        cell.selectedBackgroundView?.backgroundColor = Color.gray50

        if race.canShowResults {
            var score:Int32? = 0
            cell.rankView.rank = score

            if let resultEntry = viewModel.resultEntry {
                let resultEntryVM = ResultEntryViewModel(with: resultEntry, from: race)
                if (!race.isGQ) { score = viewModel.score }

                if resultEntryVM.resultLabel != nil {
                    cell.subtitleLabel.text = resultEntryVM.resultLabel
                    cell.rankView.rank = Int32(indexPath.row+1)
                }
            } else if let raceEntry = viewModel.raceEntry {
                if (!race.isGQ) { score = raceEntry.score }

                if (score ?? 0 > 0) {
                    cell.rankView.rank = Int32(indexPath.row+1)
                    cell.subtitleLabel.text = ResultEntryViewModel.noTimesPlaceholder
                }
            }

            if let score = score, score > 0 {
                let unit = (score == 1) ? "pt" : "pts"
                cell.textPill.text = "\(score) \(unit)"
                cell.textPill.style = .text
                cell.rankView.rank = Int32(indexPath.row+1)
            }

            if let userId = myUserId, viewModel.userId == userId {
                cell.titleLabel.textColor = Color.white
                cell.subtitleLabel.textColor = Color.gray20
                cell.rankView.titleLabel.textColor = Color.gray20
                cell.backgroundColor = Color.gray200
                cell.selectedBackgroundView?.backgroundColor = Color.gray300
            }
        }

        // only real races have frequencies
        if !race.hasEnded && race.raceClass != .esport {
           cell.textPill.text = viewModel.channelLabel
       }
    }
}

extension RacePilotsViewController: UIScrollViewDelegate {

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        layoutPinnedView()
    }
}

extension RacePilotsViewController: ScrollToTop {

    func scrollToTop() {
        tableView.setContentOffset(.zero, animated: true)
    }
}

extension RacePilotsViewController: EmptyDataSetSource {

    func title(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        emptyStateNoPilots.title
    }

    func description(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        return emptyStateNoPilots.description
    }

    func buttonTitle(forEmptyDataSet scrollView: UIScrollView, for state: UIControl.State) -> NSAttributedString? {
        if race.status == .open && !race.hasStarted {
            return emptyStateNoPilots.buttonTitle(state)
        } else {
            return nil
        }
    }

    func verticalOffset(forEmptyDataSet scrollView: UIScrollView) -> CGFloat {
        return -scrollView.adjustedContentInset.top
    }

    func backgroundColor(forEmptyDataSet scrollView: UIScrollView) -> UIColor? {
        return Color.white
    }
}

extension RacePilotsViewController: EmptyDataSetDelegate {

    func emptyDataSetShouldAllowScroll(_ scrollView: UIScrollView) -> Bool {
        return false
    }

    func emptyDataSet(_ scrollView: UIScrollView, didTapButton button: UIButton) {

        let currentState: JoinState = .notJoined

        AppControl.shared.tryJoining(race: race, raceApi: raceApi) { [weak self] (newState) in
            if currentState != newState {
                self?.reloadRace()
            }
        }
    }
}
