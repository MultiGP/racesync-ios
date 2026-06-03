//
//  PushMessagesViewController.swift
//  RaceSync
//
//  Created by Ignacio Romero Zurbuchen on 2025-05-20.
//  Copyright © 2025 MultiGP Inc. All rights reserved.
//

import UIKit
import RaceSyncAPI
import SnapKit
import EmptyDataSet_Swift
import ShimmerSwift

class PushMessagesViewController: UIViewController {

    // MARK: - Private Variables

    fileprivate lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.tableFooterView = UIView()
        tableView.emptyDataSetSource = self
        tableView.emptyDataSetDelegate = self
        tableView.register(cellType: MessageViewCell.self)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = MessageViewCell.estimatedHeight
        return tableView
    }()

    fileprivate var message: PushMessage?
    fileprivate var messageViewModels = [PushMessageViewModel]()

    fileprivate var isLoading: Bool = false {
        didSet {
            tableView.reloadData()
        }
    }

    fileprivate let emptyStateNoMessages = EmptyStateViewModel(.noPushMessages)
    fileprivate let emptyStateNoPushAuthorized = EmptyStateViewModel(.noPushAuthorized)
    fileprivate let emptyStateNoPushEnabled = EmptyStateViewModel(.noPushEnabled)

    fileprivate enum Constants {
        static let padding: CGFloat = UniversalConstants.padding
        static let cellHeight: CGFloat = UniversalConstants.cellFormHeight
    }

    // MARK: - Lifecycle Methods

    init(with message: PushMessage? = nil) {
        self.message = message
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        NotificationCenter.default.addObserver(self, selector: #selector(handlePushMessageRegistration(_:)), name: .registeredForPushMessages, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleNewPushMessage(_:)), name: .newPushMessageReceived, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)

        setupLayout()
        loadContent()

        if let message = message {
            presentContent(from: message, animated: false)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        PushMessagesController.shared.isMessagesViewShowing = true
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        PushMessagesController.shared.isMessagesViewShowing = false
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Layout

    fileprivate func setupLayout() {

        configureNavigationItems()

        view.addSubview(tableView)
        tableView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(view.snp.bottom)
        }
    }

    fileprivate func configureNavigationItems() {
        title = "Messages"

        let leftBtnItem = UIBarButtonItem(image: ButtonImg.close, style: .plain, target: self, action: #selector(didPressCloseButton))
        navigationItem.leftBarButtonItem = leftBtnItem

        let rightBtnItem = UIBarButtonItem(title: "Clear", style: .plain, target: self, action: #selector(didPressClearButton))
        rightBtnItem.isEnabled = false
        navigationItem.rightBarButtonItem = rightBtnItem

        if #available(iOS 16.0, *) { rightBtnItem.isHidden = true }
    }
    
    fileprivate func updateClearButton() {
        let item = navigationItem.rightBarButtonItem

        if #available(iOS 16.0, *) {
            item?.isHidden = !PushMessagesController.shared.isPushNotificationsEnabled()
        }
        item?.isEnabled = messageViewModels.count > 0
    }

    // MARK: - Actions

    fileprivate func presentContent(from message: PushMessage, animated: Bool) {

        // TODO: Use enum instead of loose string ids
        if message.type == "zippyq_next_round" {
            guard !message.raceId.isEmpty else { return }
            let vc = RaceTabBarController(with: message.raceId, selectedTab: .schedule)
            navigationController?.pushViewController(vc, animated: animated)
        }
        else if message.type == "event_activity_scheduler" {
            guard !message.raceId.isEmpty else { return }
            let vc = RaceTabBarController(with: message.raceId, selectedTab: .details)
            navigationController?.pushViewController(vc, animated: animated)
        }
        else if message.type == "app_store_review" {
            let storeUrl = StringConstants.appstoreReviewUrl
            if let url = URL(string: storeUrl), UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
        }
    }

    @objc fileprivate func didPressClearButton() {

        ActionSheetUtil.presentDestructiveActionSheet(withTitle: "Clear all messages?", destructiveTitle: "Yes", completion: { (action) in
            PushMessagesController.shared.clearAllPushMessages()
            self.loadContent()
        }, cancel: nil)
    }

    @objc fileprivate func didPressCloseButton() {
        dismiss(animated: true)
    }

    @objc fileprivate func didPressRequestNotificationsButton() {
        isLoading = true
        PushMessagesController.shared.requestAuthorizationPushNotifications()
    }

    @objc fileprivate func didPressShowSettingsButton() {
        AppControl.shared.openAppSettings()
    }

    @objc fileprivate func appDidBecomeActive() {
        resetTableViewForPushStatus()
    }

    // MARK: - Data Update

    fileprivate func loadContent() {
        let messages = PushMessagesController.shared.store.getAllMessages()
        messageViewModels = PushMessageViewModel.viewModels(with: messages)

        updateClearButton()
        tableView.reloadData()
    }

    fileprivate func resetTableViewForPushStatus() {
        PushMessagesController.shared.refreshPushNotificationSettings { status in
            self.tableView.reloadData()
        }
    }

    @objc fileprivate func handlePushMessageRegistration(_ notification: Notification)  {
        guard let status = notification.object as? Bool else { return }

        if status == true {
            let title = "📲 Welcome to \(Bundle.main.applicationName) iOS \(Bundle.main.releaseVersionNumber)"
            let body = "Please take a moment to rate and review the app on the App Store. Thank you for your support!"
            let type = "app_store_review"
            PushMessagesController.shared.store.addEphemeralMessage(with: title, body: body, type: type, broadcast: true)
        } else {
            isLoading = false
        }
    }

    @objc fileprivate func handleNewPushMessage(_ notification: Notification)  {
        guard let newMessage = notification.object as? PushMessage else { return }

        let viewModel = PushMessageViewModel(with: newMessage)
        messageViewModels.insert(viewModel, at: 0)

        // messageViewModels may already have more messages, that haven't yet been displayed
        let indexPaths = messageViewModels.indices.map { IndexPath(row: $0, section: 0) }

        tableView.beginUpdates()
        tableView.insertRows(at: indexPaths, with: .top)
        tableView.endUpdates()

        updateClearButton()

        if isLoading {
            isLoading = false
        }
    }
}

extension PushMessagesViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let viewModel = messageViewModels[indexPath.row]
        presentContent(from: viewModel.message, animated: true)

        tableView.deselectRow(at: indexPath, animated: true)
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
        if editingStyle == .delete {

            let viewModel = messageViewModels[indexPath.row]

            // Remove from storage
            PushMessagesController.shared.store.remove(viewModel.message)

            messageViewModels.remove(at: indexPath.row)

            tableView.beginUpdates()
            tableView.deleteRows(at: [indexPath], with: .automatic)
            tableView.endUpdates()

            updateClearButton()
        }
    }

    func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        return "Delete"
    }
}

