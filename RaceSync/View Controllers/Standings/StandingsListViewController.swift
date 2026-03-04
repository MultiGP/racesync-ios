//
//  StandingsListViewController.swift
//  RaceSync
//
//  Created by Ignacio Romero Zurbuchen on 2025-12-29.
//  Copyright © 2025 MultiGP Inc. All rights reserved.
//

import UIKit
import SnapKit
import RaceSyncAPI

class StandingsListViewController: UIViewController {

    // MARK: - Private Variables

    fileprivate lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.register(cellType: SimpleTableViewCell.self)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.tableFooterView = UIView()

        let backgroundView = UIView()
        backgroundView.backgroundColor = Color.gray20
        tableView.backgroundView = backgroundView

        return tableView
    }()

    fileprivate var exception: StandingSeason?

    fileprivate enum Constants {
        static let padding: CGFloat = UniversalConstants.padding
        static let cellHeight: CGFloat = UniversalConstants.cellHeight
    }

    // MARK: - Initialization

    init(with exception: StandingSeason? = nil) {
        self.exception = exception
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

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
            $0.top.bottom.leading.trailing.equalToSuperview()
        }
    }

    // MARK: - Data

    fileprivate var sections: [Section] {
        get {
            if let exception = exception {
                return Section.allCases.filter { $0 != exception }
            } else {
                return Section.allCases
            }
        }
    }
}

extension StandingsListViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let section = sections[indexPath.row]
        let vc = StandingsViewController(with: section)
        vc.title = section.title

        navigationController?.pushViewController(vc, animated: true)
    }
}

extension StandingsListViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(forIndexPath: indexPath) as SimpleTableViewCell

        let section = sections[indexPath.row]
        cell.titleLabel.text = section.shortTitle
        cell.subtitleLabel.text = "\(section.pilotCount) Pilots"
        cell.accessoryType = .disclosureIndicator

        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return Constants.cellHeight
    }
}

fileprivate typealias Section = StandingSeason

fileprivate extension Section {

    var title: String {
        return "\(year) MultiGP Global Qualifier"
    }

    var shortTitle: String {
        return "MultiGP GQ \(year)"
    }

    var year: String {
        self.rawValue
    }

    var pilotCount: String {
        switch self {
        case .y2025:    return "1113"
        case .y2024:    return "932"
        case .y2023:    return "824"
        case .y2022:    return "712"
        case .y2021:    return "685"
        case .y2020:    return "604"
        case .y2019:    return "1011"
        }
    }
}
