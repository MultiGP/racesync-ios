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
import SwiftValidators

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
        view.backgroundColor = Color.white
        view.alwaysBounceVertical = true
        view.showsHorizontalScrollIndicator = false
        view.contentInsetAdjustmentBehavior = .never
        view.delegate = self
        return view
    }()

    fileprivate lazy var htmlView: RichEditorView = {
        let view = RichEditorView()
        view.isEditable = false
        view.isScrollEnabled = false
        view.delegate = self
        return view
    }()

    fileprivate lazy var headerView: ProfileHeaderView = {
        let view = ProfileHeaderView()
        view.topLayoutInset = 0
        view.locationIconView.isHidden = true
        view.backgroundColor = .red
        return view
    }()

    fileprivate var htmlViewHeightConstraint: Constraint?

    fileprivate enum Constants {
        static let padding: CGFloat = UniversalConstants.padding
        static let cellHeight: CGFloat = UniversalConstants.cellHeight
        static let htmlpadding: CGFloat = 12
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
        populateContent()
        configureNavigationItems()

        let contentView = UIView()
        view.backgroundColor = Color.white

        let profileViewModel = ProfileViewModel(with: series)
        headerView.viewModel = profileViewModel
        let headerViewSize = headerView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)

        let button = headerView.locationButton
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        button.titleLabel?.numberOfLines = 2
        button.titleLabel?.textAlignment = .center
        button.tintColor = Color.gray200
        button.isUserInteractionEnabled = false

        contentView.addSubview(headerView)
        headerView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.size.equalTo(headerViewSize)
        }

        contentView.addSubview(htmlView)
        htmlView.snp.makeConstraints {
            $0.top.equalTo(headerView.snp.bottom)
            $0.leading.equalToSuperview().offset(Constants.padding)
            $0.trailing.equalToSuperview().offset(-Constants.padding)
            htmlViewHeightConstraint = $0.height.equalTo(0).constraint
            htmlViewHeightConstraint?.activate()
            $0.bottom.equalToSuperview()
        }

        scrollView.addSubview(contentView)
        contentView.snp.makeConstraints {
            $0.top.leading.trailing.bottom.equalToSuperview()
            $0.width.equalTo(scrollView.snp.width)
        }

        view.addSubview(scrollView)
        scrollView.snp.makeConstraints {
            $0.width.equalTo(UIScreen.main.bounds.width)
            $0.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }
    }

    fileprivate func configureNavigationItems() {
        title = "Details"
        tabBarItem = UITabBarItem(title: title, image: SystemImg.calendarCclock, selectedImage: nil)

        navigationItem.rightBarButtonItem = seriesController.navigationItems()
    }

    fileprivate func populateContent() {

        // Load the HTML on the next runloop
        DispatchQueue.main.async { [weak self] in
            guard let s = self else { return }
            s.configureHTML()
        }
    }

    fileprivate func configureHTML() {
        guard series.description.stripHTML().count > 0 else { return }

        let vSpacing = Constants.padding * 3/4

        let content = series.description.replaceHTMLColorTag(with: Color.black).stripHTMLFontTag().stripHTMLEdges()
        htmlView.html = "<div id=\"content\" style=\"color:\(Color.black.toHexString()); padding-top: \(vSpacing)px; padding-bottom: \(vSpacing)px;\">\(content)</div>"
        htmlView.isUserInteractionEnabled = true
    }
}

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

extension SeriesDetailViewController: RichEditorDelegate {

    func richEditor(_ editor: RichEditorView, heightDidChange height: Int) {
        var offset = CGFloat(height)
        offset += Constants.htmlpadding*2

        htmlViewHeightConstraint?.update(offset: offset)
    }

    func richEditor(_ editor: RichEditorView, shouldInteractWith url: URL) -> Bool {

        if let link = DeepLink.create(from: url), ApplicationControl.shared.canHandleDeepLink(link) {
            ApplicationControl.shared.handle(link)
        } else if Validator.isEmail().apply(url.absoluteString) {
            // leave the system handle emails
            UIApplication.shared.open(url)
        } else {
            // open url using in-app browser, else the url is open on the WKWebView
            WebViewController.open(url)
        }

        return false
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
