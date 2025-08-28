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
    func pinnedCellForRow(at indexPath: IndexPath) -> UITableViewCell

    func layoutPinnedCell()
    func invalidatePinnedCell()
}

extension Pinnable {

    func layoutPinnedCell() {
        guard !isSearching,
              let indexPath = pinnedCellIndexPath(),
              let superview = tableView.superview else { return }

        let cellRect = tableView.rectForRow(at: indexPath)
        let cellSuperRect = tableView.convert(cellRect, to: superview)

        let topInset = tableView.adjustedContentInset.top
        let bottomInset = tableView.adjustedContentInset.bottom

        let topPinY = tableView.frame.minY + topInset
        let bottomPinY = tableView.frame.maxY - bottomInset - cellSuperRect.height

        // Check whether the cell is scrolled past top or bottom
        if cellSuperRect.minY <= topPinY {
            showPinnedCell(at: topPinY, indexPath: indexPath, size: cellSuperRect.size)
        } else if cellSuperRect.maxY >= bottomPinY + cellSuperRect.height {
            showPinnedCell(at: bottomPinY, indexPath: indexPath, size: cellSuperRect.size)
        } else {
            removePinnedCell()
        }
    }

    fileprivate func showPinnedCell(at y: CGFloat, indexPath: IndexPath, size: CGSize) {
        if pinnedView == nil {
            pinnedView = createImageViewFromCell(forRowAt: indexPath)
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
        let cellHeight = tableView.rectForRow(at: indexPath).height

        let cell = pinnedCellForRow(at: indexPath)
        cell.frame = CGRect(x: 0, y: 0, width: cellWidth, height: cellHeight)

        cell.setNeedsLayout()
        cell.layoutIfNeeded()

        // Wrap in container to preserve layout (optional but cleaner)
        let container = UIView(frame: cell.bounds)
        container.addSubview(cell)

        guard let snapshot = container.snapshotView(afterScreenUpdates: true) else { return nil }
        snapshot.tag = indexPath.row
        snapshot.addTapAction { [weak self] in
            guard let self = self,
                  let pinnedIndexPath = self.pinnedCellIndexPath() else { return }
            self.tableView.scrollToRow(at: pinnedIndexPath, at: .middle, animated: true)
        }

        return snapshot
    }

    fileprivate func createImageViewFromCell(forRowAt indexPath: IndexPath) -> UIView? {
        let cellWidth = tableView.bounds.width
        let cellHeight = tableView.rectForRow(at: indexPath).height

        let cell = pinnedCellForRow(at: indexPath)
        cell.frame = CGRect(x: 0, y: 0, width: cellWidth, height: cellHeight)

        // important to call, since it may have not laid correctly when dequeued
        cell.setNeedsLayout()
        cell.layoutIfNeeded()

        // Render into an image
        let renderer = UIGraphicsImageRenderer(size: cell.bounds.size)
        let image = renderer.image { context in
            cell.layer.render(in: context.cgContext)
        }

        // the cell may have been added to the view hierarchy, so let's remove it
        cell.removeFromSuperview()

        // Wrap in UIImageView so we return a UIView
        let imageView = UIImageView(image: image)
        imageView.frame = cell.bounds
        imageView.tag = indexPath.row
        imageView.isUserInteractionEnabled = true

        imageView.addTapAction { [weak self] in
            guard let self = self,
                  let pinnedIndexPath = self.pinnedCellIndexPath() else { return }
            self.tableView.scrollToRow(at: pinnedIndexPath, at: .middle, animated: true)
        }

        return imageView
    }

    fileprivate func removePinnedCell() {
        pinnedView?.removeFromSuperview()
    }

    func invalidatePinnedCell() {
        removePinnedCell()

        cachedPinnedIndexPath = nil
        pinnedView = nil

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
