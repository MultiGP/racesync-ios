//
//  RacePaymentViewController.swift
//  RaceSync
//
//  Created by Ignacio Romero Zurbuchen on 2025-08-07.
//  Copyright © 2025 MultiGP Inc. All rights reserved.
//

import UIKit
import SnapKit
import RaceSyncAPI

class RacePaymentViewController: UIViewController {

    // MARK: - Public Variables

    var race: Race

    // MARK: - Private Variables

    fileprivate var raceApi = RaceApi()

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
        
    }

    // MARK: - Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()

        setupLayout()
        configureNavigationItems()
        populateData()
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

    }

    fileprivate func configureNavigationItems() {

        title = "Pilot Payments"
        tabBarItem = UITabBarItem(title: "Payments", image: SystemImg.banknote, selectedImage: SystemImg.banknoteFill)
        tabBarItem.isEnabled = true
    }

    // MARK: - Content

    fileprivate func populateData() {

        raceApi.getRacePayments(with: race.id) { payments, error in
            
        }
    }
}
