//
//  RacePaymentsViewController.swift
//  RaceSync
//
//  Created by Ignacio Romero Zurbuchen on 2025-08-07.
//  Copyright © 2025 MultiGP Inc. All rights reserved.
//

import UIKit
import SnapKit
import RaceSyncAPI
import EmptyDataSet_Swift

fileprivate enum Column: String, EnumTitle {
    case pilot = "Pilot"
    case paid = "Paid"
    case received = "Received"

    var title: String { rawValue }
}

class RacePaymentsViewController: UIViewController, RaceTabbable {

    // MARK: - Public Variables

    var raceController: RaceController

    var race: Race {
        get { return raceController.race! }
    }

    var raceApi: RaceApi {
        get { return raceController.raceApi }
    }

    override var tabBarController: RaceTabBarController {
        return super.tabBarController as! RaceTabBarController
    }

    // MARK: - Private Variables

    lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.emptyDataSetSource = self
        tableView.emptyDataSetDelegate = self
        tableView.tableHeaderView = UIView()
        tableView.tableFooterView = UIView()
        tableView.backgroundColor = Color.clear
        tableView.register(cellType: ColumnTableViewCell.self)
        tableView.register(ColumnTableViewHeaderView.self, forHeaderFooterViewReuseIdentifier: ColumnTableViewHeaderView.identifier)
        tableView.refreshControl = self.refreshControl
        return tableView
    }()

    fileprivate lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.backgroundColor = Color.clear
        refreshControl.tintColor = Color.blue
        refreshControl.addTarget(self, action: #selector(didPullRefreshControl), for: .valueChanged)
        return refreshControl
    }()

    fileprivate lazy var activityIndicatorView: UIActivityIndicatorView = {
        return UIActivityIndicatorView(style: .medium)
    }()

    fileprivate lazy var headerView: ColumnTableViewHeaderView = {
        let view = ColumnTableViewHeaderView()
        view.addColumn(with: Column.pilot.title, orientation: .left) // TODO: Let the subview do the chevron layout logic. Use an enum to track each column type
        view.addColumn(with: Column.paid.title, orientation: .right)
        view.addColumn(with: Column.received.title, orientation: .right)
        view.addTarget(self, action: #selector(didPressColumnTitle))
        return view
    }()

    fileprivate var isLoading: Bool = false {
        didSet {
            if isLoading {
                activityIndicatorView.startAnimating()
                tableView.isUserInteractionEnabled = false
            }
            else {
                activityIndicatorView.stopAnimating()
                tableView.isUserInteractionEnabled = true
            }
        }
    }

    fileprivate var userApi = UserApi()
    fileprivate var userPaymentPairs: [(user: UserViewModel, payment: RacePayment?)] = []
    fileprivate var userViewModelCache = [ObjectId: UserViewModel]()

    fileprivate var sortingColumn: Column = .pilot
    fileprivate var sortingAscending = true
    fileprivate let emptyStateNoPayments = EmptyStateViewModel(.noRacePayments)

    fileprivate let mainSection: Int = 0
    fileprivate var totalPaid: Float32 = 0
    fileprivate var totalReceived: Float32 = 0

    fileprivate enum Constants {
        static let padding: CGFloat = UniversalConstants.padding
        static let cellHeight: CGFloat = 80
        static let buttonSpacing: CGFloat = 12
        static let maximumConcurrentUserRequests = 4
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
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }

    // MARK: - Layout

    fileprivate func setupLayout() {

        view.backgroundColor = Color.gray50

        view.addSubview(tableView)
        tableView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.width.equalTo(UIScreen.main.bounds.width)
        }

        view.addSubview(activityIndicatorView)
        activityIndicatorView.snp.makeConstraints {
            $0.centerX.centerY.equalToSuperview()
        }
    }

    fileprivate func configureNavigationItems() {

        title = "Payments"
        tabBarItem = UITabBarItem(title: title, image: SystemImg.banknote, selectedImage: SystemImg.banknoteFill)
        tabBarItem.isEnabled = true

        navigationItem.rightBarButtonItems = raceController.navigationItems()
    }

    // MARK: - Content

    fileprivate func loadContent() {

        if userPaymentPairs.count == 0 {
            isLoading = true
        }

        var userViewModels = [UserViewModel]()

        if let entries = race.entries {
            userViewModels = UserViewModel.viewModelsFromEntries(entries)
        }

        raceApi.getRacePayments(with: race.id) { payments, error in
            guard let payments = payments, payments.count > 0 else {
                return self.finishLoading()
            }

            let userPilotIds = Set(userViewModels.map { $0.userId })
            let missingPilotIds = Set(payments.map { $0.pilotId })
                .subtracting(userPilotIds)
                .filter { !$0.isEmpty }

            self.calculateTotals(from: payments)

            guard !missingPilotIds.isEmpty else {
                self.pair(payments: payments, with: userViewModels)
                return self.finishLoading()
            }

            self.loadUserViewModels(for: missingPilotIds) { [weak self] additionalUsers in
                guard let self else { return }

                userViewModels.append(contentsOf: additionalUsers)
                self.pair(payments: payments, with: userViewModels)
                self.finishLoading()
            }
        }
    }

    fileprivate func loadUserViewModels(for userIds: Set<ObjectId>, completion: @escaping ([UserViewModel]) -> Void) {
        var users = userIds.compactMap { userViewModelCache[$0] }
        var unresolvedIds = Array(userIds.filter { userViewModelCache[$0] == nil })

        guard !unresolvedIds.isEmpty else {
            return completion(users)
        }

        func loadNextBatch() {
            let batchSize = min(Constants.maximumConcurrentUserRequests, unresolvedIds.count)
            let ids = Array(unresolvedIds.prefix(batchSize))
            unresolvedIds.removeFirst(batchSize)

            let group = DispatchGroup()

            for id in ids {
                group.enter()
                userApi.getUser(with: id) { [weak self] user, _ in
                    DispatchQueue.main.async {
                        defer { group.leave() }
                        guard let self, let user else { return }

                        let viewModel = UserViewModel(with: user)
                        self.userViewModelCache[id] = viewModel
                        users.append(viewModel)
                    }
                }
            }

            group.notify(queue: .main) {
                if unresolvedIds.isEmpty {
                    completion(users)
                } else {
                    loadNextBatch()
                }
            }
        }

        loadNextBatch()
    }

    fileprivate func calculateTotals(from payments: [RacePayment]) {
        totalPaid = 0
        totalReceived = 0

        for payment in payments {
            totalPaid += payment.amountPaid
            totalReceived += payment.netAmount
        }
    }

    fileprivate func pair(payments: [RacePayment], with userViewModels: [UserViewModel]) {
        // Create dictionary for quick lookup
        let paymentDict = Dictionary(uniqueKeysWithValues: payments.map { ($0.pilotId, $0) })

        // Map all users into tuple with matching payment (if any)
        userPaymentPairs = userViewModels.map { viewModel in
            (user: viewModel, payment: paymentDict[viewModel.userId])
        }

        // sort by username as default
        sortByUsername(order: sortingAscending)
    }

    fileprivate func sortByUsername(order: Bool = true) {
        userPaymentPairs.sort {
            let comparison = $0.user.username.localizedCaseInsensitiveCompare($1.user.username)
            return comparison == (order ? .orderedAscending : .orderedDescending)
        }
    }

    fileprivate func sortByPaid(order: Bool = true) {
        userPaymentPairs.sort {
            let a = $0.payment?.amountPaid ?? 0
            let b = $1.payment?.amountPaid ?? 0
            return order ? a < b : a > b
        }
    }

    fileprivate func sortByReceived(order: Bool = true) {
        userPaymentPairs.sort {
            let a = $0.payment?.netAmount ?? 0
            let b = $1.payment?.netAmount ?? 0
            return order ? a < b : a > b
        }
    }

    fileprivate func finishLoading() {
        isLoading = false

        if refreshControl.isRefreshing {
            refreshControl.endRefreshing()
        }

        tableView.reloadData()
    }

    func reloadContent() {
        loadContent()
    }

    // MARK: - Action

    @objc func didPressEditButton() {
        let users = userPaymentPairs.map { $0.user }

        let vc = RacePilotsPickerController(with: race)
        vc.externalUserViewModels = users
        vc.delegate = self

        let nc = NavigationController(rootViewController: vc)
        present(nc, animated: true)
    }

    @objc fileprivate func didPressColumnTitle(_ sender: UIButton) {
        guard let title = sender.title(for: .normal), let column = Column(title: title) else { return }

        if column == sortingColumn, sortingAscending == true {
            sortingAscending = false
        } else {
            sortingAscending = true
        }

        switch column {
        case .pilot:
            sortByUsername(order: sortingAscending)
        case .paid:
            sortByPaid(order: sortingAscending)
        case .received:
            sortByReceived(order: sortingAscending)
        }

        sortingColumn = column

        tableView.reloadData()
    }

    @objc fileprivate func didPullRefreshControl() {
        reloadContent()
    }
}

