//
//  AppIconViewController.swift
//  RaceSync
//
//  Created by Ignacio Romero Zurbuchen on 2021-08-23.
//  Copyright © 2021 MultiGP Inc. All rights reserved.
//

import UIKit
import SnapKit

class AppIconViewController: UIViewController {

    // MARK: - Private Variables

    lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.tableFooterView = UIView()
        tableView.register(cellType: FormTableViewCell.self)

        let backgroundView = UIView()
        backgroundView.backgroundColor = Color.gray20
        tableView.backgroundView = backgroundView

        return tableView
    }()

    let appIconManager = AppIconManager()
    
    // MARK: - Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()

        setupLayout()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    // MARK: - Layout

    fileprivate func setupLayout() {
        view.addSubview(tableView)
        tableView.snp.makeConstraints {
            $0.top.leading.trailing.bottom.equalToSuperview()
        }
    }
}

extension AppIconViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let currentAppIcon = AppIconManager.current()
        guard let appIcon = AppIcon(rawValue: indexPath.row), appIcon != currentAppIcon else { return }

        AppIconManager.setIcon(appIcon) { (didSet) in
            tableView.reloadData()
        }
    }
}

extension AppIconViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return AppIcon.allCases.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return iconTableViewCell(for: indexPath)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UniversalConstants.cellHeight
    }

    func iconTableViewCell(for indexPath: IndexPath) -> FormTableViewCell {
        let cell = tableView.dequeueReusableCell(forIndexPath: indexPath) as FormTableViewCell
        guard let appIcon = AppIcon(rawValue: indexPath.row) else { return cell }

        cell.textLabel?.text = appIcon.title
        cell.imageView?.image = appIcon.preview?.rounded(with: 60 / 4)
        cell.imageView?.layer.shadowColor = Color.black.cgColor
        cell.imageView?.layer.shadowOffset = CGSize(width: 0, height: 2.0)
        cell.imageView?.layer.shadowOpacity = 0.2
        cell.imageView?.layer.shadowRadius = 3
        cell.accessoryType = .none

        if AppIconManager.current() == appIcon {
            let imageView = UIImageView(image: UIImage(named: "icn_cell_checkmark"))
            imageView.tintColor = Color.blue
            cell.accessoryView = imageView
        } else {
            cell.accessoryView = nil
        }

        return cell
    }
}
