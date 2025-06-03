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

    func configureView(with viewModel: StandingViewModel, completion: @escaping RenderBlock) {

        let positionText = String.stringWithOrdinalSuffix(for: viewModel.rank)
        let suffixText = String.ordinalSuffix(for: viewModel.rank)

        let rankAttributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 90, weight: .bold),
                              NSAttributedString.Key.foregroundColor: Color.white]
        let ordinalAttributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 50, weight: .medium),
                          NSAttributedString.Key.foregroundColor: Color.white]

        let rankString = NSMutableAttributedString(string: positionText, attributes: rankAttributes)
        rankString.setAttributes(ordinalAttributes, range: NSString(string: positionText).range(of: suffixText))


        func attributedText(for label: String, score: String) -> NSAttributedString {
            let whiteAttributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 19, weight: .semibold),
                                  NSAttributedString.Key.foregroundColor: Color.white]
            let yellowAttributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 19, weight: .semibold),
                                  NSAttributedString.Key.foregroundColor: Color.yellow]

            let attstring = NSMutableAttributedString(string: label, attributes: whiteAttributes)

            attstring.setAttributes(yellowAttributes, range: NSString(string: label).range(of: score))
            return attstring
        }

        positionLabel.attributedText = rankString
        titleLabel.text = viewModel.titleLabel

        let score1 = StandingViewModel.timeLabel(for: viewModel.standing.season1Score)
        time1Label.attributedText = attributedText(for: viewModel.score1Label, score: score1)

        let score2 = StandingViewModel.timeLabel(for: viewModel.standing.season2Score)
        time2Label.attributedText = attributedText(for: viewModel.score2Label, score: score2)

        let imageUrl = APIServices.shared.myUser?.profilePictureUrl
        let placeholder = PlaceholderImg.profileAvatar?.withRenderingMode(.alwaysOriginal)

        imageView.setImage(with: imageUrl, placeholderImage: placeholder) { (_) in

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
