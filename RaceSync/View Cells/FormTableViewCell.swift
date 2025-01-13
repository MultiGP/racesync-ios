//
//  FormTableViewCell.swift
//  RaceSync
//
//  Created by Ignacio Romero Zurbuchen on 2019-12-31.
//  Copyright © 2019 MultiGP Inc. All rights reserved.
//

import UIKit
import SnapKit

class FormTableViewCell: UITableViewCell {

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

    var detailImage: UIImage? {
        get { return accessoryImageView.image }
        set {
            accessoryImageView.image = newValue
            accessoryImageView.isHidden = (newValue == nil)
            detailTextLabel?.isHidden = (newValue != nil)
        }
    }

    // MARK: - Private Variables

    fileprivate lazy var spinnerView: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(style: .medium)
        return view
    }()

    fileprivate lazy var accessoryImageView: UIImageView = {
        let view = UIImageView()
        view.isUserInteractionEnabled = false
        view.isHidden = true
        return view
    }()

    fileprivate enum Constants {
        static let padding: CGFloat = UniversalConstants.padding
        static let buttonSpacing: CGFloat = 8
    }

    // MARK: - Initializatiom

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .value1, reuseIdentifier: reuseIdentifier)
        setupLayout()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Layout

    fileprivate func setupLayout() {
        let selectedBackgroundView = UIView()
        selectedBackgroundView.backgroundColor = Color.gray50
        self.selectedBackgroundView = selectedBackgroundView

        accessoryType = .disclosureIndicator

        addSubview(accessoryImageView)
        accessoryImageView.snp.makeConstraints {
            $0.trailing.equalTo(contentView.snp.trailing).offset(-Constants.buttonSpacing)
            $0.centerY.equalToSuperview()
        }
    }
}