extension PushMessagesViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard PushMessagesController.shared.isPushNotificationsEnabled() else { return 0 }
        return messageViewModels.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let viewModel = messageViewModels[indexPath.row]

        let cell = tableView.dequeueReusableCell(forIndexPath: indexPath) as MessageViewCell
        cell.titleLabel.text = viewModel.titleLabel
        cell.detailLabel.text = viewModel.detailLabel
        cell.timeLabel.text = viewModel.dateLabel
        return cell
    }
}

extension PushMessagesViewController: EmptyDataSetSource {

    func title(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        guard !isLoading else { return nil }

        let controller = PushMessagesController.shared
        if !controller.isPushNotificationsEnabled() {
            let emptyState = (controller.authorizationStatus == .notDetermined || controller.authorizationStatus == .authorized)
                ? emptyStateNoPushAuthorized
                : emptyStateNoPushEnabled
            return emptyState.title
        } else {
            return emptyStateNoMessages.title
        }
    }

    func description(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        guard !isLoading else { return nil }

        let controller = PushMessagesController.shared
        if !controller.isPushNotificationsEnabled() {
            let emptyState = (controller.authorizationStatus == .notDetermined || controller.authorizationStatus == .authorized)
                ? emptyStateNoPushAuthorized
                : emptyStateNoPushEnabled
            return emptyState.description
        } else {
            return emptyStateNoMessages.description
        }
    }

    func buttonTitle(forEmptyDataSet scrollView: UIScrollView, for state: UIControl.State) -> NSAttributedString? {
        guard !isLoading else { return nil }

        let controller = PushMessagesController.shared
        if !controller.isPushNotificationsEnabled() {
            let emptyState = (controller.authorizationStatus == .notDetermined || controller.authorizationStatus == .authorized)
                ? emptyStateNoPushAuthorized
                : emptyStateNoPushEnabled
            return emptyState.buttonTitle(state)
        }
        return nil
    }

    func customView(forEmptyDataSet scrollView: UIScrollView) -> UIView? {
        guard isLoading else { return nil }

        let view = UIActivityIndicatorView(style: .large)
        view.color = Color.gray300
        view.startAnimating()
        return view
    }

    func backgroundColor(forEmptyDataSet scrollView: UIScrollView) -> UIColor? {
        return Color.white
    }
}

extension PushMessagesViewController: EmptyDataSetDelegate {

    func verticalOffset(forEmptyDataSet scrollView: UIScrollView) -> CGFloat {
        return -(navigationController?.navigationBar.frame.height ?? 0)
    }

    func emptyDataSetShouldDisplay(_ scrollView: UIScrollView) -> Bool {
        return true
    }

    func emptyDataSetShouldAllowScroll(_ scrollView: UIScrollView) -> Bool {
        return (!isLoading)
    }

    func emptyDataSet(_ scrollView: UIScrollView, didTapButton button: UIButton) {

        let controller = PushMessagesController.shared
        if !controller.isPushNotificationsEnabled() {
            if (controller.authorizationStatus == .notDetermined || controller.authorizationStatus == .authorized) {
                didPressRequestNotificationsButton()
            } else {
                didPressShowSettingsButton()
            }
        }
    }
}
