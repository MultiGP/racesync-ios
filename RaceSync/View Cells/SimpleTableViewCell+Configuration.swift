//
//  SimpleTableViewCell+Configuration.swift
//  RaceSync
//
//  Created by Ignacio Romero Zurbuchen on 2026-04-12.
//  Copyright © 2026 MultiGP Inc. All rights reserved.
//

import UIKit
import RaceSyncAPI

extension SimpleTableViewCell {

    static func configure<T>(_ cell: T, with viewModel: SeriesViewModel) where T : SimpleTableViewCell {
        cell.titleLabel.text = viewModel.titleLabel
        cell.titleLabel.numberOfLines = 2
        cell.subtitleLabel.text = viewModel.subtitleLabel
        cell.accessoryType = .disclosureIndicator

        let imageRatio = 1.5
        let imageHeight = UniversalConstants.cellAvatarHeight + 10
        let imageSize = CGSize(width: imageHeight * imageRatio, height: imageHeight)
        cell.imageRatio = imageRatio
        cell.iconImageView.setImage(with: viewModel.imageUrl, placeholderImage: PlaceholderImg.seriesSmall, size: imageSize)
        cell.iconImageView.contentMode = .center
        cell.iconImageView.layer.cornerRadius = 6
        cell.iconImageView.layer.masksToBounds = true
        
        cell.backgroundColor = Color.white
        cell.selectedBackgroundView?.backgroundColor = Color.gray20
    }
}
