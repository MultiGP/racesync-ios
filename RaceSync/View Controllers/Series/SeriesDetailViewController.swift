//
//  SeriesDetailViewController.swift
//  RaceSync
//
//  Created by Ignacio Romero Zurbuchen on 2025-10-01.
//  Copyright © 2025 MultiGP Inc. All rights reserved.
//

import UIKit
import SnapKit
import RaceSyncAPI

class SeriesDetailViewController: UIViewController {

    // MARK: - Public Variables

    var seriesController: SeriesController

    var series: Series {
        get { return seriesController.series! }
    }

    var seriesApi: SeriesApi {
        get { return seriesController.seriesApi }
    }

    // MARK: - Private Variables

    fileprivate lazy var scrollView: UIScrollView = {
        let view = UIScrollView()
        view.showsVerticalScrollIndicator = false
        view.backgroundColor = Color.white
        view.isScrollEnabled = true
        view.alwaysBounceVertical = true
        view.delegate = self
        return view
    }()

    fileprivate let headerView = ProfileHeaderView()

    fileprivate enum Constants {
        static let padding: CGFloat = UniversalConstants.padding
        static let cellHeight: CGFloat = UniversalConstants.cellHeight
    }

    // MARK: - Initialization

    init(with controller: SeriesController) {
        self.seriesController = controller
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

        configureNavigationItems()
    }

    // MARK: - Layout

    fileprivate func setupLayout() {

        configureNavigationItems()

        view.addSubview(scrollView)
        scrollView.snp.makeConstraints {
            $0.top.leading.trailing.bottom.equalToSuperview()
        }

        let profileViewModel = ProfileViewModel(with: series)
        headerView.viewModel = profileViewModel
        let headerViewSize = headerView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)

        scrollView.addSubview(headerView)
        headerView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.size.equalTo(headerViewSize)
        }

        scrollView.contentSize = view.bounds.size
    }

    fileprivate func configureNavigationItems() {
        title = "Details"
        tabBarItem = UITabBarItem(title: title, image: SystemImg.calendarCclock, selectedImage: nil)

        navigationItem.rightBarButtonItem = seriesController.navigationItems()
    }
}

//extension SeriesDetailViewController: UITableViewDelegate {
//
//    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        tableView.deselectRow(at: indexPath, animated: true)
//    }
//}
//
//extension SeriesDetailViewController: UITableViewDataSource {
//
//    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        return 10
//    }
//
//    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        return UITableViewCell()
//    }
//
//    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
//        return Constants.cellHeight
//    }
//}

extension SeriesDetailViewController: UIScrollViewDelegate {

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        stretchHeaderView(with: scrollView.contentOffset)
    }
}

extension SeriesDetailViewController: ScrollToTop {

    func scrollToTop() {
        scrollView.setContentOffset(.zero, animated: true)
    }
}

// MARK: - HeaderStretchable

extension SeriesDetailViewController: HeaderStretchable {

    var targetHeaderView: StretchableView {
        return headerView.backgroundView
    }

    var targetHeaderViewSize: CGSize {
        return headerView.backgroundViewSize
    }

    var topLayoutInset: CGFloat {
        return 0
    }

    var anchoredViews: [UIView]? {
        return nil
    }
}
