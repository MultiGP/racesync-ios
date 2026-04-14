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

class RaceScheduleViewController: UIViewController, RaceTabbable {

    // MARK: - Public Variables

    var raceController: RaceController

    var race: Race {
        get { return raceController.race! }
    }

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
        view.scrollView.alwaysBounceHorizontal = false
        view.scrollView.alwaysBounceVertical = false
        view.scrollView.showsHorizontalScrollIndicator = false
        view.scrollView.showsVerticalScrollIndicator = false
        return view
    }()

    fileprivate var reloadTimer: Timer?
    fileprivate let isWebPollEnabled: Bool = true

    fileprivate enum Constants {
        static let padding: CGFloat = UniversalConstants.padding
        static let cellHeight: CGFloat = UniversalConstants.cellHeight
    }

    // MARK: - Initialization

    init(with controller: RaceController) {
        self.raceController = controller
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

        setupLayout()
        loadContent()
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
            $0.width.equalTo(UIScreen.main.bounds.width)
            $0.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }
    }

    fileprivate func configureNavigationItems() {
        title = "Schedule"
        tabBarItem = UITabBarItem(title: title, image: SystemImg.flagCheckered, selectedImage: nil)

        navigationItem.rightBarButtonItem = raceController.navigationItems(for: [.zippyQ, .share])
    }

    // MARK: - Data Update

    fileprivate func loadContent() {
        let zippyqUrl = MGPWeb.getUrl(for: .zippyqView, value: race.id)

        if let url = URL(string: zippyqUrl) {
            webView.load(URLRequest(url: url))

            if reloadTimer != nil {
                reloadTimer?.invalidate()
                reloadTimer = nil
            }

            // Start reload timer
            if isWebPollEnabled {
                reloadTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
                    self?.webView.reload()
                }
            }
        }
    }

    // RaceTabbable
    func reloadContent() {
        loadContent()
    }
}
