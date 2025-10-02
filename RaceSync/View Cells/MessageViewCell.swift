//
//  MessageViewCell.swift
//  RaceSync
//
//  Created by Ignacio Romero Zurbuchen on 2025-05-20.
//  Copyright © 2025 MultiGP Inc. All rights reserved.
//

import UIKit
import SnapKit

class MessageViewCell: UITableViewCell {

    // MARK: - Public Variables

    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        label.textColor = Color.gray500
        label.lineBreakMode = .byTruncatingTail
        label.numberOfLines = 1
        return label
    }()

    lazy var detailLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        label.textColor = Color.black
        label.lineBreakMode = .byTruncatingTail
        label.numberOfLines = 5
        return label
    }()

    lazy var timeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        label.textColor = Color.gray200
        label.textAlignment = .right
        label.numberOfLines = 1
        return label
    }()

    var isLoading: Bool = false {
        didSet {
            if isLoading {
                accessoryView = spinnerView
                spinnerView.startAnimating()
            } else {
                accessoryView = nil
                accessoryType = .disclosureIndicator
            }
        }
    }

    static var estimatedHeight: CGFloat {
        return Constants.cellHeight
    }

    // MARK: - Private Variables

    fileprivate lazy var spinnerView: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(style: .medium)
        view.hidesWhenStopped = true
        view.tintColor = Color.gray500
        return view
    }()

    fileprivate enum Constants {
        static let padding: CGFloat = UniversalConstants.padding
        static let margin: CGFloat = 12
        static let vPadding: CGFloat = 20
        static let cellHeight: CGFloat = 100
    }

    // MARK: - Initialization

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .value1, reuseIdentifier: reuseIdentifier)
        setupLayout()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Layout

    fileprivate func setupLayout() {
        let selectedBackgroundView = UIView()
        selectedBackgroundView.backgroundColor = Color.gray20
        self.selectedBackgroundView = selectedBackgroundView

        accessoryType = .disclosureIndicator

        addSubview(timeLabel)
        timeLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(Constants.vPadding)
            $0.trailing.equalToSuperview().offset(-Constants.padding*2)
        }

        addSubview(titleLabel)
        titleLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(Constants.vPadding)
            $0.leading.equalToSuperview().offset(Constants.padding*2)
            $0.trailing.equalToSuperview().offset(-Constants.padding*4)
        }

        addSubview(detailLabel)
        detailLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(Constants.margin/2)
            $0.leading.equalToSuperview().offset(Constants.padding*2)
            $0.trailing.equalToSuperview().offset(-Constants.padding*3)
            $0.bottom.equalToSuperview().offset(-Constants.margin*2)
        }
    }
}
