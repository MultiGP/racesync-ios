//
//  UIViewController+Lookup.swift
//  RaceSync
//
//  Created by Ignacio Romero Zurbuchen on 2019-12-05.
//  Copyright © 2019 MultiGP Inc. All rights reserved.
//

import UIKit

extension UIViewController {

    // TODO: 'keyWindow' was deprecated in iOS 13.0: Should not be used for applications that support multiple scenes 
    static func topMostViewController() -> UIViewController? {
        guard let window = UIApplication.shared.keyWindow, let rootViewController = window.rootViewController else {
            return nil
        }

        var topController = rootViewController

        while let newTopController = topController.presentedViewController {
            topController = newTopController
        }

        return topController
    }

    func topVisibleViewController() -> UIViewController {
        if let nav = self as? UINavigationController {
            return nav.visibleViewController?.topVisibleViewController() ?? nav
        } else if let tab = self as? UITabBarController {
            return tab.selectedViewController?.topVisibleViewController() ?? tab
        } else if let presented = self.presentedViewController {
            return presented.topVisibleViewController()
        } else {
            return self
        }
    }
}

extension UIApplication {
    /// Finds the top-most visible view controller starting from the key window
    var visibleViewController: UIViewController? {
        guard let root = self.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow })?.rootViewController else {
            return nil
        }
        return root.topVisibleViewController()
    }
}
