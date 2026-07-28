//
//  SegmentedTableViewHeaderView.swift
//  RaceSync
//
//  Created by Ignacio Romero Zurbuchen on 2019-11-21.
//  Copyright © 2019 MultiGP Inc. All rights reserved.
//

import UIKit
import SnapKit

class SegmentedTableViewHeaderView: UITableViewHeaderFooterView {

    static var identifier: String = "SegmentedTableViewHeaderView"

    static var headerHeight: CGFloat {
        return Constants.height
    }

    lazy var segmentedControl: UISegmentedControl = {
        let items = ["Item 1", "Item 2"] // pre-loading elements
        let segmentedControl = UISegmentedControl(items: items)
        segmentedControl.selectedSegmentIndex = 0
        return segmentedControl
    }()

    // MARK: - Private Variables

    fileprivate enum Constants {
        static let padding: CGFloat = UniversalConstants.padding
        static let height: CGFloat = 32 + padding * 2 // slightly higher than native height
    }

    // MARK: - Initialization

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        setupLayout()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Super Overrides

    override func didMoveToWindow() {
        super.didMoveToWindow()
        
        // Locks the view from changing modes automatically
        Appearance.applyUserInterfaceStyle(to: self)
    }

    // MARK: - Layout

    fileprivate func setupLayout() {
        backgroundView = UIView()
        backgroundView?.backgroundColor = Color.barBackground

        addSubview(segmentedControl)
        segmentedControl.snp.makeConstraints {
            $0.top.equalToSuperview().offset(Constants.padding)
            $0.leading.equalToSuperview().offset(Constants.padding)
            $0.trailing.equalToSuperview().offset(-Constants.padding)
            $0.bottom.equalTo(self.snp.bottom).offset(-Constants.padding)
        }

        addSeparatorLine(.bottom)
    }
}
