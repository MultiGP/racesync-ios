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

class RacePilotsViewController: UIViewController, ViewJoinable, RaceTabbable {

    // MARK: - Public Variables

    var race: Race

    // MARK: - Private Variables

    lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.emptyDataSetDelegate = self
        tableView.emptyDataSetSource = self
        tableView.tableFooterView = UIView()
        tableView.backgroundColor = Color.gray50
        tableView.register(cellType: AvatarTableViewCell.self)
        return tableView
    }()

    fileprivate var isLoading: Bool {
        get { return tabBarController.isLoading }
        set { }
    }

    override var tabBarController: RaceTabBarController {
        return super.tabBarController as! RaceTabBarController
    }

    fileprivate var raceApi = RaceApi()
    fileprivate var userApi = UserApi()
    fileprivate var userViewModels = [UserViewModel]()

    fileprivate var emptyStateRaceRegisters = EmptyStateViewModel(.noRaceRegisters)
    fileprivate var didTapCell: Bool = false

    fileprivate var showingResults: Bool {
        guard let results = race.results, results.count > 0 else { return false }
        guard let startDate = race.startDate else { return false }
        return startDate.isPassed
    }

    fileprivate enum Constants {
        static let padding: CGFloat = UniversalConstants.padding
        static let buttonSpacing: CGFloat = 12
    }

    // MARK: - Initialization

    init(with race: Race) {
        self.race = race

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
        populateData()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    // MARK: - Layout

    fileprivate func setupLayout() {

        view.backgroundColor = Color.white

        view.addSubview(tableView)
        tableView.snp.makeConstraints {
            $0.top.leading.trailing.bottom.equalToSuperview()
        }
    }

    fileprivate func configureNavigationItems() {

        title = showingResults ? "Race Results" : "Pilots Racing"
        let itemTitle = showingResults ? "Results" : "Pilots"
        tabBarItem = UITabBarItem(title: itemTitle, image: UIImage(named: "icn_tabbar_roster"), selectedImage: nil)

        var buttons = [UIButton]()

        if race.isMyChapter {
            let editButton = CustomButton(type: .system)
            editButton.addTarget(self, action: #selector(didPressEditButton), for: .touchUpInside)
            editButton.setImage(ButtonImg.edit, for: .normal)
            buttons += [editButton]
        }

        let shareButton = CustomButton(type: .system)
        shareButton.addTarget(tabBarController, action: #selector(tabBarController.didPressShareButton), for: .touchUpInside)
        shareButton.setImage(ButtonImg.share, for: .normal)
        buttons += [shareButton]

        let stackView = UIStackView(arrangedSubviews: buttons)
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.alignment = .lastBaseline
        stackView.spacing = Constants.buttonSpacing
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: stackView)
    }

    fileprivate func populateData() {

        var viewModels = [UserViewModel]()

        func populateScore(in userViewModels: [UserViewModel]) {
            guard race.isGQ == false else { return } // Don't display points for GQ race results

            for vm in userViewModels {
                if let raceEntry = race.entries?.filter ({ return $0.pilotId == vm.userId }).first {
                    vm.score = raceEntry.score
                }
            }
        }

        if showingResults, let results = ResultEntryViewModel.combinedResults(from: race.results, for: race.trueScoringFormat) {
            viewModels += UserViewModel.viewModelsFromResults(results)
            populateScore(in: viewModels)
        }

        if let entries = race.entries, entries.count > 0 {
            // We need to include the pilots that didn't complete laps still
            if viewModels.count > 0, viewModels.count < entries.count {
                viewModels += UserViewModel.viewModels(viewModels, withoutResults: entries)
                populateScore(in: viewModels)

            // No race results, so let's just populate with race entries instead
            } else if viewModels.count == 0 {
                viewModels += UserViewModel.viewModelsFromEntries(entries)
            }
        }

        userViewModels = viewModels
    }

    func reloadContent() {
        populateData()
        tableView.reloadData()
    }

    fileprivate func reloadRaceView() {
        tabBarController.reloadRaceView()
    }

    // MARK: - Actions

    @objc func didPressEditButton() {
        let vc = RacePilotsPickerController(with: race, raceId: tabBarController.raceId)
        vc.externalUserViewModels = userViewModels
        vc.delegate = self

        let nc = NavigationController(rootViewController: vc)
        present(nc, animated: true)
    }
}

fileprivate extension RacePilotsViewController {

    func setLoading(_ cell: AvatarTableViewCell, loading: Bool) {
        cell.isLoading = loading
        didTapCell = loading
    }
    
    func canInteract(with cell: AvatarTableViewCell) -> Bool {
        guard !cell.isLoading else { return false }
        guard !didTapCell else { return false }
        return true
    }

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
}

extension RacePilotsViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        showUserProfile(forUserAt: indexPath)
        tableView.deselectRow(at: indexPath, animated: true)
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if showingResults {
            if race.isGQ {
                return "GQ Results: \(ScoringFormat.fastest3Laps.title)"
            } else {
                return race.scoringFormat.title
            }
        } else {
            return nil
        }
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard userViewModels.count > 0 else { return 0 }
        return UITableView.automaticDimension
    }
}

