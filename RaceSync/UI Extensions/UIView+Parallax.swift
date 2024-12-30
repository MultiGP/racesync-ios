//
//  UIView+Parallax.swift
//  RaceSync
//
//  Created by Ignacio Romero Zurbuchen on 2024-12-30.
//  Copyright © 2024 MultiGP Inc. All rights reserved.
//

import UIKit

extension UIView {

    public static func addParallaxToView(_ view: UIView, amount: CGFloat = 20) {

        let horizontal = UIInterpolatingMotionEffect(keyPath: "center.x", type: .tiltAlongHorizontalAxis)
        horizontal.minimumRelativeValue = -amount
        horizontal.maximumRelativeValue = amount

        let vertical = UIInterpolatingMotionEffect(keyPath: "center.y", type: .tiltAlongVerticalAxis)
        vertical.minimumRelativeValue = -amount
        vertical.maximumRelativeValue = amount

        let group = UIMotionEffectGroup()
        group.motionEffects = [horizontal, vertical]
        view.addMotionEffect(group)
    }
}
