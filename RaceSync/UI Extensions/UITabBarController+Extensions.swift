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

        self.setValue(RoundedSelectionTabBar(), forKey: "tabBar")

        self.viewControllers = vcs

        // Trick to pre-load each view controller
        self.preloadTabs()

        var index = selectedIndex
        let defaultIndex = 0

        // makes sure disabled tabs aren't selected
        // and defaults to the first tab
        if index != defaultIndex {
            let vc = vcs[index]

            if let item = vc.tabBarItem, !item.isEnabled {
                index = defaultIndex
            }
        }
        else if vcs.count > 1 {
            self.selectedIndex = index+1
        }

        self.selectedIndex = index
    }

    func preloadTabs() {
        if let vcs = viewControllers {
            for vc in vcs {
                let _ = vc.view
            }
        }
    }
}
