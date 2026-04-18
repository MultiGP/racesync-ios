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

        let appearance = nc.navigationBar.standardAppearance
        appearance.shadowColor = hide ? .clear : Color.gray100
        nc.navigationBar.standardAppearance = appearance
        nc.navigationBar.scrollEdgeAppearance = appearance
    }
}

protocol ScrollToTop where Self: UIViewController {
    func scrollToTop()
}
