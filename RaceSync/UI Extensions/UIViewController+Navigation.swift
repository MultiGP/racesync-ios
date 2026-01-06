//
//  UIViewController+Navigation.swift
//  RaceSync
//
//  Created by Ignacio Romero Zurbuchen on 2021-10-21.
//  Copyright © 2021 MultiGP Inc. All rights reserved.
//

import UIKit

extension UIViewController {

    var topOffset: CGFloat {
        get {
            var height = UIApplication.shared.statusBarFrame.height
            height += navigationController?.navigationBar.frame.size.height ?? 44.0
            return height
        }
    }

    func hideNavigationShadow(_ hide: Bool = true) {
        guard let nc = navigationController else { return }

        // By masking to bounds, the shadow of a navigation bar is no longer visible
        // This trick only works when the backgroud of view behind the navigation bar is the same color
        // It cannot be used for transitioning to more complicated views.
        nc.navigationBar.layer.masksToBounds = hide
    }
}

protocol ScrollToTop where Self: UIViewController {
    func scrollToTop()
}
