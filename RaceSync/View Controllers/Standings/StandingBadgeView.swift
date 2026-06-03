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

        let standing = viewModel.standing
        let textSize: CGFloat = 90
        let isZipper = standing.season1.contains("2025") || standing.season1.contains("2024") // Only 2024 and 2025 had 2 scores per season

        // Define attributes
        let rankAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: textSize, weight: .bold),
            .foregroundColor: UIColor.white
        ]
        let ordinalAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: textSize/2, weight: .medium),
            .foregroundColor: UIColor.white,
            .baselineOffset: textSize/3 // raises the ordinal element to the top of the font
        ]

        // Create attributed rank string
        let rankString = NSMutableAttributedString(string: positionText, attributes: rankAttributes)
        if let suffixRange = positionText.range(of: suffixText) {
            let nsRange = NSRange(suffixRange, in: positionText)
            rankString.setAttributes(ordinalAttributes, range: nsRange)
        }

        positionLabel.attributedText = rankString
        positionLabel.sizeToFit() //forcing the label to adjust size

        titleLabel.text = viewModel.titleLabel

        let score1 = StandingViewModel.timeLabel(for: standing.season1Score)
        let score2 = StandingViewModel.timeLabel(for: standing.season2Score)

        // When not zipper (2 seasons), we are making this label slightly bigger since only will be displayed
        time1Label.attributedText = attributedScore(label: viewModel.score1Label, scores: [score1, score2], size: isZipper ? 20 : 30)
        time2Label.attributedText = attributedScore(label: viewModel.score2Label, scores: [score1, score2])

        // Download the image and render
        let placeholder = PlaceholderImg.profileAvatar?.withRenderingMode(.alwaysOriginal)
        imageView.setImage(with: imageUrl, placeholderImage: placeholder) { _ in
            let image = self.asImage()

            DispatchQueue.main.async {
                completion(image)
            }
        }
    }

    fileprivate func attributedScore(label: String, scores: [String], size: CGFloat = 20) -> NSAttributedString {
        let white: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: size, weight: .semibold),
            .foregroundColor: UIColor.white
        ]
        let yellow: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: size, weight: .semibold),
            .foregroundColor: UIColor.yellow
        ]

        let result = NSMutableAttributedString(string: label, attributes: white)

        scores.forEach { score in
            guard score != "N/A" else { return }
            let range = (label as NSString).range(of: score)
            if range.location != NSNotFound && range.length > 0 {
                result.setAttributes(yellow, range: range)
            }
        }

        return result
    }

    fileprivate func asImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        return renderer.image { context in
            layer.render(in: context.cgContext)
        }
    }
}
