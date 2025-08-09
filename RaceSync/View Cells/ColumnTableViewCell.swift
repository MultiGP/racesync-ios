//
//  ColumnTableViewCell.swift
//  RaceSync
//
//  Created by Ignacio Romero Zurbuchen on 2025-08-08.
//  Copyright © 2025 MultiGP Inc. All rights reserved.
//

import UIKit
import SnapKit

class ColumnTableViewCell: UITableViewCell {

    // MARK: - Public Variables

    static var height: CGFloat {
        return Constants.height
    }

    lazy var columnLabel1: UILabel = {
        return genericLabel()
    }()

    lazy var columnLabel2: UILabel = {
        return genericLabel()
    }()

    // MARK: - Private Variables

    fileprivate func genericLabel() -> UILabel {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        label.textColor = Color.gray500
        label.textAlignment = .right
        return label
    }

    fileprivate enum Constants {
        static let padding: CGFloat = UniversalConstants.padding
        static let buttonSpacing: CGFloat = 60
        static let height: CGFloat = 76
    }

    // MARK: - Initialization

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        setupLayout()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Layout

    fileprivate func setupLayout() {
        let selectedBackgroundView = UIView()
        selectedBackgroundView.backgroundColor = Color.gray50
        self.selectedBackgroundView = selectedBackgroundView

        let backgroundView = UIView()
        backgroundView.backgroundColor = Color.white
        self.backgroundView = backgroundView

        textLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        textLabel?.textColor = Color.black
        detailTextLabel?.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        detailTextLabel?.textColor = Color.gray300
        accessoryType = .none

        addSubview(columnLabel2)
        columnLabel2.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-Constants.padding)
            $0.centerY.equalToSuperview()
        }

        addSubview(columnLabel1)
        columnLabel1.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-Constants.padding*8)
            $0.centerY.equalToSuperview()
        }
    }
}
