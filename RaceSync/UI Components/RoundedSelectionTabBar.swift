//
//  RoundedSelectionTabBar.swift
//  RaceSync
//
//  Created by Ignacio Romero Zurbuchen on 2025-08-10.
//  Copyright © 2025 MultiGP Inc. All rights reserved.
//

import UIKit

class RoundedSelectionTabBar: UITabBar {

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSelectionBackground()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupSelectionBackground()
    }

    fileprivate func setupSelectionBackground() {
        selectionBackground.backgroundColor = Color.gray50.withAlphaComponent(0.5)
        selectionBackground.layer.cornerRadius = 8
        selectionBackground.layer.masksToBounds = true
        insertSubview(selectionBackground, at: 0) // Behind tab bar items
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateSelectionFrame(animated: false)
    }

    func updateSelectionFrame(animated: Bool) {
        guard let items = items, let selectedItem = selectedItem,
              let index = items.firstIndex(of: selectedItem),
              let tabBarButton = orderedTabBarButtons[safe: index] else { return }

        let inset: CGFloat = 16
        var targetFrame = tabBarButton.frame.insetBy(dx: inset, dy: inset/8)
        targetFrame.size.height += inset/4

        if animated {
            UIView.animate(withDuration: 0.2, delay: 0, options: [.curveEaseOut, .beginFromCurrentState]) {
                self.selectionBackground.frame = targetFrame
            } completion: { finished in
                //
            }
        } else {
            selectionBackground.frame = targetFrame
        }
    }

    fileprivate let selectionBackground = UIView()
}

extension UITabBar {
    var orderedTabBarButtons: [UIControl] {
        return subviews
            .compactMap { $0 as? UIControl }
            .sorted { $0.frame.origin.x < $1.frame.origin.x }
    }
}
