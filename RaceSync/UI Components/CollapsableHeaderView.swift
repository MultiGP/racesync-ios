//
//  CollapsableHeaderView.swift
//  RaceSync
//
//  Created by Ignacio Romero on 2026-07-29.
//  Copyright © 2026 MultiGP Inc. All rights reserved.
//

import UIKit
import SnapKit
import AlamofireImage

class CollapsableHeaderView: UITableViewHeaderFooterView {

    // MARK: - Public Variables

    static let identifier = "CollapsableHeaderView"
    static let headerHeight: CGFloat = 58
    static let headerHeightWithSubtitle: CGFloat = 76

    var title: String? {
        didSet { titleLabel.text = title }
    }

    var contextualText: String? {
        didSet { contextualLabel.text = contextualText }
    }

    var subtitle: String? {
        didSet {
            subtitleLabel.text = subtitle
            updateMetadataVisibility()
        }
    }

    var subtitleContext: String? {
        didSet {
            subtitleContextLabel.text = subtitleContext
            updateMetadataVisibility()
        }
    }

    var isExpanded: Bool = false {
        didSet {
            chevronImageView.image = UIImage(systemName: isExpanded ? "chevron.up" : "chevron.down")
            separatorView.isHidden = isExpanded
            updateContextualContent()
            updateMetadataVisibility()
        }
    }

    var avatarImageUrls = [String?]() {
        didSet {
            updateAvatars()
            updateContextualContent()
        }
    }

    var selectedBackgroundColor: UIColor? = Color.gray50
    var didTapView: (() -> Void)?

    lazy var textPill: TextPill = {
        let pill = TextPill(style: .badge)
        if #available(iOS 16.0, *) {
            pill.titleLabel.font = UIFont.systemFont(ofSize: 13, weight: .semibold, width: .condensed)
        } else {
            pill.titleLabel.font = UIFont.systemFont(ofSize: 11, weight: .semibold)
        }
        pill.isHidden = true
        return pill
    }()

    // MARK: - Private Variables

    fileprivate lazy var titleLabel: UILabel = {
        let label = UILabel()
        if #available(iOS 16.0, *) {
            label.font = UIFont.systemFont(ofSize: 25, weight: .medium, width: .condensed)
        } else {
            label.font = UIFont.systemFont(ofSize: 22, weight: .medium)
        }
        label.textColor = Color.blue
        return label
    }()

    fileprivate lazy var contextualLabel: UILabel = {
        let label = UILabel()
        if #available(iOS 16.0, *) {
            label.font = UIFont.systemFont(ofSize: 17, weight: .medium, width: .condensed)
        } else {
            label.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        }
        label.textColor = Color.gray300
        label.textAlignment = .right
        return label
    }()

    fileprivate lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        if #available(iOS 16.0, *) {
            label.font = UIFont.systemFont(ofSize: 15, weight: .medium, width: .condensed)
        } else {
            label.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        }
        label.textColor = Color.gray200
        label.isHidden = true
        return label
    }()

    fileprivate lazy var subtitleContextLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = Color.blue
        label.textAlignment = .right
        label.lineBreakMode = .byTruncatingTail
        label.isHidden = true
        return label
    }()

    fileprivate lazy var chevronImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.tintColor = Color.gray400
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    fileprivate lazy var avatarStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = -Constants.avatarOverlap
        return stackView
    }()

    fileprivate lazy var leadingStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [titleLabel, textPill])
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = Constants.badgeSpacing
        return stackView
    }()

    fileprivate lazy var metadataStackView: UIStackView = {
        let spacerView = UIView()
        let stackView = UIStackView(arrangedSubviews: [subtitleLabel, spacerView, subtitleContextLabel])
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = Constants.padding
        stackView.isHidden = true
        return stackView
    }()

    fileprivate lazy var topLineStackView: UIStackView = {
        let spacerView = UIView()
        let stackView = UIStackView(arrangedSubviews: [leadingStackView, spacerView, trailingStackView])
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = Constants.padding
        return stackView
    }()

    fileprivate lazy var contentStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [topLineStackView, metadataStackView])
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.spacing = 0
        return stackView
    }()

    fileprivate lazy var trailingStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [contextualLabel, avatarStackView, chevronImageView])
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = Constants.padding/2
        return stackView
    }()

    fileprivate lazy var separatorView: UIView = {
        let view = UIView()
        view.backgroundColor = Color.gray100
        return view
    }()

    fileprivate var isTouching = false

    fileprivate enum Constants {
        static let padding: CGFloat = UniversalConstants.padding
        static let badgeSpacing: CGFloat = 10
        static let chevronSize: CGFloat = 16
        static let avatarSize: CGFloat = headerHeight / 2
        static let avatarOverlap: CGFloat = avatarSize / 4
        static let avatarBorderWidth: CGFloat = 2
        static let separatorHeight: CGFloat = 0.5
    }

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        didTapView = nil
        avatarImageUrls = []
        subtitle = nil
        subtitleContext = nil
        setHighlighted(false)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)

        isTouching = true
        setHighlighted(true)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)

        guard let touch = touches.first else { return }
        isTouching = bounds.contains(touch.location(in: self))
        setHighlighted(isTouching)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)

        let shouldInvokeTap = isTouching
        isTouching = false
        setHighlighted(false)

        if shouldInvokeTap {
            didTapView?()
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)

        isTouching = false
        setHighlighted(false)
    }
}

