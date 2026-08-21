//
//  ZippyqFrequencyCollectionViewCell.swift
//  RaceSync
//
//  Created by Ignacio Romero on 2026-08-20.
//  Copyright © 2026 MultiGP Inc. All rights reserved.
//

import UIKit
import SnapKit

class ZippyqFrequencyCollectionViewCell: UICollectionViewCell {

    let frequencyView = ZippyqFrequencyContentView()

    var actionButton: FrequencyActionButton {
        return frequencyView.actionButton
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.addSubview(frequencyView)
        frequencyView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with viewModel: ZippyqFrequencyViewModel, showsTopSeparator: Bool) {
        frequencyView.configure(with: viewModel, showsTopSeparator: showsTopSeparator)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        frequencyView.prepareForReuse()
    }

    override var isHighlighted: Bool {
        didSet {
            frequencyView.isHighlighted = isHighlighted
        }
    }
}
