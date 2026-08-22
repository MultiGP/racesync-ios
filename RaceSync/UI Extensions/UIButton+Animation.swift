//
//  UIButton+Animation.swift
//  RaceSync
//
//  Created by Ignacio Romero on 2026-08-18.
//  Copyright © 2026 MultiGP Inc. All rights reserved.
//

import UIKit

extension UIButton {
    
    func animatePress() {
        UIView.animate(
            withDuration: 0.12,
            animations: { self.transform = CGAffineTransform(scaleX: 0.88, y: 0.88) }
        ) { _ in
            UIView.animate(
                withDuration: 0.4,
                delay: 0,
                usingSpringWithDamping: 0.4,
                initialSpringVelocity: 8,
                options: .allowUserInteraction,
                animations: { self.transform = .identity }
            )
        }
    }
}
