//
//  EventSessionTableViewCell.swift
//  RaceSync
//
//  Created by Ignacio Romero on 2026-05-19.
//  Copyright © 2026 MultiGP Inc. All rights reserved.
//

import UIKit

class EventSessionTableViewCell: UITableViewCell {
    
    var isFavorite: Bool = false {
        didSet {
            guard oldValue != isFavorite else { return }
            starImageView.tintColor = isFavorite ? Color.yellow : Color.gray100
            starImageView.image = isFavorite ? SystemImg.starFill : SystemImg.star
        }
    }
    
    static let cellHeight: CGFloat = 72
    
    // MARK: - Public Variables

    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        label.textColor = Color.black
        return label
    }()

    lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        label.textColor = Color.gray300
        return label
    }()
    
    lazy var startTimeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        label.textColor = Color.gray300
        label.textAlignment = .center
        return label
    }()

    lazy var endTimeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        label.textColor = Color.gray300
        label.textAlignment = .center
        return label
    }()
    
    lazy var iconView: UIImageView = {
        let view = UIImageView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        view.image = SystemImg.pin_small?.withRenderingMode(.alwaysTemplate)
        view.contentMode = .scaleAspectFit
        view.backgroundColor = Color.clear
        return view
    }()
        
    // MARK: - Private Variables
        
    fileprivate lazy var starImageView: UIImageView = {
        let view = UIImageView(frame: CGRect(x: 0, y: 0, width: 26, height: 24))
        view.backgroundColor = Color.clear
        return view
    }()

    lazy var labelStackView: UIStackView = {
        let stackView2 = UIStackView(arrangedSubviews: [iconView, subtitleLabel])
        stackView2.axis = .horizontal
        stackView2.alignment = .center
        stackView2.distribution = .fill
        stackView2.spacing = Constants.padding / 2
        
        let stackView = UIStackView(arrangedSubviews: [titleLabel, stackView2])
        stackView.axis = .vertical
        stackView.distribution = .fill
        stackView.alignment = .leading
        stackView.spacing = 5
        return stackView
    }()

    fileprivate lazy var smallLabelStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [startTimeLabel, endTimeLabel])
        stackView.axis = .vertical
        stackView.distribution = .fill
        stackView.alignment = .leading
        stackView.spacing = 5
        return stackView
    }()
    
    fileprivate enum Constants {
        static let padding: CGFloat = UniversalConstants.padding
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
        
        let selectedBackgroundView = UIView()
        selectedBackgroundView.backgroundColor = Color.yellow
        self.selectedBackgroundView = selectedBackgroundView
        
        contentView.addSubview(smallLabelStackView)
        smallLabelStackView.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.leading.equalToSuperview().offset(Constants.padding)
            $0.width.equalTo(60) // fixed width so it never shifts
        }

        contentView.addSubview(labelStackView)
        labelStackView.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.leading.equalTo(smallLabelStackView.snp.trailing).offset(Constants.padding)
            $0.trailing.equalToSuperview().inset(Constants.padding)
        }
        
        starImageView.frame.size = .init(width: 26, height: 24)
        accessoryView = starImageView
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        titleLabel.text = nil
        subtitleLabel.text = nil
        startTimeLabel.text = nil
        endTimeLabel.text = nil
        
        isFavorite = false
    }
}
