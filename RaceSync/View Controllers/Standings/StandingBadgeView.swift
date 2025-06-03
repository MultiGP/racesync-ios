//
//  StandingBadgeView.swift
//  RaceSync
//
//  Created by Ignacio Romero Zurbuchen on 2025-06-02.
//  Copyright © 2025 MultiGP Inc. All rights reserved.
//

import UIKit
import RaceSyncAPI

public typealias RenderBlock = (_ image: UIImage) -> Void

class StandingBadgeView: UIView {

    // MARK: - Variables

    @IBOutlet var positionLabel: UILabel!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var time1Label: UILabel!
    @IBOutlet var time2Label: UILabel!
    @IBOutlet var imageView: UIImageView!

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    fileprivate func commonInit() {
        let nib = UINib(nibName: String(describing: type(of: self)), bundle: .main)
        guard let loadedView = nib.instantiate(withOwner: self).first as? UIView else { return }

        loadedView.frame = bounds
        loadedView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(loadedView)
    }

    func configureView(with viewModel: StandingViewModel, imageUrl: String?, completion: @escaping RenderBlock) {
        let positionText = String.stringWithOrdinalSuffix(for: viewModel.rank)
        let suffixText = String.ordinalSuffix(for: viewModel.rank)

        // Define attributes
        let rankAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 90, weight: .bold),
            .foregroundColor: UIColor.white
        ]
        let ordinalAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 50, weight: .medium),
            .foregroundColor: UIColor.white
        ]

        // Create attributed rank string
        let rankString = NSMutableAttributedString(string: positionText, attributes: rankAttributes)
        if let suffixRange = positionText.range(of: suffixText) {
            let nsRange = NSRange(suffixRange, in: positionText)
            rankString.setAttributes(ordinalAttributes, range: nsRange)
        }

        // Helper function to create attributed score labels
        func attributedScore(label: String, score: String) -> NSAttributedString {
            let whiteAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 20, weight: .semibold),
                .foregroundColor: UIColor.white
            ]
            let yellowAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 20, weight: .semibold),
                .foregroundColor: UIColor.yellow
            ]

            let attributedString = NSMutableAttributedString(string: label, attributes: whiteAttributes)

            if score != "N/A", let scoreRange = label.range(of: score) {
                let nsRange = NSRange(scoreRange, in: label)
                attributedString.setAttributes(yellowAttributes, range: nsRange)
            }

            return attributedString
        }

        positionLabel.attributedText = rankString
        titleLabel.text = viewModel.titleLabel

        let score1 = StandingViewModel.timeLabel(for: viewModel.standing.season1Score)
        time1Label.attributedText = attributedScore(label: viewModel.score1Label, score: score1)

        let score2 = StandingViewModel.timeLabel(for: viewModel.standing.season2Score)
        time2Label.attributedText = attributedScore(label: viewModel.score2Label, score: score2)

        // Download the image and render
        let placeholder = PlaceholderImg.profileAvatar?.withRenderingMode(.alwaysOriginal)
        imageView.setImage(with: imageUrl, placeholderImage: placeholder) { _ in
            let image = self.asImage()

            DispatchQueue.main.async {
                completion(image)
            }
        }
    }

    fileprivate func asImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        return renderer.image { context in
            layer.render(in: context.cgContext)
        }
    }
}