private extension CollapsableHeaderView {

    func setupLayout() {
        backgroundView = UIView()
        backgroundView?.backgroundColor = Color.tableBackground
        contentView.backgroundColor = Color.tableBackground

        contentView.addSubview(contentStackView)
        contentStackView.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(Constants.padding)
            $0.trailing.equalToSuperview().offset(-Constants.padding)
            $0.centerY.equalToSuperview()
        }

        chevronImageView.snp.makeConstraints {
            $0.width.height.equalTo(Constants.chevronSize)
        }

        contentView.addSubview(separatorView)
        separatorView.snp.makeConstraints {
            $0.leading.trailing.bottom.equalToSuperview()
            $0.height.equalTo(Constants.separatorHeight)
        }
    }

    func setHighlighted(_ highlighted: Bool) {
        contentView.backgroundColor = highlighted ? selectedBackgroundColor : Color.tableBackground
    }

    func updateAvatars() {
        for view in avatarStackView.arrangedSubviews {
            avatarStackView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }

        for imageUrl in avatarImageUrls {
            let avatarImageView = AvatarImageView(withHeight: Constants.avatarSize, showShadow: false)
            avatarImageView.imageView.layer.borderColor = Color.tableBackground.cgColor
            avatarImageView.imageView.layer.borderWidth = Constants.avatarBorderWidth
            avatarImageView.imageView.setImage(with: imageUrl,
                                               placeholderImage: PlaceholderImg.medium,
                                               size: CGSize(width: Constants.avatarSize, height: Constants.avatarSize))
            avatarStackView.addArrangedSubview(avatarImageView)
            avatarImageView.snp.makeConstraints {
                $0.size.equalTo(Constants.avatarSize)
            }
        }
    }

    func updateContextualContent() {
        let displaysAvatars = !isExpanded && !avatarImageUrls.isEmpty
        avatarStackView.isHidden = !displaysAvatars
        contextualLabel.isHidden = !isExpanded
    }

    func updateMetadataVisibility() {
        let displaysSubtitle = isExpanded && subtitle?.isEmpty == false
        let displaysContext = isExpanded && subtitleContext?.isEmpty == false
        subtitleLabel.isHidden = !displaysSubtitle
        subtitleContextLabel.isHidden = !displaysContext
        metadataStackView.isHidden = !displaysSubtitle && !displaysContext
    }
}
