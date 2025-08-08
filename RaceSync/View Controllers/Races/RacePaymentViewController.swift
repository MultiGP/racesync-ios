//
//  RacePaymentViewController.swift
//  RaceSync
//
//  Created by Ignacio Romero Zurbuchen on 2025-08-07.
//  Copyright © 2025 MultiGP Inc. All rights reserved.
//

import UIKit
import SnapKit
import RaceSyncAPI

class RacePaymentViewController: UIViewController, RaceTabbable {

    // MARK: - Public Variables

    var race: Race

    // MARK: - Private Variables

    lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.tableFooterView = UIView()
        tableView.backgroundColor = Color.gray50
        
        tableView.register(cellType: ColumnTableViewCell.self)
        tableView.register(ColumnTableViewHeaderView.self, forHeaderFooterViewReuseIdentifier: ColumnTableViewHeaderView.identifier)
        tableView.refreshControl = self.refreshControl
        return tableView
    }()

    fileprivate lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.backgroundColor = Color.white
        refreshControl.tintColor = Color.blue
        refreshControl.addTarget(self, action: #selector(didPullRefreshControl), for: .valueChanged)
        return refreshControl
    }()

    fileprivate lazy var activityIndicatorView: UIActivityIndicatorView = {
        return UIActivityIndicatorView(style: .medium)
    }()

    fileprivate lazy var headerView: ColumnTableViewHeaderView = {
        let header = ColumnTableViewHeaderView()
        header.addColumn(with: "⇅ Pilot", orientation: .left) // TODO: Let the subview do the chevron layout logic. Use an enum to track each column type
        header.addColumn(with: "⇅ Paid", orientation: .right)
        header.addColumn(with: "⇅ Received", orientation: .right)
        header.addTarget(self, action: #selector(didPressColumnTitle))
        return header
    }()

    override var tabBarController: RaceTabBarController {
        return super.tabBarController as! RaceTabBarController
    }

    fileprivate var isLoading: Bool = false {
        didSet {
            if isLoading { activityIndicatorView.startAnimating() }
            else { activityIndicatorView.stopAnimating() }
        }
    }

    fileprivate var raceApi = RaceApi()
    fileprivate var userApi = UserApi()
    fileprivate var userViewModels = [UserViewModel]()
    fileprivate var payments = [RacePayment]()

    fileprivate enum Constants {
        static let padding: CGFloat = UniversalConstants.padding
        static let cellHeight: CGFloat = UniversalConstants.cellHeight
        static let buttonSpacing: CGFloat = 12
    }

    // MARK: - Initialization

    init(with race: Race) {
        self.race = race
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
        populateData()
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

        view.backgroundColor = Color.white

        view.addSubview(activityIndicatorView)
        activityIndicatorView.snp.makeConstraints {
            $0.centerX.centerY.equalToSuperview()
        }

        view.addSubview(tableView)
        tableView.snp.makeConstraints {
            $0.top.leading.trailing.bottom.equalToSuperview()
        }
    }

    fileprivate func configureNavigationItems() {

        title = "Pilot Payments"
        tabBarItem = UITabBarItem(title: "Payments", image: SystemImg.banknote, selectedImage: SystemImg.banknoteFill)
        tabBarItem.isEnabled = true

        var buttons = [UIButton]()

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

    // MARK: - Content

    fileprivate func populateData() {

        self.isLoading = true

        if let entries = race.entries {
            userViewModels = UserViewModel.viewModelsFromEntries(entries)
        }

        raceApi.getRacePayments(with: race.id) { payments, error in
            if let payments = payments {
                self.payments = payments
            } else if let _ = error {
                // handle error
            }
            self.isLoading = false
            self.tableView.reloadData()
        }
    }

    @objc fileprivate func didPullRefreshControl() {
        // TODO: Implement refresh. Should reload parent too.
    }

    func reloadContent() {
        populateData()
        tableView.reloadData()
    }

    // MARK: - Action

    @objc fileprivate func didPressColumnTitle(_ sender: Any) {

        // TODO: Implement Sorting
    }
}

extension RacePaymentViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        let viewModel = userViewModels[indexPath.row]

        tableView.deselectRow(at: indexPath, animated: true)
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return headerView
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return ColumnTableViewHeaderView.headerHeight
    }
}

extension RacePaymentViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        payments.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return columnTableViewCell(for: indexPath)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UniversalConstants.cellFormHeight
    }

    func columnTableViewCell(for indexPath: IndexPath) -> ColumnTableViewCell {
        let cell = tableView.dequeueReusableCell(forIndexPath: indexPath) as ColumnTableViewCell

        let payment = payments[indexPath.row]
        cell.textLabel?.text = payment.pilotId
        cell.columnLabel1.text = String(format: "$%.2f", payment.amountPaid)
        cell.columnLabel2.text = String(format: "$%.2f", payment.netAmount)
        cell.accessoryType = .none

        if let userViewModel = userViewModels.first(where: { $0.userId == payment.pilotId }) {
            cell.textLabel?.text = userViewModel.username
            cell.detailTextLabel?.text = userViewModel.fullName
        }

        return cell
    }
}