extension RacePaymentsViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard userPaymentPairs.count > 0 else { return nil }

        if section == mainSection {
            guard !isLoading else { return nil }
            return headerView
        }
        return nil
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard userPaymentPairs.count > 0 else { return 0 }

        if section == mainSection {
            return ColumnTableViewHeaderView.headerHeight
        }
        return 0
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return ColumnTableViewCell.height
    }
}

extension RacePaymentsViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        guard userPaymentPairs.count > 0 else { return 0 }
        return 2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == mainSection {
            return userPaymentPairs.count
        }
        return 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == mainSection {
            return paymentTableViewCell(for: indexPath)
        } else {
            return totalTableViewCell(for: indexPath)
        }
    }

    func paymentTableViewCell(for indexPath: IndexPath) -> ColumnTableViewCell {
        let cell = tableView.dequeueReusableCell(forIndexPath: indexPath) as ColumnTableViewCell

        let pair = userPaymentPairs[indexPath.row]
        let user = pair.user
        let payment = pair.payment
        let backgroundColor = user.isJoined ? Color.white : Color.red.withAlphaComponent(0.2)

        cell.textLabel?.text = user.isJoined ? user.username : "\(user.username) (Not Joined)"
        cell.detailTextLabel?.text = user.fullName
        cell.columnLabel1.text = String(format: "$%.2f", payment?.amountPaid ?? 0)
        cell.columnLabel2.text = String(format: "$%.2f", payment?.netAmount ?? 0)
        cell.backgroundView?.backgroundColor = backgroundColor
        return cell
    }

    func totalTableViewCell(for indexPath: IndexPath) -> ColumnTableViewCell {
        let cell = tableView.dequeueReusableCell(forIndexPath: indexPath) as ColumnTableViewCell

        cell.textLabel?.text = "Total:"
        cell.detailTextLabel?.text = nil
        cell.columnLabel1.text = String(format: "$%.2f", totalPaid)
        cell.columnLabel2.text = String(format: "$%.2f", totalReceived)
        cell.backgroundView?.backgroundColor = Color.white
        return cell
    }
}

extension RacePaymentsViewController: RacePilotsPickerControllerDelegate {

    func pickerControllerDidUpdate(_ viewController: RacePilotsPickerController) {
        reloadContent()
    }
}

extension RacePaymentsViewController: EmptyDataSetSource {

    func title(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        return emptyStateNoPayments.title
    }

    func description(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        return emptyStateNoPayments.description
    }

    func image(forEmptyDataSet scrollView: UIScrollView) -> UIImage? {
        return nil
    }

    func verticalOffset(forEmptyDataSet scrollView: UIScrollView) -> CGFloat {
        return -scrollView.adjustedContentInset.top
    }

    func backgroundColor(forEmptyDataSet scrollView: UIScrollView) -> UIColor? {
        return Color.white
    }
}

extension RacePaymentsViewController: EmptyDataSetDelegate {

    func emptyDataSetShouldAllowScroll(_ scrollView: UIScrollView) -> Bool {
        return false
    }
}
