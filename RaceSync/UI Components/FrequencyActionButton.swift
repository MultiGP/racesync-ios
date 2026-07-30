//
//  FrequencyActionButton.swift
//  RaceSync
//
//  Created by Ignacio Romero on 2026-07-29.
//  Copyright © 2026 MultiGP Inc. All rights reserved.
//

import UIKit
import SnapKit

class FrequencyActionButton: CustomButton {

    var action: ZippyqFrequencyAction? {
        didSet {
            updateAppearance()
        }
    }

    var isLoading = false {
        didSet {
            updateLoadingState()
        }
    }

    override var isEnabled: Bool {
        didSet {
            alpha = isEnabled ? 1 : 0.4
            if !isLoading {
                isUserInteractionEnabled = isEnabled
            }
        }
    }

    private enum Constants {
        static let height: CGFloat = 32
        static let horizontalPadding: CGFloat = 12
    }

    private lazy var spinnerView: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(style: .medium)
        addSubview(view)
        view.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
        return view
    }()

    init() {
        super.init(frame: .zero)
        setupLayout()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupLayout() {
        setContentHuggingPriority(.required, for: .horizontal)
        setContentCompressionResistancePriority(.required, for: .horizontal)
        contentEdgeInsets = UIEdgeInsets(top: 4, left: Constants.horizontalPadding, bottom: 4, right: Constants.horizontalPadding)
        layer.cornerCurve = .continuous
        isHidden = true
    }

    private func updateAppearance() {
        guard let action else {
            isHidden = true
            return
        }

        isHidden = false
        setTitleColor(action.titleColor, for: .normal)
        titleLabel?.font = action.font
        backgroundColor = action.backgroundColor
        updateLoadingState()
    }

    private func updateLoadingState() {
        guard let action else {
            spinnerView.stopAnimating()
            return
        }

        setTitle(action.title, for: .normal)
        titleLabel?.alpha = isLoading ? 0 : 1
        isUserInteractionEnabled = !isLoading && isEnabled

        if isLoading {
            spinnerView.color = action.titleColor
            spinnerView.startAnimating()
        } else {
            spinnerView.stopAnimating()
        }
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(width: size.width, height: Constants.height)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        if #available(iOS 26.0, *) {
            layer.cornerRadius = bounds.height / 2
        } else {
            layer.cornerRadius = 6
        }
    }

    override func sendAction(_ action: Selector, to target: Any?, for event: UIEvent?) {
        guard !isLoading else { return }

        isLoading = true
        super.sendAction(action, to: target, for: event)
    }
}

extension ZippyqFrequencyAction {

    fileprivate var title: String {
        switch self {
        case .addMe:            return "Add Me"
        case .`switch`:         return "Switch"
        case .remove:           return "Remove"
        }
    }

    fileprivate var backgroundColor: UIColor {
        switch self {
        case .addMe:            return Color.green
        case .`switch`:         return Color.green
        case .remove:           return Color.lightRed
        }
    }

    fileprivate var titleColor: UIColor {
        switch self {
        case .addMe:            return Color.light
        case .`switch`:         return Color.light
        case .remove:           return Color.light
        }
    }
    
    fileprivate var font: UIFont {
        switch self {
        case .addMe, .`switch`:
                            return UIFont.systemFont(ofSize: 14, weight: .semibold)
        default:            return UIFont.systemFont(ofSize: 14, weight: .regular)

        }
    }
}
