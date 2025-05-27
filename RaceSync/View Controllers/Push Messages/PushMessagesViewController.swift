//
//  PushMessagesViewController.swift
//  RaceSync
//
//  Created by Ignacio Romero Zurbuchen on 2025-05-20.
//  Copyright © 2025 MultiGP Inc. All rights reserved.
//

import UIKit
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
        return tableView
    }()

    fileprivate var messageViewModels = [PushMessageViewModel]()

    fileprivate var emptyStateNoMessages = EmptyStateViewModel(.noPushMessages)
    fileprivate var emptyStateNoPushEnabled = EmptyStateViewModel(.noPushEnabled)

    fileprivate enum Constants {
        static let padding: CGFloat = UniversalConstants.padding
        static let cellHeight: CGFloat = UniversalConstants.cellFormHeight
    }

    // MARK: - Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Messages"

        let closeBtn = UIBarButtonItem(image: ButtonImg.close, style: .done, target: self, action: #selector(didPressCloseButton))
        navigationItem.leftBarButtonItem = closeBtn

        let clearBtn = UIBarButtonItem(title: "Clear All", style: .done, target: self, action: #selector(didPressClearButton))
        navigationItem.rightBarButtonItem = clearBtn

        NotificationCenter.default.addObserver( self, selector: #selector(handleNewPushMessage(_:)), name: .newPushMessageReceived, object: nil)

        populateDataSource()
        setupLayout()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        tableView.reloadData()
        PushMessagesController.shared.clearNotificationsCount()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Layout

    fileprivate func populateDataSource() {

        let messages = PushMessagesController.shared.store.getAllMessages()
        messageViewModels = PushMessageViewModel.viewModels(with: messages)
        tableView.reloadData()
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

    fileprivate func setupLayout() {

        view.addSubview(tableView)
        tableView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(view.snp.bottom)
        }
    }

    // MARK: - Actions

    @objc private func handleNewPushMessage(_ notification: Notification)  {
        guard let newMessage = notification.object as? PushMessage else { return }

        let viewModel = PushMessageViewModel(with: newMessage)
        messageViewModels.insert(viewModel, at: 0)

        DispatchQueue.main.async {
            self.tableView.beginUpdates()
            self.tableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
            self.tableView.endUpdates()
        }
    }

    @objc func didPressCloseButton() {
        dismiss(animated: true)
    }

    @objc func didPressClearButton() {
        PushMessagesController.shared.clearAllNotificationMessages()
        populateDataSource()
    }

    @objc func didPressEnableNotificationsButton() {

        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

extension PushMessagesViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        let viewModel = messageViewModels[indexPath.row]

        if let raceId = viewModel.message.raceId {
            let vc = RaceTabBarController(with: raceId)
            navigationController?.pushViewController(vc, animated: true)
        }

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
        let cell = tableView.dequeueReusableCell(forIndexPath: indexPath) as MessageViewCell

        let viewModel = messageViewModels[indexPath.row]

        cell.titleLabel.text = viewModel.titleLabel
        cell.detailLabel.text = viewModel.detailLabel
        cell.timeLabel.text = viewModel.dateLabel

        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return MessageViewCell.height
    }
}

extension PushMessagesViewController: EmptyDataSetSource {

    func title(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {

        if PushMessagesController.shared.isRegisteredForNotifications() {
            return emptyStateNoMessages.title
        } else {
            return emptyStateNoPushEnabled.title
        }
    }

    func description(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {

        if PushMessagesController.shared.isRegisteredForNotifications() {
            return emptyStateNoMessages.description
        } else {
            return emptyStateNoPushEnabled.description
        }
    }

    func buttonTitle(forEmptyDataSet scrollView: UIScrollView, for state: UIControl.State) -> NSAttributedString? {

        if !PushMessagesController.shared.isRegisteredForNotifications() {
            return emptyStateNoPushEnabled.buttonTitle(state)
        }
        return nil
    }

    func backgroundColor(forEmptyDataSet scrollView: UIScrollView) -> UIColor? {
        return Color.white
    }
}

extension PushMessagesViewController: EmptyDataSetDelegate {

    func emptyDataSetShouldDisplay(_ scrollView: UIScrollView) -> Bool {
        return true
    }

    func emptyDataSetShouldAllowScroll(_ scrollView: UIScrollView) -> Bool {
        return true
    }

    func emptyDataSet(_ scrollView: UIScrollView, didTapButton button: UIButton) {

        if !PushMessagesController.shared.isRegisteredForNotifications() {
            didPressEnableNotificationsButton()
        }
    }
}
