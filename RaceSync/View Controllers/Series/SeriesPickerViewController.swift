//
//  SeriesPickerViewController.swift
//  RaceSync
//
//  Created by Ignacio Romero Zurbuchen on 2026-04-12.
//  Copyright © 2026 MultiGP Inc. All rights reserved.
//

import RaceSyncAPI
import EmptyDataSet_Swift
import SnapKit

/**
 Generic display of pre-loaded series.
 */
class SeriesPickerViewController: UIViewController {

    // MARK: - Public Variables

    lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(cellType: SimpleTableViewCell.self)
//        tableView.emptyDataSetSource = self
        tableView.tableFooterView = UIView()
        return tableView
    }()

    // MARK: - Private Variables

    fileprivate lazy var rightBarButtonItem: UIBarButtonItem = {
        let item = UIBarButtonItem(title: "Join", style: .plain, target: self, action: #selector(didPressJoinButton))
        item.isEnabled = false
        return item
    }()

    fileprivate lazy var leftBarButtonItem: UIBarButtonItem = {
        let item = UIBarButtonItem(image: ButtonImg.close, style: .plain, target: self, action: #selector(didPressCloseButton))
        item.isEnabled = true
        return item
    }()

    fileprivate lazy var activityIndicatorView: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(style: .medium)
        view.hidesWhenStopped = true
        return view
    }()

    fileprivate var isLoading: Bool = false {
        didSet {
            if isLoading {
                tableView.isUserInteractionEnabled = false
                navigationItem.rightBarButtonItem = UIBarButtonItem(customView: activityIndicatorView)
                activityIndicatorView.startAnimating()
            }
            else {
                tableView.isUserInteractionEnabled = true
                navigationItem.rightBarButtonItem = rightBarButtonItem
                activityIndicatorView.stopAnimating()
            }
        }
    }

    fileprivate var seriesList: [SeriesViewModel]
    fileprivate let seriesApi = SeriesApi()

    fileprivate var raceId: ObjectId
    fileprivate var selectedSeriesId: ObjectId?

    fileprivate enum Constants {
        static let padding: CGFloat = UniversalConstants.padding
        static let cellHeight: CGFloat = 100
    }

    // MARK: - Initialization

    init(_ seriesViewModel: [SeriesViewModel], raceId: ObjectId) {
        self.seriesList = seriesViewModel
        self.raceId = raceId
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
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

    deinit {
        //
    }

    // MARK: - Layout

    fileprivate func setupLayout() {

        configureNavigationItems()

        view.addSubview(tableView)
        tableView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }

    fileprivate func configureNavigationItems() {
        title = "Pick a Series"
        navigationItem.rightBarButtonItem = rightBarButtonItem
        navigationItem.leftBarButtonItem = leftBarButtonItem
    }

    // MARK: - Actions

    fileprivate func joinSeries(_ series: Series) {

        isLoading = true

        seriesApi.join(series: series.id, with: raceId) { [weak self] status, error in
            if status {
                let message = "Joined series \"\(series.name)\" and waiting for approval."
                AlertUtil.presentAlertMessage(message, title: "Joined Series", cancelTitle: "OK", delay: 0.5)
                self?.dismiss(animated: true)
            } else if let error = error {
                AlertUtil.presentAlertMessage("\(error.localizedDescription)", title: "Error", delay: 0.5)
            } else {
                AlertUtil.presentAlertMessage("Couldn't join this series. Please try again later.", title: "Error", delay: 0.5)
            }
            self?.isLoading = false
        }
    }

    @objc fileprivate func didPressJoinButton() {
        guard let seriesId = selectedSeriesId else { return }
        guard let viewModel = seriesList.first(where: { $0.series.id == seriesId }) else { return }

        let title = "Joining \(viewModel.titleLabel)"
        let message = "The administrator will be notified of this request. Once approved, this will appear in the series."

        ActionSheetUtil.presentActionSheet(
            withTitle: title, message: message, buttonTitle: "Join", completion: { [weak self] _ in
                self?.joinSeries(viewModel.series)
        })
    }

    @objc fileprivate func didPressCloseButton() {
        dismiss(animated: true)
    }
}

extension SeriesPickerViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        let viewModel = seriesList[indexPath.row]

        if let seriesId = selectedSeriesId, seriesId == viewModel.series.id {
            selectedSeriesId = nil
        } else {
            selectedSeriesId = viewModel.series.id
        }

        navigationItem.rightBarButtonItem?.isEnabled = (selectedSeriesId != nil)

        tableView.reloadData()
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return Constants.cellHeight
    }
}

extension SeriesPickerViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return seriesList.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(forIndexPath: indexPath) as SimpleTableViewCell
        let viewModel = seriesList[indexPath.row]
        SimpleTableViewCell.configure(cell, with: viewModel)

        if let seriesId = selectedSeriesId, seriesId == viewModel.series.id {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }

        cell.selectionStyle = .none

        return cell
    }
}
