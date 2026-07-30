//
//  CollapsableHeaderView.swift
//  RaceSync
//
//  Created by Ignacio Romero on 2026-07-29.
//  Copyright © 2026 MultiGP Inc. All rights reserved.
//

import UIKit
import SnapKit

class CollapsableHeaderView: UITableViewHeaderFooterView {

    // MARK: - Public Variables

    static let identifier = "CollapsableHeaderView"
    static let headerHeight: CGFloat = 58

    var title: String? {
        didSet { titleLabel.text = title }
    }

    var contextualText: String? {
        didSet { contextualLabel.text = contextualText }
    }

    var isExpanded: Bool = false {
        didSet {
            chevronImageView.image = UIImage(systemName: isExpanded ? "chevron.up" : "chevron.down")
            separatorView.isHidden = isExpanded
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
            label.font = UIFont.systemFont(ofSize: 16, weight: .medium, width: .condensed)
        } else {
            label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        }
        label.textColor = Color.gray200
        label.textAlignment = .right
        return label
    }()

    fileprivate lazy var chevronImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.tintColor = Color.gray400
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    fileprivate lazy var leadingStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [titleLabel, textPill])
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = Constants.badgeSpacing
        return stackView
    }()

    fileprivate lazy var trailingStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [contextualLabel, chevronImageView])
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
        isAccessibilityElement = true
        accessibilityTraits = .button

        contentView.addSubview(leadingStackView)
        leadingStackView.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(Constants.padding)
            $0.centerY.equalToSuperview()
        }

        contentView.addSubview(trailingStackView)
        trailingStackView.snp.makeConstraints {
            $0.leading.greaterThanOrEqualTo(leadingStackView.snp.trailing).offset(Constants.padding).priority(.high)
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
}
