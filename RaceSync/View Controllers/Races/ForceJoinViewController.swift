//
//  ForceJoinViewController.swift
//  RaceSync
//
//  Created by Ignacio Romero Zurbuchen on 2020-03-21.
//  Copyright © 2020 MultiGP Inc. All rights reserved.
//

import UIKit
import SnapKit
import RaceSyncAPI
import EmptyDataSet_Swift
import ShimmerSwift

class ForceJoinViewController: ViewController, Shimmable {

    // MARK: - Public Variables

    lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.register(UserTableViewCell.self, forCellReuseIdentifier: UserTableViewCell.identifier)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.tableFooterView = UIView()

        return tableView
    }()

    let shimmeringView: ShimmeringView = defaultShimmeringView()

    // MARK: - Private Variables

    fileprivate var race: Race
    fileprivate let raceApi = RaceApi()
    fileprivate var chapterApi = ChapterApi()
    fileprivate var userApi = UserApi()

    fileprivate var userViewModels = [UserViewModel]()

    fileprivate enum Constants {
        static let padding: CGFloat = UniversalConstants.padding
    }

    // MARK: - Initialization

    init(with race: Race) {
        self.race = race

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()

        setupLayout()
        loadUsers()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    // MARK: - Layout

    func setupLayout() {

        title = "Force Join Pilots"

        view.backgroundColor = Color.white

        view.addSubview(tableView)
        tableView.snp.makeConstraints {
            $0.top.leading.trailing.bottom.equalToSuperview()
        }

        view.addSubview(shimmeringView)
        shimmeringView.snp.makeConstraints {
            $0.top.leading.trailing.bottom.equalToSuperview()
        }
    }

    // MARK: - Actions

    @objc func didPressJoinButton(_ sender: Any) {
        guard let button = sender as? JoinButton, let userId = button.accessibilityIdentifier else { return }
        guard let viewModel = userViewModels.filter ({ return $0.user?.id == userId }).first, let user = viewModel.user else { return }

        button.isLoading = true
        let state = button.joinState

        if user.hasJoined(race) {
            ActionSheetUtil.presentDestructiveActionSheet(withTitle: "Resign \(viewModel.username) from the race?", message: nil, destructiveTitle: "Yes, resign", completion: { (action) in
                self.resignUser(with: userId) { (newState) in
                    button.isLoading = false

                    if state != newState {
                        button.joinState = newState
                    }
                }
            }) { (action) in
                 button.isLoading = false
            }
        } else {
            ActionSheetUtil.presentDestructiveActionSheet(withTitle: "Force join \(viewModel.username) to the race?", destructiveTitle: "Yes, force join", completion: { (action) in
                self.forceJoinUser(with: userId) { (newState) in
                    button.isLoading = false

                    if state != newState {
                        button.joinState = newState
                    }
                }
            }) { (action) in
                 button.isLoading = false
            }
        }
    }

    func forceJoinUser(with id: ObjectId, completion: @escaping JoinStateCompletionBlock) {

        raceApi.forceJoin(race: race.id, pilotId: id) { (status, error) in
            if status == true {
                completion(.joined)
                // TODO: Reload race entries
            } else if let error = error {
                completion(.join)
                AlertUtil.presentAlertMessage("Couldn't force join this user to the race. Please try again later. \(error.localizedDescription)", title: "Error", delay: 0.5)
            } else {
                completion(.join)
            }
        }
    }

    func resignUser(with id: ObjectId, completion: @escaping JoinStateCompletionBlock) {

        raceApi.forceResign(race: race.id, pilotId: id) { (status, error) in
            if status == true {
                completion(.join)
                // TODO: Reload race entries
            } else if let error = error {
                completion(.joined)
                AlertUtil.presentAlertMessage("Couldn't remove this user from the race. Please try again later. \(error.localizedDescription)", title: "Error", delay: 0.5)
            } else {
                completion(.joined)
            }
        }
    }
}

extension ForceJoinViewController {

    func loadUsers() {
        if userViewModels.isEmpty {
            isLoading(true)

            fetchUsers { [weak self] in
                self?.isLoading(false)
                self?.tableView.reloadData()
            }
        } else {
            tableView.reloadData()
        }
    }

    func fetchUsers(_ completion: VoidCompletionBlock? = nil) {
        chapterApi.getUsers(with: race.chapterId) { [weak self] (users, error) in
            if let users = users {
                self?.userViewModels = UserViewModel.viewModels(with: users)
            } else {
                Clog.log("getMyRaces error : \(error.debugDescription)")
            }

            completion?()
        }
    }
}

extension ForceJoinViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension ForceJoinViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return userViewModels.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let viewModel = userViewModels[indexPath.row]
        return userTableViewCell(for: viewModel)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UserTableViewCell.height
    }

    func userTableViewCell(for viewModel: UserViewModel) -> UserTableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: UserTableViewCell.identifier) as! UserTableViewCell
        guard let user = viewModel.user else { return cell }

        cell.titleLabel.text = viewModel.pilotName
        cell.avatarImageView.imageView.setImage(with: viewModel.pictureUrl, placeholderImage: UIImage(named: "placeholder_medium"))
        cell.subtitleLabel.text = viewModel.fullName

        let joinButton = JoinButton(type: .system)
        joinButton.addTarget(self, action: #selector(didPressJoinButton), for: .touchUpInside)
        joinButton.hitTestEdgeInsets = UIEdgeInsets(proportionally: -10)
        joinButton.accessibilityIdentifier = user.id

        if user.hasJoined(race) {
            joinButton.joinState = .joined
        } else {
            joinButton.joinState = .join
            joinButton.setTitle("Force Join", for: .normal)
        }

        cell.accessoryType = .none
        cell.contentView.addSubview(joinButton)
        joinButton.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.height.equalTo(JoinButton.minHeight)
            $0.width.equalTo(92)
            $0.trailing.equalToSuperview().offset(-Constants.padding)
        }

        return cell
    }
}
