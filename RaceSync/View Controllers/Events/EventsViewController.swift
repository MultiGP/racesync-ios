//
//  EventsViewController.swift
//  RaceSync
//
//  Created by Ignacio Romero on 2026-04-26.
//  Copyright © 2026 MultiGP Inc. All rights reserved.
//

import Foundation
import RaceSyncAPI
import SnapKit

class EventsViewController: UIViewController {

    // MARK: - Public Variables

    lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.backgroundView = UIView()
        tableView.backgroundView?.backgroundColor = Color.clear
        tableView.backgroundColor = Color.gray50
        tableView.contentInsetAdjustmentBehavior = .always
//        tableView.dataSource = self
//        tableView.delegate = self
        tableView.register(cellType: SimpleTableViewCell.self)
        tableView.tableFooterView = UIView()
        tableView.refreshControl = self.refreshControl
        return tableView
    }()

    // MARK: - Private Variables

    fileprivate lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.backgroundColor = Color.gray50
        refreshControl.tintColor = Color.blue
        refreshControl.addTarget(self, action: #selector(didPullRefreshControl), for: .valueChanged)
        return refreshControl
    }()

    fileprivate enum Constants {
        static let padding: CGFloat = UniversalConstants.padding
        static let cellHeight: CGFloat = UniversalConstants.cellHeight
    }

    // MARK: - Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()

        setupLayout()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        hideNavigationShadow()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }

    // MARK: - Layout

    fileprivate func setupLayout() {
        
        configureNavigationItems()

        view.addSubview(tableView)
        tableView.snp.makeConstraints {
            $0.width.equalTo(UIScreen.main.bounds.width)
            $0.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }
    }

    fileprivate func configureNavigationItems() {
        title = "IO26"
        tabBarItem = UITabBarItem(title: title, image: SystemImg.globe, selectedImage: SystemImg.globeFill)
        tabBarItem.isEnabled = false
    }

    // MARK: - Actions

    @objc fileprivate func didPullRefreshControl() {
        //
    }

    // MARK: - Data Update

    
}
