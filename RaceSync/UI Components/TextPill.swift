//
//  TextBadge.swift
//  RaceSync
//
//  Created by Ignacio Romero Zurbuchen on 2019-12-14.
//  Copyright © 2019 MultiGP Inc. All rights reserved.
//

import UIKit

enum TextPillStyle {
    case badge, text
}

class TextPill: UIView {

    // MARK: - Public Variables

    var style: TextPillStyle {
        didSet {
            switch style {
            case .badge:
                titleLabel.font = UIFont.systemFont(ofSize: 14, weight: .bold)
                titleLabel.textColor = Color.white
                backgroundColor = Color.gray200.withAlphaComponent(0.5)
            case .text:
                titleLabel.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
                titleLabel.textColor = Color.gray400
                backgroundColor = Color.gray100
            }
        }
    }

    var text: String? {
        get {
            return titleLabel.text
        }
        set {
            titleLabel.text = newValue
            self.isHidden = (newValue == nil)
        }
    }

    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.adjustsFontSizeToFitWidth = false
        label.numberOfLines = 1
        return label
    }()

    // MARK: - Private Variables

    fileprivate enum Constants {
        static let padding: CGFloat = UniversalConstants.padding
        static let buttonSpacing: CGFloat = 10
        static let height: CGFloat = 26
    }

    // MARK: - Initialization

    init(style: TextPillStyle) {
        self.style = style
        super.init(frame: .zero)
        setupLayout()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Layout

    fileprivate func setupLayout() {

        layer.cornerRadius = Constants.height/2
        layer.masksToBounds = true

        addSubview(titleLabel)
        titleLabel.snp.makeConstraints {
            $0.top.bottom.equalToSuperview()

            $0.height.equalTo(Constants.height)
            $0.centerY.equalToSuperview()

            $0.leading.equalToSuperview().offset(Constants.buttonSpacing)
            $0.trailing.equalToSuperview().offset(-Constants.buttonSpacing)
        }
    }
}
