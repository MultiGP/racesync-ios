//
//  ActivityLoadingView.swift
//  RaceSync
//
//  Created by Ignacio Romero Zurbuchen on 2025-09-07.
//  Copyright © 2025 MultiGP Inc. All rights reserved.
//

import UIKit
import SnapKit

class ActivityLoadingView : UIView {

    // MARK: - Public

    var title: String = "Loading..." {
        didSet {
            loadingLabel.text = title
        }
    }

    var hidesWhenStopped: Bool = true {
        didSet {
            spinnerView.hidesWhenStopped = hidesWhenStopped
        }
    }

    var isLoading: Bool = false {
        didSet {
            isHidden = !isLoading
            isLoading ? spinnerView.startAnimating() : spinnerView.stopAnimating()
        }
    }

    // MARK: - Private Variables

    fileprivate var style: UIActivityIndicatorView.Style

    fileprivate lazy var spinnerView: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(style: self.style)
        view.hidesWhenStopped = hidesWhenStopped
        return view
    }()

    fileprivate lazy var loadingLabel: UILabel = {
        let label = UILabel()
        label.text = self.title
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = Color.gray300
        return label
    }()

    // MARK: - Initialization

    public init(style: UIActivityIndicatorView.Style) {
        self.style = style

        super.init(frame: .zero)
        setupLayout()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Layout

    fileprivate func setupLayout() {

        backgroundColor = Color.clear

        let stackView = UIStackView(arrangedSubviews: [spinnerView, loadingLabel])
        stackView.axis = .horizontal
        stackView.spacing = 8
        stackView.alignment = .center

        addSubview(stackView)
        stackView.snp.makeConstraints {
            $0.centerY.centerX.equalToSuperview()
        }
    }
}
