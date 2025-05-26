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

class PushMessagesViewController: UIViewController, Shimmable {

    // MARK: - Private Variables

    lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.tableFooterView = UIView()
        tableView.emptyDataSetSource = self
        tableView.emptyDataSetDelegate = self
        tableView.register(cellType: MessageViewCell.self)
        return tableView
    }()

    var shimmeringView: ShimmeringView = defaultShimmeringView()

    fileprivate var messages = [PushMessage]()
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

        title = "Notifications"

        let closeBtn = UIBarButtonItem(image: ButtonImg.close, style: .done, target: self, action: #selector(didPressCloseButton))
        navigationItem.leftBarButtonItem = closeBtn

        let clearBtn = UIBarButtonItem(title: "Clear", style: .done, target: self, action: #selector(didPressClearButton))
        navigationItem.rightBarButtonItem = clearBtn

        populateDataSource()
        setupLayout()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        tableView.reloadData()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    // MARK: - Layout

    fileprivate func populateDataSource() {

        isLoadingList(true)

        PushNotificationController.shared.getNotificationMessages { [weak self] messages in
            DispatchQueue.main.async {
                self?.messageViewModels = PushMessageViewModel.viewModels(with: messages)
                self?.isLoadingList(false)
                self?.tableView.reloadData()
            }
        }
    }

    fileprivate func populateDummySource() {

        messages += [
            PushMessage(apnsId: nil, title: "📣 Round 28 is up next", detail: "Get ready to race on round 28. Your channel is R1 LHCP.", timestamp: 1747793038),
            PushMessage(apnsId: nil, title: "📣 Round 17 is up next", detail: "Get ready to race on round 17. Your channel is R5 LHCP.", timestamp: 1747790038),
            PushMessage(apnsId: nil, title: "📣 Round 7 is up next", detail: "Get ready to race on round 7. Your channel is R2 RHCP.", timestamp: 1747779532),
            PushMessage(apnsId: nil, title: "📣 Round 2 is up next", detail: "Get ready to race on round 2. Your channel is R1 LHCP.", timestamp: 1747778078),
            PushMessage(apnsId: nil, title: "📌 NERDs published a new race!", detail: "Save the date! July 22nd NERDs will host '2025 MultiGP Summer Global Qualifier'.", timestamp: 1747774078),
            PushMessage(apnsId: nil, title: "💸 Payment received!", detail: "HeadsupFPV paid $23.00 USD for '2025 MultiGP Spring GQ - Last Chance'. 6 pilots have paid so far.", timestamp: 1747772048),
            PushMessage(apnsId: nil, title: "✅ HeadsupFPV joing your race", detail: "HeadsupFPV joined '2025 MultiGP Spring GQ - Last Chance'. 12 pilots have joined so far!", timestamp: 1747773038)
        ]

        messageViewModels = PushMessageViewModel.viewModels(with: messages)
        tableView.reloadData()
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

    @objc func didPressCloseButton() {
        dismiss(animated: true)
    }

    @objc func didPressClearButton() {
        PushNotificationController.shared.clearAllNotificationMessages()
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
        tableView.deselectRow(at: indexPath, animated: true)
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

        if PushNotificationController.shared.isRegisteredForNotifications() {
            return emptyStateNoMessages.title
        } else {
            return emptyStateNoPushEnabled.title
        }
    }

    func description(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {

        if PushNotificationController.shared.isRegisteredForNotifications() {
            return emptyStateNoMessages.description
        } else {
            return emptyStateNoPushEnabled.description
        }
    }

    func buttonTitle(forEmptyDataSet scrollView: UIScrollView, for state: UIControl.State) -> NSAttributedString? {

        if !PushNotificationController.shared.isRegisteredForNotifications() {
            return emptyStateNoPushEnabled.buttonTitle(state)
        }
        return nil
    }

    func backgroundColor(forEmptyDataSet scrollView: UIScrollView) -> UIColor? {
        return Color.white
    }
}

extension PushMessagesViewController: EmptyDataSetDelegate {

    func emptyDataSetShouldAllowScroll(_ scrollView: UIScrollView) -> Bool {
        return true
    }

    func emptyDataSet(_ scrollView: UIScrollView, didTapButton button: UIButton) {

        if !PushNotificationController.shared.isRegisteredForNotifications() {
            didPressEnableNotificationsButton()
        }
    }
}
