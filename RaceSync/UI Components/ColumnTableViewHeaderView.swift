//
//  ColumnTableViewHeaderView.swift
//  RaceSync
//
//  Created by Ignacio Romero Zurbuchen on 2025-08-08.
//  Copyright © 2025 MultiGP Inc. All rights reserved.
//

import UIKit
import SnapKit

class ColumnTableViewHeaderView: UITableViewHeaderFooterView {

    // MARK: - Private Variables

    static var identifier: String = "ColumnTableViewHeaderView"

    static var headerHeight: CGFloat {
        return Constants.height
    }

    // MARK: - Private Variables

    fileprivate lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fill
        stackView.alignment = .center
        stackView.spacing = 40
        stackView.backgroundColor = Color.clear

        // Spacer setup
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        spacer.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        stackView.addArrangedSubview(spacer)

        return stackView
    }()

    fileprivate var target: AnyObject?
    fileprivate var action: Selector?

    fileprivate var leftViews = [UIButton]()
    fileprivate var rightViews = [UIButton]()
    fileprivate let spacer = UIView()

    fileprivate enum Constants {
        static let padding: CGFloat = 16
        static let height: CGFloat = padding * 2
    }

    // MARK: - Initialization

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        setupLayout()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Layout

    func addColumn(with title: String, orientation: ContentMode) {
        guard orientation == .left || orientation == .right else { return } // only left and right are supported

        let button = UIButton(type: .system)
        button.addTarget(self, action: #selector(didPressButton), for: .touchUpInside)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        button.titleLabel?.textColor = Color.white
        button.titleLabel?.textAlignment = (orientation == .left) ? .left : .right
        button.tintColor = Color.white
        button.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        button.setContentCompressionResistancePriority(.required, for: .horizontal)

        let string = "\("↕".textSymbol) \(title)" // ⇅ ⇵ ↕
        let attributedString = NSAttributedString(string: string)
        button.setAttributedTitle(attributedString, for: .normal)

        switch orientation {
        case .left:
            // Insert before spacer
            stackView.insertArrangedSubview(button, at: leftViews.count)
            leftViews.append(button)

        case .right:
            // Insert after spacer (which is at index leftViews.count)
            stackView.insertArrangedSubview(button, at: leftViews.count + 1 + rightViews.count)
            rightViews.append(button)

        default:
            break
        }
    }

    fileprivate func setupLayout() {
        backgroundView = UIView()
        backgroundView?.backgroundColor = Color.gray200.withAlphaComponent(0.98)

        addSubview(stackView)
        stackView.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.leading.equalToSuperview().offset(Constants.padding)
            $0.trailing.equalToSuperview().offset(-Constants.padding)
        }

        let separatorLine = UIView()
        separatorLine.backgroundColor = Color.gray400
        addSubview(separatorLine)
        separatorLine.snp.makeConstraints {
            $0.height.equalTo(0.5)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(self.snp.bottom)
        }
    }

    // MARK: - Actions

    func addTarget(_ target: AnyObject?, action: Selector) {
        self.target = target
        self.action = action
    }

    @objc fileprivate func didPressButton(_ sender: Any) {

        if let target = target, let action = action {
            _ = target.perform(action, with: sender)
        }
    }
}

extension String {
    var textSymbol: String { self + "\u{FE0E}" }
}
