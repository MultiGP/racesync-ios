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
    var didTapAction: ((FrequencyActionButton) -> Void)?

    var actionButton: FrequencyActionButton {
        return frequencyView.actionButton
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.addSubview(frequencyView)
        frequencyView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        actionButton.addTarget(self, action: #selector(didTapActionButton), for: .touchUpInside)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with viewModel: ZippyqFrequencyViewModel,
                   showsTopSeparator: Bool,
                   allowsQueueActions: Bool) {
        frequencyView.configure(with: viewModel, showsTopSeparator: showsTopSeparator)
        if !allowsQueueActions {
            actionButton.action = nil
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        didTapAction = nil
        frequencyView.prepareForReuse()
    }

    override var isHighlighted: Bool {
        didSet {
            frequencyView.isHighlighted = isHighlighted
        }
    }

    @objc private func didTapActionButton() {
        didTapAction?(actionButton)
    }
}
