//
//  UIBarButtonItem+Extensions.swift
//  RaceSync
//
//  Created by Ignacio Romero on 2026-05-14.
//  Copyright © 2026 MultiGP Inc. All rights reserved.
//

import UIKit

typealias BarButtonAction = (image: UIImage?, selector: Selector, tag: Int)

extension UIBarButtonItem {
    
    class func spacer(width: CGFloat = 0) -> Self {
        let item = Self(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        item.width = width
        return item
    }
    
    // Useful for versions of iOS previous to iOS26, where the UIBarButtonItem needed to be laid out
    // separately without too much space in between
    static func stackedBarButtonItem(for actions: [BarButtonAction], target: AnyObject?, reversed: Bool = true) -> UIBarButtonItem {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 12
        stack.alignment = .center

        let orderedActions = reversed ? actions.indices.reversed().map { actions[$0] } : actions

        for action in orderedActions {
            let button = UIButton(type: .system)
            button.tag = action.tag
            button.setImage(action.image, for: .normal)
            button.addTarget(target, action: action.selector, for: .touchUpInside)
            button.frame = CGRect(origin: .zero, size: CGSize(width: 32, height: 32))
            stack.addArrangedSubview(button)
        }

        return UIBarButtonItem(customView: stack)
    }
}
