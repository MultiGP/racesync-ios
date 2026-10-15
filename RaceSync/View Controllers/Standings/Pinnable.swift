//
//  Pinnable.swift
//  RaceSync
//
//  Created by Ignacio Romero Zurbuchen on 2025-08-26.
//  Copyright © 2025 MultiGP Inc. All rights reserved.
//

import UIKit

protocol Pinnable where Self: UIViewController {
    var tableView: UITableView { get }
    var pinnedView: UIView? { get set }
    var cachedPinnedIndexPath: IndexPath? { get set }

    func canPinView() -> Bool
    func pinnedViewIndexPath() -> IndexPath?

    func registerPinnedView<T: UITableViewCell>(viewType: T.Type)
    func configure<T: UITableViewCell>(_ view: T, forRowAt indexPath: IndexPath)
    func configurePinned<T: UITableViewCell>(_ view: T, forRowAt indexPath: IndexPath)
    func pinnedViewBottomInset() -> CGFloat
    func layoutPinnedView()
    func invalidatePinnedView()
}
extension Pinnable {

    // MARK: - Public

    func registerPinnedView<T: UITableViewCell>(viewType: T.Type) {
        tableView.register(cellType: viewType, identifier: pinnedCellIdentifier())
    }

    func configurePinned<T: UITableViewCell>(_ view: T, forRowAt indexPath: IndexPath) {
        configure(view, forRowAt: indexPath)
    }

    func pinnedViewBottomInset() -> CGFloat {
        return tableView.adjustedContentInset.bottom
    }

    func layoutPinnedView() {
        guard canPinView(),
              let indexPath = pinnedViewIndexPath(),
              let superview = tableView.superview else { return }

        let cellRect = tableView.rectForRow(at: indexPath)
        let cellSuperRect = tableView.convert(cellRect, to: superview)

        let topInset = tableView.adjustedContentInset.top
        let bottomInset = pinnedViewBottomInset()

        let topPinY = tableView.frame.minY + topInset
        let bottomPinY = tableView.frame.maxY - bottomInset - cellSuperRect.height

        // Check whether the cell is scrolled past top or bottom
        if cellSuperRect.minY <= topPinY {
            showPinnedCell(at: topPinY, indexPath: indexPath, size: cellSuperRect.size)
        } else if cellSuperRect.maxY >= bottomPinY + cellSuperRect.height {
            showPinnedCell(at: bottomPinY, indexPath: indexPath, size: cellSuperRect.size)
        } else {
            if pinnedView?.superview != nil {
                configureOriginalCell(at: indexPath, asPinned: true)
            }
            removePinnedCell()
        }
    }

    func invalidatePinnedView() {
        removePinnedCell()

        cachedPinnedIndexPath = nil
        pinnedView = nil

        if pinnedViewIndexPath() != nil {
            layoutPinnedView()
        }
    }

    func refreshPinnedViewIfAppearanceChanged(from previousTraitCollection: UITraitCollection?) {
        guard traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else { return }

        // Wait until UIKit has propagated the new traits and resolved dynamic
        // colors before rendering the replacement bitmap.
        DispatchQueue.main.async { [weak self] in
            self?.invalidatePinnedView()
        }
    }

    // MARK: - Private

    fileprivate func showPinnedCell(at y: CGFloat, indexPath: IndexPath, size: CGSize) {
        if pinnedView == nil {
            pinnedView = createImageViewFromCell(forRowAt: indexPath)
            pinnedView?.frame = CGRect(origin: CGPoint(x: 0, y: y), size: size)
            pinnedView?.layer.zPosition = 999
        } else {
            pinnedView?.frame.origin.y = y
        }

        if let pinnedView = pinnedView, pinnedView.superview == nil {
            configureOriginalCell(at: indexPath, asPinned: false)
            view.insertSubview(pinnedView, aboveSubview: tableView)
        }
    }

