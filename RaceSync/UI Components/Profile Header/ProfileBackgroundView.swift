//
//  ProfileBackgroundView.swift
//  RaceSync
//
//  Created by Ignacio Romero Zurbuchen on 2020-08-03.
//  Copyright © 2020 MultiGP Inc. All rights reserved.
//

import UIKit
import SnapKit
import RaceSyncAPI

class ProfileBackgroundView: DimmableView {

    // MARK: - Public Variables

    lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.backgroundColor = Color.white
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()

    // MARK: - Private Variables

    fileprivate lazy var backgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = Color.black
        return view
    }()

    fileprivate lazy var backdropView: UIView = {
        let view = UIView()
        view.backgroundColor = Color.white
        return view
    }()

    fileprivate lazy var blurView: UIVisualEffectView = {
        let view = UIVisualEffectView(effect: nil)
        view.alpha = 0
        return view
    }()

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Layout

    fileprivate func setupLayout() {

        backgroundColor = Color.clear
        dimmableView = imageView

        addSubview(backdropView)
        backdropView.snp.makeConstraints {
            $0.top.bottom.leading.trailing.equalToSuperview()
        }

        addSubview(backgroundView)
        backgroundView.snp.makeConstraints {
            $0.top.bottom.leading.trailing.equalToSuperview()
        }

        addSubview(imageView)
        imageView.snp.makeConstraints {
            $0.top.bottom.leading.trailing.equalToSuperview()
        }

        addSubview(blurView)
        blurView.snp.makeConstraints {
            $0.top.bottom.leading.trailing.equalToSuperview()
        }
    }
}

extension ProfileBackgroundView: StretchableView {

    func changeLayerFrame(_ frame: CGRect) {
        layer.frame = frame
        imageView.layer.frame = CGRect(origin: .zero, size: frame.size)
        blurView.layer.frame = CGRect(origin: .zero, size: frame.size)
    }

    func changeLayerEffect(_ percentage: CGFloat) {
//        let clamped = max(0, min(1, percentage))
//        blurView.effect = UIBlurEffect(style: .regular)
//        blurView.alpha = clamped
    }
}
