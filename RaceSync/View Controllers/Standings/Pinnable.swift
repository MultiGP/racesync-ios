//
//  Pinnable.swift
//  RaceSync
//
//  Created by Ignacio Romero Zurbuchen on 2025-08-26.
//  Copyright © 2025 MultiGP Inc. All rights reserved.
//

import Foundation
import UIKit

protocol Pinnable where Self: UIViewController {
    var tableView: UITableView { get }
    var isSearching: Bool { get }

    var pinnedView: UIView? { get set }
    var cachedPinnedIndexPath: IndexPath? { get set }

    func pinnedCellIndexPath() -> IndexPath?
    func cellForRow(at indexPath: IndexPath) -> UITableViewCell

    func layoutPinnedCell()
    func invalidatePinnedCell()
}

extension Pinnable {

    func layoutPinnedCell() {
        guard !isSearching else { return }

        guard let indexPath = pinnedCellIndexPath() else { return }
        guard let _ = tableView.superview else { return }

        let cellRect = tableView.rectForRow(at: indexPath)
        let topInset = tableView.contentInset.top
        let bottomInset = tableView.contentInset.bottom
        let contentOffsetY = tableView.contentOffset.y
        let visibleHeight = tableView.bounds.height - topInset - bottomInset
        let tabBarHeight = tabBarController?.tabBar.frame.size.height ?? 0

        let targetTopOffsetY = cellRect.minY - topInset
        let targetBottomOffsetY = cellRect.maxY + tabBarHeight - visibleHeight

        let cellHeight = tableView.delegate?.tableView?(tableView, heightForRowAt: indexPath) ?? cellRect.height
        let cellWidth = tableView.frame.width

        let topPinY = tableView.frame.minY
        let bottomPinY = tableView.frame.maxY - bottomInset - cellHeight - tabBarHeight

        // Pin to top
        if contentOffsetY >= targetTopOffsetY {
            showPinnedCell(at: topPinY, indexPath: indexPath, size: CGSize(width: cellWidth, height: cellHeight))

        // Pin to bottom
        } else if contentOffsetY <= targetBottomOffsetY {
            showPinnedCell(at: bottomPinY, indexPath: indexPath, size: CGSize(width: cellWidth, height: cellHeight))
        } else {
            removePinnedCell()
        }
    }

    fileprivate func showPinnedCell(at y: CGFloat, indexPath: IndexPath, size: CGSize) {
        if pinnedView == nil {
            let snapshot = createSnapshotFromCell(forRowAt: indexPath)
            pinnedView = snapshot
            pinnedView?.frame = CGRect(origin: CGPoint(x: 0, y: y), size: size)
            pinnedView?.layer.zPosition = 999
        } else {
            pinnedView?.frame.origin.y = y
        }

        if let pinnedView = pinnedView, pinnedView.superview == nil {
            view.insertSubview(pinnedView, aboveSubview: tableView)
        }
    }

    fileprivate func createSnapshotFromCell(forRowAt indexPath: IndexPath) -> UIView? {
        let cellWidth = tableView.bounds.width
        let cellHeight = tableView.delegate?.tableView?(tableView, heightForRowAt: indexPath) ?? tableView.rowHeight

        let cell = cellForRow(at: indexPath)
        cell.frame = CGRect(x: 0, y: 0, width: cellWidth, height: cellHeight)

        // Force the cell to layout its subviews
        cell.setNeedsLayout()
        cell.layoutIfNeeded()

        // Create a snapshot of the cell’s current rendered content
        guard let snapshot = cell.snapshotView(afterScreenUpdates: true) else {
            return nil
        }
        snapshot.tag = indexPath.row

        snapshot.addTapAction {
            guard let indexPath = self.pinnedCellIndexPath() else { return }
            self.tableView.scrollToRow(at: indexPath, at: .middle, animated: true)
        }

        return snapshot
    }

    fileprivate func removePinnedCell() {
        guard let view = pinnedView else { return }

        if view.superview != nil {
            view.removeFromSuperview()
        }

        pinnedView = nil
    }

    func invalidatePinnedCell() {
        cachedPinnedIndexPath = nil
        removePinnedCell()

        if pinnedCellIndexPath() != nil {
            layoutPinnedCell()
        }
    }
}

fileprivate class TapHandler {
    let action: () -> Void
    init(_ action: @escaping () -> Void) { self.action = action }
    @objc func invoke() { action() }
}

fileprivate extension UIView {
    func addTapAction(_ action: @escaping () -> Void) {
        let handler = TapHandler(action)
        let tap = UITapGestureRecognizer(target: handler, action: #selector(TapHandler.invoke))
        self.addGestureRecognizer(tap)
        self.isUserInteractionEnabled = true
        // retain handler
        objc_setAssociatedObject(self, "[\(arc4random())]", handler, .OBJC_ASSOCIATION_RETAIN)
    }
}
