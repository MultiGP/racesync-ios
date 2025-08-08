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

    lazy var columnLabel1: UILabel = {
        return genericLabel()
    }()

    lazy var columnLabel2: UILabel = {
        return genericLabel()
    }()

    // MARK: - Private Variables

    fileprivate lazy var stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [columnLabel1, columnLabel2])
        stackView.axis = .horizontal
        stackView.distribution = .fillProportionally
        stackView.alignment = .center
        stackView.spacing = Constants.buttonSpacing
        return stackView
    }()

    fileprivate func genericLabel() -> UILabel {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        label.textColor = Color.gray200
        label.textAlignment = .right
        return label
    }

    fileprivate enum Constants {
        static let padding: CGFloat = UniversalConstants.padding
        static let buttonSpacing: CGFloat = 60
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

        accessoryType = .none

        addSubview(stackView)
        stackView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(Constants.padding)
            $0.trailing.equalToSuperview().offset(-Constants.padding)
        }
    }
}
