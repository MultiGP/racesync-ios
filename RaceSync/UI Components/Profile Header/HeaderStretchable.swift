//
//  HeaderStretchable.swift
//  RaceSync
//
//  Created by Ignacio Romero Zurbuchen on 2019-12-16.
//  Copyright © 2019 MultiGP Inc. All rights reserved.
//

import UIKit
import RaceSyncAPI

protocol HeaderStretchable {

    var targetHeaderView: StretchableView { get }
    var targetHeaderViewSize: CGSize { get }
    var topLayoutInset: CGFloat { get }

    var anchoredViews: [UIView]? { get }

    func stretchHeaderView(with contentOffset: CGPoint)
}

extension HeaderStretchable where Self: UIViewController {

    func stretchHeaderView(with contentOffset: CGPoint) {

        let topInset = topLayoutInset

        // skipping from doing calculations if not needed
        guard contentOffset.y < -topInset else { return }

        let scrollRatio = contentOffset.y + topInset
        let movingUp: Bool = scrollRatio < 0

        let targetViewSize = targetHeaderViewSize

        let newWidth = movingUp ? targetViewSize.width - scrollRatio*2 : targetViewSize.width
        let newHeight = movingUp ? targetViewSize.height - scrollRatio : targetViewSize.height
        let newX = movingUp ? -(newWidth - targetViewSize.width) / 2 : 0
        let newY = movingUp ? contentOffset.y : -topInset

        let newFrame = CGRect(x: newX, y: newY, width: newWidth , height: newHeight)
        targetHeaderView.changeLayerFrame(newFrame)

        if let anchoredViews = anchoredViews {
            for view in anchoredViews {
                view.layer.frame.origin.y = topInset + UniversalConstants.padding + newY
            }
        }

//        let maxBlurOffset: CGFloat = 120
//        let percentage = min(1, abs(contentOffset.y+topInset) / maxBlurOffset)
//        targetHeaderView.changeLayerEffect(percentage)
    }
}

protocol StretchableView {
    func changeLayerFrame(_ frame: CGRect)
    func changeLayerEffect(_ percentage: CGFloat)
}
