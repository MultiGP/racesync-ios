//
//  AvatarTableViewCell.swift
//  RaceSync
//
//  Created by Ignacio Romero Zurbuchen on 2019-12-10.
//  Copyright © 2019 MultiGP Inc. All rights reserved.
//

import UIKit
import SnapKit

class AvatarTableViewCell: UITableViewCell {

    // MARK: - Public Variables

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

    lazy var avatarImageView: AvatarImageView = {
        return AvatarImageView(withHeight: Constants.imageHeight)
    }()

    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        label.textColor = Color.black
        return label
    }()

    lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        label.textColor = Color.gray300
        return label
    }()

    lazy var rankView: RankView = {
        let view = RankView()
        view.isHidden = true
        return view
    }()

    lazy var textPill: TextPill = {
        let pill = TextPill(style: .badge)
        pill.isHidden = true
        return pill
    }()

    // MARK: - Private Variables

    fileprivate lazy var textStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        stackView.axis = .vertical
        stackView.distribution = .fillProportionally
        stackView.alignment = .leading
        stackView.spacing = 5
        return stackView
    }()

    fileprivate lazy var spinnerView: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(style: .medium)
        return view
    }()

    fileprivate var imageViewLeadingConstraint: Constraint?
    fileprivate var imageViewWidthConstraint: Constraint?
    fileprivate var rankLabelWidthConstraint: Constraint?
    fileprivate var rankLabelLeadingConstraint: Constraint?

    fileprivate enum Constants {
        static let padding: CGFloat = UniversalConstants.padding
        static let imageHeight: CGFloat = UniversalConstants.cellAvatarHeight
        static let buttonSpacing: CGFloat = 8
    }

    // MARK: - Initialization

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupLayout()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Layout

    open func setupLayout() {
        backgroundColor = Color.white

        let selectedBackgroundView = UIView()
        selectedBackgroundView.backgroundColor = Color.gray20
        self.selectedBackgroundView = selectedBackgroundView

        accessoryType = .disclosureIndicator

        contentView.addSubview(textPill)
        textPill.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-Constants.buttonSpacing)
            $0.centerY.equalToSuperview()
        }

        contentView.addSubview(rankView)
        rankView.snp.makeConstraints {
            $0.centerY.equalToSuperview()

            rankLabelWidthConstraint = $0.width.greaterThanOrEqualTo(Constants.imageHeight / 2).constraint
            rankLabelWidthConstraint?.activate()

            rankLabelLeadingConstraint = $0.leading.equalToSuperview().offset(Constants.padding).constraint
            rankLabelLeadingConstraint?.activate()
        }

        contentView.addSubview(avatarImageView)
        avatarImageView.snp.makeConstraints {
            $0.height.equalTo(Constants.imageHeight)
            $0.centerY.equalToSuperview()

            imageViewLeadingConstraint = $0.leading.equalTo(rankView.snp.trailing).offset(Constants.padding/2).constraint
            imageViewLeadingConstraint?.activate()

            imageViewWidthConstraint = $0.width.equalTo(Constants.imageHeight).constraint
            imageViewWidthConstraint?.activate()
        }

        contentView.addSubview(textStackView)
        textStackView.snp.makeConstraints {
            $0.leading.equalTo(avatarImageView.snp.trailing).offset(Constants.padding).priority(.high)
            $0.trailing.equalTo(textPill.snp.leading).offset(-Constants.padding)
            $0.centerY.equalToSuperview()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        imageViewWidthConstraint?.update(offset: avatarImageView.isHidden ? 0 : Constants.imageHeight)

        if rankView.isHidden {
            imageViewLeadingConstraint?.update(offset: 0)
            rankLabelWidthConstraint?.update(offset: 0)
            rankLabelLeadingConstraint?.update(offset: 0)
            rankLabelWidthConstraint?.deactivate()
        } else {
            imageViewLeadingConstraint?.update(offset: Constants.padding/2)
            rankLabelWidthConstraint?.activate()
            rankLabelLeadingConstraint?.update(offset: Constants.padding)
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        titleLabel.numberOfLines = 1
        titleLabel.text = nil
        subtitleLabel.text = nil
        textPill.text = nil
        accessoryView = nil
    }
}
