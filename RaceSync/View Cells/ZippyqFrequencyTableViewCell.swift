//
//  ZippyqFrequencyTableViewCell.swift
//  RaceSync
//
//  Created by Ignacio Romero on 2026-07-29.
//  Copyright © 2026 MultiGP Inc. All rights reserved.
//

import UIKit
import SnapKit
import AlamofireImage

class ZippyqFrequencyTableViewCell: UITableViewCell {

    // MARK: - Public Variables

    lazy var frequencyIndicatorView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = Constants.indicatorWidth / 2
        view.layer.masksToBounds = true
        return view
    }()

    lazy var channelLabel: UILabel = {
        let label = UILabel()
        if #available(iOS 16.0, *) {
            label.font = UIFont.systemFont(ofSize: 22, weight: .medium, width: .condensed)
        } else {
            label.font = UIFont.systemFont(ofSize: 20, weight: .medium)
        }
        label.textColor = Color.blue
        label.textAlignment = .center
        return label
    }()

    lazy var avatarImageView: AvatarImageView = {
        return AvatarImageView(withHeight: Constants.avatarHeight, showShadow: false)
    }()

    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        label.textColor = Color.black
        return label
    }()

    lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.textColor = Color.gray300
        return label
    }()

    lazy var resultLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.monospacedDigitSystemFont(ofSize: 15, weight: .regular)
        label.textColor = Color.blue
        label.textAlignment = .right
        return label
    }()

    lazy var actionButton: FrequencyActionButton = {
        return FrequencyActionButton()
    }()

    // MARK: - Private Variables

    fileprivate lazy var separatorView: UIView = {
        let view = UIView()
        view.backgroundColor = Color.gray100
        return view
    }()

    fileprivate lazy var textStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        stackView.axis = .vertical
        stackView.alignment = .leading
        stackView.spacing = 3
        return stackView
    }()

    fileprivate enum Constants {
        static let padding: CGFloat = UniversalConstants.padding
        static let indicatorWidth: CGFloat = 6
        static let indicatorHeight: CGFloat = 36
        static let channelWidth: CGFloat = 46
        static let avatarHeight: CGFloat = 36
        static let spacing: CGFloat = 12
        static let separatorHeight: CGFloat = 0.5
        static let currentUserBackgroundColor = Color.dynamic(
            light: UIColor(hex: "f8f7fc"), dark: UIColor(hex: "263238")
        )
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

    fileprivate func setupLayout() {
        backgroundColor = Color.white
        backgroundView = UIView()
        backgroundView?.backgroundColor = Color.white
        selectedBackgroundView = UIView()
        selectedBackgroundView?.backgroundColor = Color.gray50

        contentView.addSubview(separatorView)
        separatorView.snp.makeConstraints {
            $0.top.equalToSuperview()
            $0.leading.trailing.equalToSuperview().inset(Constants.padding)
            $0.height.equalTo(Constants.separatorHeight)
        }

        contentView.addSubview(frequencyIndicatorView)
        frequencyIndicatorView.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(Constants.padding)
            $0.centerY.equalToSuperview()
            $0.width.equalTo(Constants.indicatorWidth)
            $0.height.equalTo(Constants.indicatorHeight)
        }

        contentView.addSubview(channelLabel)
        channelLabel.snp.makeConstraints {
            $0.leading.equalTo(frequencyIndicatorView.snp.trailing)
            $0.centerY.equalToSuperview()
            $0.width.equalTo(Constants.channelWidth)
        }

        contentView.addSubview(avatarImageView)
        avatarImageView.snp.makeConstraints {
            $0.leading.equalTo(channelLabel.snp.trailing).offset(Constants.padding/2)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(Constants.avatarHeight)
        }

        contentView.addSubview(resultLabel)
        resultLabel.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(Constants.padding)
            $0.centerY.equalToSuperview()
        }

        contentView.addSubview(actionButton)
        actionButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(Constants.padding)
            $0.centerY.equalToSuperview()
        }

        contentView.addSubview(textStackView)
        textStackView.snp.makeConstraints {
            $0.leading.equalTo(avatarImageView.snp.trailing).offset(Constants.padding)
            $0.trailing.lessThanOrEqualTo(resultLabel.snp.leading).inset(Constants.spacing)
            $0.trailing.lessThanOrEqualTo(actionButton.snp.leading).inset(Constants.spacing)
            $0.centerY.equalToSuperview()
        }
    }

    // MARK: - Configuration

    func configure(with viewModel: ZippyqFrequencyViewModel, showsTopSeparator: Bool) {
        let backgroundColor = viewModel.isCurrentUser ? Constants.currentUserBackgroundColor : Color.white
        self.backgroundColor = backgroundColor
        backgroundView?.backgroundColor = backgroundColor

        titleLabel.text = viewModel.titleLabel
        titleLabel.textColor = viewModel.isAssigned ? Color.black : Color.gray200
        subtitleLabel.text = viewModel.subtitleLabel
        resultLabel.text = viewModel.resultLabel
        resultLabel.isHidden = viewModel.resultLabel == nil
        actionButton.action = viewModel.action
        actionButton.isEnabled = viewModel.isActionEnabled
        separatorView.isHidden = !showsTopSeparator

        frequencyIndicatorView.backgroundColor = viewModel.frequencyColor
        channelLabel.text = viewModel.channelLabel

        if viewModel.isAssigned {
            avatarImageView.imageView.backgroundColor = Color.white
            avatarImageView.imageView.setImage(with: viewModel.imageUrl,
                                               placeholderImage: PlaceholderImg.medium,
                                               size: CGSize(width: Constants.avatarHeight, height: Constants.avatarHeight))
        } else {
            avatarImageView.imageView.af_cancelImageRequest()
            avatarImageView.imageView.image = nil
            avatarImageView.imageView.backgroundColor = Color.gray100
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        channelLabel.text = nil
        avatarImageView.imageView.image = nil
        titleLabel.text = nil
        subtitleLabel.text = nil
        resultLabel.text = nil
        resultLabel.isHidden = true
        actionButton.action = nil
        actionButton.isEnabled = false
        actionButton.isLoading = false
        separatorView.isHidden = true
    }
}
