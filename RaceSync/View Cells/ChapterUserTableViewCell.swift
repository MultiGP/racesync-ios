//
//  ChapterUserTableViewCell.swift
//  RaceSync
//
//  Created by Ignacio Romero Zurbuchen on 2020-03-23.
//  Copyright © 2020 MultiGP Inc. All rights reserved.
//

import UIKit
import SnapKit

class ChapterUserTableViewCell: AvatarTableViewCell {

    let joinButton = JoinButton(type: .system)

    override func setupLayout() {
        super.setupLayout()

        accessoryType = .none
        contentView.addSubview(joinButton)
        joinButton.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.height.equalTo(JoinButton.minHeight)
            $0.width.equalTo(92)
            $0.trailing.equalToSuperview().offset(-UniversalConstants.padding)
        }
    }
}
