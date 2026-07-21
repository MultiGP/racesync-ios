//
//  Appearance.swift
//  RaceSync
//
//  Created by Ignacio Romero Zurbuchen on 2019-11-16.
//  Copyright © 2019 MultiGP Inc. All rights reserved.
//

import UIKit
import AlamofireImage
import Presentr

class Appearance {
    static func configureUIAppearance() {
        applyUserInterfaceStyle()
        configureViewAppearance()
        configureNavigationBarAppearance()
        configureTabBarAppearance()
        configureToolBarAppearance()
        configureActivityIndicatorAppearance()
    }

    static func defaultPresenter() -> Presentr {
        let presenter = Presentr(presentationType: .bottomHalf)
        presenter.blurBackground = false
        presenter.backgroundOpacity = 0.2
        presenter.transitionType = .coverVertical
        presenter.dismissTransitionType = .coverVertical
        presenter.dismissAnimated = true
        presenter.dismissOnSwipe = true
        presenter.backgroundTap = .dismiss
        presenter.outsideContextTap = .passthrough
        presenter.roundCorners = true
        presenter.cornerRadius = 10
        return presenter
    }

    static func applyUserInterfaceStyle() {
        guard let window = UIApplication.shared.delegate?.window else { return }

        window?.overrideUserInterfaceStyle = AppPrefs.appearance.userInterfaceStyle
        window?.rootViewController?.view.setNeedsLayout()
        window?.rootViewController?.view.setNeedsDisplay()
    }
}

fileprivate extension Appearance {

    static func configureViewAppearance() {
        let windowAppearance = UIWindow.appearance()
        windowAppearance.tintColor = Color.blue

        if let mainWindow = UIApplication.shared.delegate?.window {
            mainWindow?.backgroundColor = Color.white
        }
    }

    static func configureNavigationBarAppearance() {
        let foregroundColor = Color.blue
        let backgroundColor = Color.navigationBarColor
        let backIndicatorImage = ButtonImg.back
        let textAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 18),
            .foregroundColor: Color.black
        ]

        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = backgroundColor
        appearance.shadowColor = Color.gray100
        appearance.titleTextAttributes = textAttributes
        appearance.setBackIndicatorImage(
            backIndicatorImage?.withRenderingMode(.alwaysTemplate),
            transitionMaskImage: backIndicatorImage
        )

        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().tintColor = foregroundColor
        
        let buttonAppearance = UIBarButtonItemAppearance()
        buttonAppearance.normal.titleTextAttributes = [.foregroundColor: foregroundColor]

        let doneButtonAppearance = UIBarButtonItemAppearance()
        doneButtonAppearance.normal.titleTextAttributes = [.foregroundColor: foregroundColor]

        appearance.buttonAppearance = buttonAppearance
        appearance.doneButtonAppearance = doneButtonAppearance
        appearance.backButtonAppearance = buttonAppearance
    }

    static func configureTabBarAppearance() {
        let foregroundColor = Color.blue
        let backgroundColor = Color.navigationBarColor
        let unselectedItemTintColor = Color.gray300
        let backgroundImage = UIImage.image(withColor: backgroundColor, imageSize: CGSize(width: 44, height: 44))

        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithTransparentBackground()
        tabBarAppearance.backgroundColor = backgroundColor
        tabBarAppearance.shadowColor = Color.gray100
        
        // TODO: This isn't working on iOS26 but let's revisit at another time. The idea is to give more separation to each tab.
        if #available(iOS 18.0, *) {
            tabBarAppearance.stackedItemPositioning = .centered
            tabBarAppearance.stackedItemSpacing = 80
            tabBarAppearance.stackedItemWidth = 40
        }
        
        UITabBar.appearance().standardAppearance = tabBarAppearance

        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        }
        
        // set the color and font for the title
        let barAppearance = UITabBar.appearance()
        barAppearance.barTintColor = backgroundColor
        barAppearance.tintColor = foregroundColor
        barAppearance.unselectedItemTintColor = unselectedItemTintColor
        barAppearance.barStyle = .default
        barAppearance.backgroundImage = backgroundImage
        barAppearance.isOpaque = false
        barAppearance.isTranslucent = true
        
    }

    static func configureToolBarAppearance() {
        let foregroundColor = Color.blue
        let backgroundColor = Color.navigationBarColor

        // set the color and font for the title
        let toolBarAppearance = UIToolbar.appearance()
        toolBarAppearance.barTintColor = backgroundColor
        toolBarAppearance.tintColor = foregroundColor
        toolBarAppearance.barStyle = .default
        toolBarAppearance.isOpaque = false
        toolBarAppearance.isTranslucent = true
    }

    static func configureTabBarItemAppearance() {
        //
    }

    static func configureActivityIndicatorAppearance() {
        let appearance = UIActivityIndicatorView.appearance()
        appearance.color = Color.gray300
        appearance.hidesWhenStopped = true
    }
}
