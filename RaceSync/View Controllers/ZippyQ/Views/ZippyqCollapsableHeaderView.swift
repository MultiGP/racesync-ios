//
//  ZippyqCollapsableHeaderView.swift
//  RaceSync
//
//  Created by Ignacio Romero on 2026-07-29.
//  Copyright © 2026 MultiGP Inc. All rights reserved.
//

import UIKit
import SnapKit
import AlamofireImage

class ZippyqCollapsableHeaderView: UICollectionReusableView {

    // MARK: - Public Variables

    static let identifier = "ZippyqCollapsableHeaderView"
    static let headerHeight: CGFloat = 58
    static let headerHeightWithSubtitle: CGFloat = 76

    private(set) var isExpanded = false

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
        imageView.tintColor = .tertiaryLabel
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

    fileprivate lazy var accessoryContainerView = UIView()

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
        let stackView = UIStackView(arrangedSubviews: [accessoryContainerView, chevronImageView])
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

    fileprivate lazy var contentView = UIView()

    fileprivate var isTouching = false
    fileprivate var isExpandable = true
    fileprivate var accessoryWidthConstraint: Constraint?
    fileprivate var avatarImageUrls = [String?]()

    fileprivate enum Constants {
        static let padding: CGFloat = UniversalConstants.padding
        static let badgeSpacing: CGFloat = 10
        static let chevronSize: CGFloat = 20
        static let avatarSize: CGFloat = headerHeight / 2
        static let avatarOverlap: CGFloat = avatarSize / 4
        static let avatarBorderWidth: CGFloat = 2
        static let separatorHeight: CGFloat = 0.5
    }
    
    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Overrides

    override func prepareForReuse() {
        super.prepareForReuse()

        didTapView = nil
        titleLabel.text = nil
        contextualLabel.text = nil
        subtitleLabel.text = nil
        subtitleContextLabel.text = nil
        textPill.isHidden = true
        avatarImageUrls = []
        updateAvatars()
        setHighlighted(false)
        setExpanded(false, animated: false)
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
    
    // MARK: - Configuration

    func configure(with viewModel: ZippyqRoundViewModel, isExpanded: Bool) {
        titleLabel.text = viewModel.titleLabel
        contextualLabel.text = viewModel.contextualLabel
        subtitleLabel.text = viewModel.heatLabel
        subtitleContextLabel.text = viewModel.scoringFormatLabel
        textPill.text = viewModel.badge.title
        textPill.titleLabel.textColor = viewModel.badge.titleColor
        textPill.backgroundColor = viewModel.badge.backgroundColor
        avatarImageUrls = viewModel.avatarImageUrls
        updateAvatars()

        self.isExpandable = viewModel.isExpandable
        self.isExpanded = viewModel.isExpandable && isExpanded
        updateExpansionState(animated: false)
    }
    
    func setExpanded(_ expanded: Bool, animated: Bool) {
        guard isExpandable else { return }
        guard expanded != isExpanded else { return }

        isExpanded = expanded
        updateExpansionState(animated: animated)
    }
}

private extension ZippyqCollapsableHeaderView {

    func setupLayout() {
        backgroundColor = Color.tableBackground

        addSubview(contentView)
        contentView.backgroundColor = Color.tableBackground
        contentView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        contentView.addSubview(contentStackView)
        contentStackView.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(Constants.padding)
            $0.trailing.equalToSuperview().offset(-Constants.padding)
            $0.top.equalToSuperview().offset(12)
        }

        accessoryContainerView.addSubview(contextualLabel)
        accessoryContainerView.addSubview(avatarStackView)
        accessoryContainerView.snp.makeConstraints {
            accessoryWidthConstraint = $0.width.equalTo(0).constraint
            $0.height.equalTo(Constants.avatarSize)
        }
        contextualLabel.snp.makeConstraints {
            $0.trailing.centerY.equalToSuperview()
        }
        avatarStackView.snp.makeConstraints {
            $0.trailing.centerY.equalToSuperview()
        }

        chevronImageView.snp.makeConstraints {
            $0.width.height.equalTo(Constants.chevronSize)
        }
        chevronImageView.image = UIImage(
            systemName: "chevron.down",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 19, weight: .medium)
        )

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
        updateAccessoryWidth()
    }

    func updateAccessoryWidth() {
        let avatarCount = CGFloat(avatarImageUrls.count)
        let avatarsWidth = avatarCount > 0
            ? avatarCount * Constants.avatarSize - (avatarCount - 1) * Constants.avatarOverlap
            : 0
        let width = max(avatarsWidth, contextualLabel.intrinsicContentSize.width)
        accessoryWidthConstraint?.update(offset: width)
    }

    func updateExpansionState(animated: Bool) {
        separatorView.isHidden = isExpanded
        chevronImageView.isHidden = !isExpandable

        let displaysAvatars = isExpandable && !isExpanded && !avatarImageUrls.isEmpty
        let displaysContext = !isExpandable || isExpanded
        let displaysSubtitle = isExpandable && isExpanded && subtitleLabel.text?.isEmpty == false
        let displaysSubtitleContext = isExpandable && isExpanded && subtitleContextLabel.text?.isEmpty == false
        let displaysMetadata = displaysSubtitle || displaysSubtitleContext
        let expectedExpandedState = isExpanded

        [avatarStackView, contextualLabel, metadataStackView, subtitleLabel, subtitleContextLabel].forEach {
            $0.layer.removeAllAnimations()
        }

        avatarStackView.isHidden = false
        contextualLabel.isHidden = false
        metadataStackView.isHidden = false
        subtitleLabel.isHidden = false
        subtitleContextLabel.isHidden = false

        let updates = {
            self.avatarStackView.alpha = displaysAvatars ? 1 : 0
            self.contextualLabel.alpha = displaysContext ? 1 : 0
            self.metadataStackView.alpha = displaysMetadata ? 1 : 0
            self.subtitleLabel.alpha = displaysSubtitle ? 1 : 0
            self.subtitleContextLabel.alpha = displaysSubtitleContext ? 1 : 0
        }
        let completion: (Bool) -> Void = { _ in
            guard self.isExpanded == expectedExpandedState else { return }
            self.avatarStackView.isHidden = !displaysAvatars
            self.contextualLabel.isHidden = !displaysContext
            self.metadataStackView.isHidden = !displaysMetadata
            self.subtitleLabel.isHidden = !displaysSubtitle
            self.subtitleContextLabel.isHidden = !displaysSubtitleContext
        }

        guard animated else {
            updateChevron(animated: false)
            updates()
            completion(true)
            return
        }
        updateChevron(animated: true)
        UIView.animate(
            withDuration: 0.25,
            delay: 0,
            options: [.beginFromCurrentState, .allowUserInteraction, .curveEaseInOut],
            animations: updates,
            completion: completion
        )
    }

    func updateChevron(animated: Bool) {
        let targetRotation: CGFloat = isExpanded ? .pi : 0
        guard animated else {
            chevronImageView.layer.transform = CATransform3DMakeRotation(targetRotation, 0, 0, 1)
            return
        }

        let currentRotation = chevronImageView.layer.presentation()?
            .value(forKeyPath: "transform.rotation.z") as? CGFloat
            ?? (isExpanded ? 0 : .pi)
        chevronImageView.layer.transform = CATransform3DMakeRotation(targetRotation, 0, 0, 1)

        let animation = CABasicAnimation(keyPath: "transform.rotation.z")
        animation.fromValue = currentRotation
        animation.toValue = targetRotation
        animation.duration = 0.25
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        chevronImageView.layer.add(animation, forKey: "rotation")
    }
}
