//
//  UITabBarController+Extensions.swift
//  RaceSync
//
//  Created by Ignacio Romero Zurbuchen on 2019-12-11.
//  Copyright © 2019 MultiGP Inc. All rights reserved.
//

import UIKit

extension UITabBarController {

    func configureTabBarController(with vcs: [UIViewController], selectedIndex: Int) {
        guard self.viewControllers == nil else { return } // only once

        self.viewControllers = vcs

        // Trick to pre-load each view controller
        self.preloadTabs()

        var idx = vcs.indices.contains(selectedIndex) ? selectedIndex : 0

        if idx < vcs.count {
            let vc = vcs[idx]

            // makes sure disabled tabs aren't selected
            if let item = vc.tabBarItem, !item.isEnabled {
                idx = 0
            }
        }

        if #available(iOS 26.0, *) {
            if idx == 0, vcs.count > 1 {
                // The first tab is already UIKit's default selection. Force one
                // state change so its selection background is initialized.
                UIView.performWithoutAnimation {
                    self.selectedIndex = 1
                    self.selectedIndex = idx
                    self.view.layoutIfNeeded()
                    self.tabBar.layoutIfNeeded()
                }
            } else {
                UIView.performWithoutAnimation {
                    self.selectedIndex = idx
                    self.view.layoutIfNeeded()
                    self.tabBar.layoutIfNeeded()
                }
            }
        } else {
            // Force refresh to work around a UITabBarController bug on older OSes.
            if idx < vcs.count-1 {
                self.selectedIndex = idx+1
            } else if idx > 0 {
                self.selectedIndex = idx-1
            }

            self.selectedIndex = idx
        }
    }

    func preloadTabs() {
        if let vcs = viewControllers {
            for vc in vcs {
                let _ = vc.view
            }
        }
    }
}
