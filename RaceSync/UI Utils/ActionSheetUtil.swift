//
//  ActionSheetUtil.swift
//  RaceSync
//
//  Created by Ignacio Romero Zurbuchen on 2019-12-05.
//  Copyright © 2019 MultiGP Inc. All rights reserved.
//

import UIKit

class ActionSheetUtil {

    static func presentActionSheet(withTitle title: String, message: String? = nil, buttonTitles: [String], disabledButtonTitles: Set<String> = [], completion: @escaping AlertCompletionBlock, cancel: AlertCompletionBlock? = nil) {
        guard let topMostVC = UIViewController.topMostViewController() else { return }

        let alert = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
        alert.view.tintColor = Color.blue

        for buttonTitle in buttonTitles {
            let action = UIAlertAction(title: buttonTitle, style: .default, handler: completion)
            action.isEnabled = !disabledButtonTitles.contains(buttonTitle)
            alert.addAction(action)
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: cancel))

        topMostVC.present(alert, animated: true)
    }

    static func presentActionSheet(withTitle title: String, message: String? = nil, buttonTitle: String? = nil, completion: @escaping AlertCompletionBlock, cancel: AlertCompletionBlock? = nil) {
        presentActionSheet(
            withTitle: title,
            message: message,
            buttonTitles: [buttonTitle ?? "Ok"],
            completion: completion,
            cancel: cancel
        )
    }

    static func presentDestructiveActionSheet(withTitle title: String, message: String? = nil, destructiveTitle: String? = nil, completion: AlertCompletionBlock? = nil, cancel: AlertCompletionBlock? = nil) {
        guard let topMostVC = UIViewController.topMostViewController() else { return }

        let alert = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
        alert.view.tintColor = Color.blue

        alert.addAction(UIAlertAction(title: destructiveTitle ?? "Ok", style: .destructive, handler: completion))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: cancel))
        
        topMostVC.present(alert, animated: true)
    }
}