    fileprivate func configureOriginalCell(at indexPath: IndexPath, asPinned: Bool) {
        guard let cell = tableView.cellForRow(at: indexPath) else { return }

        if asPinned {
            configurePinned(cell, forRowAt: indexPath)
        } else {
            configure(cell, forRowAt: indexPath)
        }

        cell.setNeedsLayout()
        cell.layoutIfNeeded()
    }

    fileprivate func createSnapshotFromCell(forRowAt indexPath: IndexPath) -> UIView? {
        let cellWidth = tableView.bounds.width
        let cellHeight = tableView.rectForRow(at: indexPath).height
        let cellSize = CGSize(width: cellWidth, height: cellHeight)

        guard let renderingContext = pinnedCellForRow(at: indexPath, size: cellSize) else { return nil }
        let cell = renderingContext.cell

        let snapshot = withExtendedLifetime(renderingContext.renderingTable) {
            cell.snapshotView(afterScreenUpdates: true)
        }
        guard let snapshot else { return nil }
        snapshot.tag = indexPath.row
        snapshot.addTapAction { [weak self] in
            guard let self = self,
                  let pinnedIndexPath = self.pinnedViewIndexPath() else { return }
            self.tableView.scrollToRow(at: pinnedIndexPath, at: .middle, animated: true)
        }

        return snapshot
    }

    fileprivate func createImageViewFromCell(forRowAt indexPath: IndexPath) -> UIView? {
        let cellWidth = tableView.bounds.width
        let cellHeight = tableView.rectForRow(at: indexPath).height
        let cellSize = CGSize(width: cellWidth, height: cellHeight)

        guard let renderingContext = pinnedCellForRow(at: indexPath, size: cellSize) else { return nil }
        let cell = renderingContext.cell

        // Render into an image
        let renderer = UIGraphicsImageRenderer(size: cell.bounds.size)
        let image = withExtendedLifetime(renderingContext.renderingTable) {
            renderer.image { context in
                cell.layer.render(in: context.cgContext)
            }
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
                  let pinnedIndexPath = self.pinnedViewIndexPath() else { return }
            self.tableView.scrollToRow(at: pinnedIndexPath, at: .middle, animated: true)
        }

        return imageView
    }

    fileprivate func pinnedCellForRow(
        at indexPath: IndexPath,
        size: CGSize
    ) -> (cell: UITableViewCell, renderingTable: UITableView)? {
        // This cell is created manually for bitmap rendering, independently of
        // the table view's data-source request.
        guard let cell = tableView.dequeueReusableCell(withIdentifier: pinnedCellIdentifier()) else {
            return nil
        }
        configurePinned(cell, forRowAt: indexPath)

        // Give the rendering cell a real table-view layout pass. A standalone
        // UITableViewCell does not receive the same margins and accessory-view
        // geometry as a cell managed by a table view.
        let renderingTable = UITableView(frame: CGRect(origin: .zero, size: size), style: tableView.style)
        renderingTable.overrideUserInterfaceStyle = tableView.traitCollection.userInterfaceStyle
        renderingTable.separatorStyle = .none
        renderingTable.layoutMargins = tableView.layoutMargins
        renderingTable.rowHeight = size.height

        let renderingDataSource = PinnedCellRenderingDataSource(cell: cell)
        renderingTable.dataSource = renderingDataSource
        renderingTable.reloadData()
        renderingTable.layoutIfNeeded()
        cell.layoutIfNeeded()

        // Return the table with the cell so its trait environment remains alive
        // until after the caller has captured the snapshot or bitmap.
        return (cell, renderingTable)
    }

    fileprivate func removePinnedCell() {
        pinnedView?.removeFromSuperview()
    }

    fileprivate func pinnedCellIdentifier() -> String {
        return "\(String(describing: type(of: self))).\(String(describing: Pinnable.self))"
    }
}

fileprivate final class PinnedCellRenderingDataSource: NSObject, UITableViewDataSource {
    private let cell: UITableViewCell

    init(cell: UITableViewCell) {
        self.cell = cell
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return cell
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

