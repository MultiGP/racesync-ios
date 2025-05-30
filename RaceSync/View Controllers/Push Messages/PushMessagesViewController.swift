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

    fileprivate var emptyStateNoMessages = EmptyStateViewModel(.noPushMessages)
    fileprivate var emptyStateNoPushAuthorized = EmptyStateViewModel(.noPushAuthorized)
    fileprivate var emptyStateNoPushEnabled = EmptyStateViewModel(.noPushEnabled)

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

        title = "Messages"

        let closeBtn = UIBarButtonItem(image: ButtonImg.close, style: .done, target: self, action: #selector(didPressCloseButton))
        navigationItem.leftBarButtonItem = closeBtn

        let clearBtn = UIBarButtonItem(title: "Clear All", style: .done, target: self, action: #selector(didPressClearButton))
        clearBtn.isEnabled = false
        if #available(iOS 16.0, *) { clearBtn.isHidden = true }
        navigationItem.rightBarButtonItem = clearBtn

        NotificationCenter.default.addObserver(self, selector: #selector(handlePushMessageRegistration(_:)), name: .registeredForPushMessages, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleNewPushMessage(_:)), name: .newPushMessageReceived, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)

        setupLayout()
        populateDataSource()

        if let message = message {
            presentContent(from: message, animated: false)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        PushMessagesController.shared.clearPushMessagesCount()
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

        view.addSubview(tableView)
        tableView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(view.snp.bottom)
        }
    }

    fileprivate func populateDataSource() {

        let messages = PushMessagesController.shared.store.getAllMessages()
        messageViewModels = PushMessageViewModel.viewModels(with: messages)

        updateClearButton()
        tableView.reloadData()
    }

    fileprivate func updateClearButton() {
        let item = navigationItem.rightBarButtonItem

        if #available(iOS 16.0, *) {
            item?.isHidden = !PushMessagesController.shared.isPushNotificationsEnabled()
        }
        item?.isEnabled = messageViewModels.count > 0
    }

    fileprivate func populateDummySource() {

        //        messages += [
        //            PushMessage(title: "📣 Round 28 is up next", detail: "Get ready to race on round 28. Your channel is R1 LHCP.", timestamp: 1747793038),
        //            PushMessage(title: "📣 Round 17 is up next", detail: "Get ready to race on round 17. Your channel is R5 LHCP.", timestamp: 1747790038),
        //            PushMessage(title: "📣 Round 7 is up next", detail: "Get ready to race on round 7. Your channel is R2 RHCP.", timestamp: 1747779532),
        //            PushMessage(title: "📣 Round 2 is up next", detail: "Get ready to race on round 2. Your channel is R1 LHCP.", timestamp: 1747778078),
        //            PushMessage(title: "📌 NERDs published a new race!", detail: "Save the date! July 22nd NERDs will host '2025 MultiGP Summer Global Qualifier'.", timestamp: 1747774078),
        //            PushMessage(title: "💸 Payment received!", detail: "HeadsupFPV paid $23.00 USD for '2025 MultiGP Spring GQ - Last Chance'. 6 pilots have paid so far.", timestamp: 1747772048),
        //            PushMessage(title: "✅ HeadsupFPV joing your race", detail: "HeadsupFPV joined '2025 MultiGP Spring GQ - Last Chance'. 12 pilots have joined so far!", timestamp: 1747773038)
        //        ]
        //
        //        messageViewModels = PushMessageViewModel.viewModels(with: messages)
        //        tableView.reloadData()
    }

    // MARK: - Actions

    fileprivate func presentContent(from message: PushMessage, animated: Bool) {

        if message.type == "zippyq_next_round", !message.raceId.isEmpty {
            let vc = RaceTabBarController(with: message.raceId) // TODO: Select schedule tab
            navigationController?.pushViewController(vc, animated: animated)
        }
    }

    @objc fileprivate func handlePushMessageRegistration(_ notification: Notification)  {
        updateClearButton()
        tableView.reloadData()
    }

    @objc fileprivate func handleNewPushMessage(_ notification: Notification)  {
        guard let newMessage = notification.object as? PushMessage else { return }

        let viewModel = PushMessageViewModel(with: newMessage)
        messageViewModels.insert(viewModel, at: 0)

        tableView.beginUpdates()
        tableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
        tableView.endUpdates()

        updateClearButton()
    }

    @objc fileprivate func appDidBecomeActive() {
        tableView.reloadData()
    }

    @objc fileprivate func didPressCloseButton() {
        dismiss(animated: true)
    }

    @objc fileprivate func didPressClearButton() {
        PushMessagesController.shared.clearAllPushMessages()
        populateDataSource()
    }

    @objc fileprivate func didPressAllowNotificationsButton() {
        PushMessagesController.shared.requestAuthorizationPushNotifications()
    }

    @objc fileprivate func didPressShowSettingsButton() {
        ApplicationControl.shared.openAppSettings()
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

//    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
//        return UITableView.automaticDimension
//    }
}

extension PushMessagesViewController: EmptyDataSetSource {

    func title(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {

        if !PushMessagesController.shared.isPushNotificationsEnabled() {
            let emptyState = !PushMessagesController.shared.isAllowingNotifications()
                ? emptyStateNoPushAuthorized
                : emptyStateNoPushEnabled
            return emptyState.title
        } else {
            return emptyStateNoMessages.title
        }
    }

    func description(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {

        if !PushMessagesController.shared.isPushNotificationsEnabled() {
            let emptyState = !PushMessagesController.shared.isAllowingNotifications()
                ? emptyStateNoPushAuthorized
                : emptyStateNoPushEnabled
            return emptyState.description
        } else {
            return emptyStateNoMessages.description
        }
    }

    func buttonTitle(forEmptyDataSet scrollView: UIScrollView, for state: UIControl.State) -> NSAttributedString? {

        if !PushMessagesController.shared.isPushNotificationsEnabled() {
            let emptyState = !PushMessagesController.shared.isAllowingNotifications()
                ? emptyStateNoPushAuthorized
                : emptyStateNoPushEnabled
            return emptyState.buttonTitle(state)
        }
        return nil
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
        return true
    }

    func emptyDataSet(_ scrollView: UIScrollView, didTapButton button: UIButton) {

        if !PushMessagesController.shared.isPushNotificationsEnabled() {
            if !PushMessagesController.shared.isAllowingNotifications() {
                didPressAllowNotificationsButton()
            } else {
                didPressShowSettingsButton()
            }
        }
    }
}
