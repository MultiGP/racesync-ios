//
//  RaceScheduleViewController..swift
//  RaceSync
//
//  Created by Ignacio Romero Zurbuchen on 2019-11-15.
//  Copyright © 2019 MultiGP Inc. All rights reserved.
//

import UIKit
import SnapKit
import RaceSyncAPI
@preconcurrency import WebKit

class RaceScheduleViewController: UIViewController {

    // MARK: - Public Variables

    var race: Race

    // MARK: - Private Variables

    fileprivate lazy var webView: WKWebView = {

        let script = """
            // hides specific UI elements
            var style = document.createElement('style');
            style.innerHTML = ".topright { display: none !important; } .topcenter { display: none !important; } .verticalviewbutton { display: none !important; }";
            document.head.appendChild(style);
        
            // hides header title while preserving the vertical space
            var headers = document.querySelectorAll("h2");
            headers.forEach(function(header) {
                if (header.textContent.trim().startsWith("Event:")) {
                    header.innerHTML = "&nbsp;";
                }
            });
        
            // presents the page to scroll when reloading
            history.scrollRestoration = 'manual';
        """

        let userScript = WKUserScript(source: script, injectionTime: .atDocumentEnd, forMainFrameOnly: true)

        let contentController = WKUserContentController()
        contentController.addUserScript(userScript)

        // Configure the WebView
        let config = WKWebViewConfiguration()
        config.userContentController = contentController

        let view = WKWebView(frame: .zero, configuration: config)
        view.navigationDelegate = self
        view.scrollView.alwaysBounceHorizontal = false
        view.scrollView.alwaysBounceVertical = false
        view.scrollView.showsHorizontalScrollIndicator = false
        view.scrollView.showsVerticalScrollIndicator = false
        return view
    }()

    fileprivate var reloadTimer: Timer?
    fileprivate let isWebPollEnabled: Bool = true

    fileprivate var canDisplayZippyQ: Bool {
        get { return race.isZippyQEnabled && !race.isFinalized }
    }

    fileprivate enum Constants {
        static let padding: CGFloat = UniversalConstants.padding
        static let cellHeight: CGFloat = UniversalConstants.cellHeight
    }

    // MARK: - Initialization

    init(with race: Race) {
        self.race = race
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        reloadTimer?.invalidate()
    }

    // MARK: - Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()

        if canDisplayZippyQ {
            setupLayout()
            initializeWebview()
        }

        configureNavigationItems()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }

    // MARK: - Layout

    fileprivate func setupLayout() {

        view.addSubview(webView)
        webView.snp.makeConstraints {
            $0.top.bottom.equalToSuperview()
            $0.leading.trailing.equalToSuperview()
        }
    }

    fileprivate func configureNavigationItems() {

        title = "Race Schedule"
        let itemTitle = "Schedule"
        tabBarItem = UITabBarItem(title: itemTitle, image: UIImage(systemName:"flag.checkered"), selectedImage: nil)
        tabBarItem.isEnabled = canDisplayZippyQ

        let rightBtnItem = UIBarButtonItem(image: UIImage(systemName:"safari"), style: .plain, target: self, action: #selector(openZippyQSchedule))
        navigationItem.rightBarButtonItem = rightBtnItem
        navigationItem.rightBarButtonItem?.isEnabled = canDisplayZippyQ
    }

    fileprivate func initializeWebview() {

        let zippyqUrl = MGPWeb.getUrl(for: .zippyqView, value: race.id)

        if let url = URL(string: zippyqUrl) {
            webView.load(URLRequest(url: url))

            // Start reload timer
            if isWebPollEnabled {
                reloadTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
                    self?.webView.reload()
                }
            }
        }
    }

    @objc fileprivate func openZippyQSchedule() {
        let zippyqUrl = MGPWeb.getUrl(for: .zippyqView, value: race.id)
        if let url = URL(string: zippyqUrl), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
}

extension RaceScheduleViewController: WKNavigationDelegate {

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        
    }
}
