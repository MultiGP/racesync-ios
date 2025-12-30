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
            let status_height = UIApplication.shared.statusBarFrame.height
            let navi_height = navigationController?.navigationBar.frame.size.height ?? 44
            return status_height + navi_height
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
