//
//  AvatarTableViewCell.swift
//  RaceSync
//
//  Created by Ignacio Romero Zurbuchen on 2019-12-10.
//  Copyright © 2019 MultiGP Inc. All rights reserved.
//

import UIKit
import SnapKit

class SimpleTableViewCell: UITableViewCell {

    // MARK: - Public Variables

    var imageRatio: CGFloat = 1 {
        didSet {
            iconImageView.snp.updateConstraints { make in
                make.width.equalTo(Constants.imageHeight * imageRatio)
            }

            imageViewWidthConstraint?.update(offset: Constants.imageHeight * imageRatio)
        }
    }
    fileprivate var imageViewWidthConstraint: Constraint?

    lazy var iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.backgroundColor = Color.clear
        imageView.clipsToBounds = true
        return imageView
    }()

    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        label.textColor = Color.black
        return label
    }()

    lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        label.textColor = Color.gray300
        return label
    }()

    // MARK: - Private Variables

    fileprivate lazy var labelStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        stackView.axis = .vertical
        stackView.distribution = .fillProportionally
        stackView.alignment = .leading
        stackView.spacing = 2
        return stackView
    }()

    fileprivate enum Constants {
        static let padding: CGFloat = UniversalConstants.padding
        static let imageHeight: CGFloat = UniversalConstants.cellAvatarHeight
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

        let selectedBackgroundView = UIView()
        selectedBackgroundView.backgroundColor = Color.gray20
        self.selectedBackgroundView = selectedBackgroundView

        contentView.addSubview(iconImageView)
        iconImageView.snp.makeConstraints {
            $0.height.equalTo(Constants.imageHeight)
            $0.width.equalTo(Constants.imageHeight * imageRatio)
            $0.leading.equalToSuperview().offset(Constants.padding)
            $0.centerY.equalToSuperview()

//            imageViewWidthConstraint = $0.width.equalTo(Constants.imageHeight * imageRatio).constraint
//            imageViewWidthConstraint?.activate()
        }

        contentView.addSubview(labelStackView)
        labelStackView.snp.makeConstraints {
            $0.leading.equalTo(iconImageView.snp.trailing).offset(Constants.padding)
            $0.trailing.equalToSuperview().offset(-Constants.padding)
            $0.centerY.equalToSuperview()
        }
    }
}
