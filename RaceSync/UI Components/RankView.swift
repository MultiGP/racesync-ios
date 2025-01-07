//
//  RankView.swift
//  RaceSync
//
//  Created by Ignacio Romero Zurbuchen on 2025-01-07.
//  Copyright © 2025 MultiGP Inc. All rights reserved.
//

import SnapKit

class RankView: UIView {

    // MARK: - Public Variables

    var rank: Int32? {
        get {
            guard let text = titleLabel.text else { return nil }
            return Int32(text)
        }
        set {
            titleLabel.text = rankString(for: newValue)
            self.isHidden = (titleLabel.text == nil)
        }
    }

    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 19, weight: .medium)
        label.textColor = Color.gray300
        label.textAlignment = .center
        label.numberOfLines = 1
        return label
    }()

    // MARK: - Private Variables

    func rankString(for rank: Int32?) -> String? {
        guard let rank = rank, rank >= 0 else { return nil }

        if rank == 1 {
            return "🥇"
        } else if rank == 2 {
            return "🥈"
        } else if rank == 3 {
            return "🥉"
        }
        return "\(rank)"
    }

    // MARK: - Initialization

    init() {
        super.init(frame: .zero)
        setupLayout()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    fileprivate func setupLayout() {

        layer.masksToBounds = true

        addSubview(titleLabel)
        titleLabel.snp.makeConstraints {
            $0.top.leading.trailing.bottom.equalToSuperview()
        }
    }

}