extension RacePilotsViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return userViewModels.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return avatarTableViewCell(for: indexPath)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UniversalConstants.cellHeight
    }

    func avatarTableViewCell(for indexPath: IndexPath) -> AvatarTableViewCell {
        let userVM = userViewModels[indexPath.row]
        let cell = tableView.dequeueReusableCell(forIndexPath: indexPath) as AvatarTableViewCell

        cell.avatarImageView.imageView.setImage(with: userVM.pictureUrl, placeholderImage: PlaceholderImg.medium)
        cell.titleLabel.text = userVM.displayName
        cell.subtitleLabel.text = ResultEntryViewModel.noResultPlaceholder
        cell.textPill.text = showingResults ? nil : userVM.channelLabel // hidden when results visible
        cell.textPill.style = .badge
        cell.rankView.rank = nil

        if showingResults {
            if let resultEntry = userVM.resultEntry {
                let resultEntryVM = ResultEntryViewModel(with: resultEntry, from: race)

                if resultEntryVM.resultLabel != nil {
                    cell.subtitleLabel.text = resultEntryVM.resultLabel
                    cell.rankView.rank = Int32(indexPath.row+1)
                }
            }

            if let score = userVM.score, score > 0 {
                let unit = (score == 1) ? "pt" : "pts"
                cell.textPill.text = "\(score) \(unit)"
                cell.textPill.style = .text
                cell.rankView.rank = Int32(indexPath.row+1)
            }
        }

        return cell
    }
}

extension RacePilotsViewController: RacePilotsPickerControllerDelegate {

    func pickerControllerDidUpdate(_ viewController: RacePilotsPickerController) {
        reloadRaceView()
    }
}

extension RacePilotsViewController: EmptyDataSetSource {

    func title(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        emptyStateRaceRegisters.title
    }

    func description(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        return emptyStateRaceRegisters.description
    }

    func buttonTitle(forEmptyDataSet scrollView: UIScrollView, for state: UIControl.State) -> NSAttributedString? {
        guard let startDate = race.startDate else { return nil }
        if race.status == .open && !startDate.isPassed {
            return emptyStateRaceRegisters.buttonTitle(state)
        } else {
            return nil
        }
    }

    func backgroundColor(forEmptyDataSet scrollView: UIScrollView) -> UIColor? {
        return Color.white
    }
}

extension RacePilotsViewController: EmptyDataSetDelegate {

    func emptyDataSetShouldDisplay(_ scrollView: UIScrollView) -> Bool {
        return !isLoading
    }

    func emptyDataSetShouldAllowScroll(_ scrollView: UIScrollView) -> Bool {
        return false
    }

    func emptyDataSet(_ scrollView: UIScrollView, didTapButton button: UIButton) {

        let currentState: JoinState = .join

        join(race: race, raceApi: raceApi) { [weak self] (newState) in
            if currentState != newState {
                self?.reloadRaceView()
            }
        }
    }

    func verticalOffset(forEmptyDataSet scrollView: UIScrollView) -> CGFloat {
        return -(view.safeAreaInsets.top + view.safeAreaInsets.bottom)
    }
}
