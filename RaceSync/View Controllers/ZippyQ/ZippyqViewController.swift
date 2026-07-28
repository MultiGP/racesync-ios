//
//  ZippyqViewController.swift
//  RaceSync
//
//  Created by Ignacio Romero on 2026-07-27.
//  Copyright © 2026 MultiGP Inc. All rights reserved.
//

import UIKit
import SnapKit
import RaceSyncAPI

class ZippyqViewController: UIViewController, RaceTabbable {
    
    // MARK: - Public Variables
    
    var raceController: RaceController
    
    var race: Race {
        get { return raceController.race! }
    }
    
    // MARK: - Private Variables
    
    fileprivate let zippyqAPI = ZippyqApi()
    fileprivate var revisionHash: ZippyqRevisionHash?
    
    fileprivate let refreshInterval: TimeInterval = 10.0
    fileprivate var refreshTimer: Timer?
    fileprivate let isPollEnabled: Bool = true
    
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
        refreshTimer?.invalidate()
    }
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupLayout()
        configureNavigationItems()
        loadContent()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if revisionHash == nil {
            loadContent()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        startPolling()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        stopPolling()
    }
    
    // MARK: - Layout
    
    fileprivate func setupLayout() {
        
        
    }
    
    fileprivate func configureNavigationItems() {
        title = "ZippyQ"
        tabBarItem = UITabBarItem(title: title, image: SystemImg.bulletList, selectedImage: SystemImg.bulletListFill)
        
        navigationItem.rightBarButtonItems = raceController.navigationItems()
    }
    
    // MARK: - Data Update
    
    fileprivate func loadRevision() {
        
        zippyqAPI.getRevision(for: race.id, revision: revisionHash) { [weak self] hash, error in
            if let error {
                // Handle error
            } else {
                self?.loadContent(with: hash?.value)
            }
        }
    }
    
    fileprivate func loadContent(with hash: ZippyqRevisionHash? = nil) {
        
        if let hash = hash, hash == revisionHash {
            Clog.log("NO need to fetch ZippyQ content")
            return // no need to reload
        }
        
        revisionHash = hash // saving for later use
        Clog.log("Fetching ZippyQ content!")
    }
    
    fileprivate func startPolling() {
        guard isPollEnabled, refreshTimer == nil else { return }

        refreshTimer = Timer.scheduledTimer(withTimeInterval: refreshInterval, repeats: true) { [weak self] _ in
            self?.loadRevision()
        }
    }

    fileprivate func stopPolling() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }

    // RaceTabbable
    func reloadContent() {
        loadContent()
    }
}
