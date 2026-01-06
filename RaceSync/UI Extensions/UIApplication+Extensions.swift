//
//  UIApplication+Extensions.swift
//  RaceSync
//
//  Created by Ignacio Romero Zurbuchen on 2026-01-05.
//  Copyright © 2026 MultiGP Inc. All rights reserved.
//

import UIKit

extension UIApplication {

    var statusBarFrame: CGRect {
        guard let scene = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first,
            let statusBarFrame = scene.statusBarManager?.statusBarFrame
        else {
            return .zero
        }
        return statusBarFrame
    }

    var keyWindow: UIWindow? {
        return UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
    }
}
