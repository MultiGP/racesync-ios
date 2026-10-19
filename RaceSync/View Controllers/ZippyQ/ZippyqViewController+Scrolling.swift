//
//  ZippyqViewController+Scrolling.swift
//  RaceSync
//
//  Copyright © 2026 MultiGP Inc. All rights reserved.
//

import UIKit

// MARK: - ZippyQ Round State + Expansion animation

extension ZippyqViewController {

    func toggleRound(withId roundId: String) {
        if !snapshotController.isRoundExpanded(withId: roundId) {
            expandAndScrollToRound(withId: roundId)
            return
        }

        let currentContentOffset = collectionView.contentOffset
        let wasAtBottom = currentContentOffset.y >= maximumContentOffsetY - 1
        let scrollOffset = currentContentOffset.y + collectionView.adjustedContentInset.top
        let shouldExpandHeader = scrollOffset <= headerCollapseRange
        setVisibleRoundHeader(withId: roundId, expanded: false)
        snapshotController.toggleRound(withId: roundId)
        headerCollapseTracking = .suspended
        applySnapshot(animatingDifferences: true) { [weak self] in
            guard let self else { return }
            collectionView.layoutIfNeeded()

            let targetOffsetY: CGFloat
            if shouldExpandHeader {
                targetOffsetY = -collectionView.adjustedContentInset.top
            } else if wasAtBottom {
                targetOffsetY = maximumContentOffsetY
            } else {
                targetOffsetY = min(
                    maximumContentOffsetY,
                    max(-collectionView.adjustedContentInset.top, currentContentOffset.y)
                )
            }
            let targetContentOffset = CGPoint(x: currentContentOffset.x, y: targetOffsetY)

            UIView.animate(
                withDuration: 0.25,
                delay: 0,
                options: [.allowUserInteraction, .beginFromCurrentState, .curveEaseInOut]
            ) {
                if shouldExpandHeader {
                    self.setHeaderCollapseProgress(0)
                }
                self.collectionView.contentOffset = targetContentOffset
                self.collectionView.layoutIfNeeded()
            } completion: { [weak self] _ in
                self?.headerCollapseTracking = .contentOffset
            }
        }
    }

    func expandAndScrollToRound(cycle: Int32, heat: Int32) {
        expandAndScrollToRound(withId: "\(cycle):\(heat)")
    }

    func expandAndScrollToRound(withId roundId: String) {
        if !snapshotController.isRoundExpanded(withId: roundId) {
            setVisibleRoundHeader(withId: roundId, expanded: true)
            snapshotController.expandRound(withId: roundId)
            applySnapshot(animatingDifferences: true)
            animateScrollRoundToTopAlongsideUpdates(withId: roundId)
            return
        }
        scrollRoundToTop(withId: roundId)
    }

    private func setVisibleRoundHeader(withId roundId: String, expanded: Bool) {
        let sectionIdentifier = SectionIdentifier.round(roundId)
        guard let section = dataSource.snapshot().indexOfSection(sectionIdentifier) else { return }
        let headerIndexPath = IndexPath(item: 0, section: section)
        guard collectionView.indexPathsForVisibleSupplementaryElements(
            ofKind: ZippyqCollectionViewLayout.roundHeaderElementKind
        ).contains(headerIndexPath) else { return }

        let header = collectionView.supplementaryView(
            forElementKind: ZippyqCollectionViewLayout.roundHeaderElementKind,
            at: headerIndexPath
        ) as? ZippyqCollapsableHeaderView
        guard let header else { return }

        (collectionView.collectionViewLayout as? ZippyqCollectionViewLayout)?
            .prepareAccordionTransition(forSection: section)
        header.setExpanded(expanded, animated: true)
    }

    func scrollRoundToTop(withId roundId: String, animated: Bool = true) {
        collectionView.layoutIfNeeded()
        guard let targetOffset = targetContentOffset(forRoundWithId: roundId) else { return }
        collectionView.setContentOffset(targetOffset, animated: animated)
    }

    func animateScrollRoundToTopAlongsideUpdates(withId roundId: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }

            collectionView.layoutIfNeeded()
            guard let targetOffset = targetContentOffset(forRoundWithId: roundId) else { return }

            headerCollapseTracking = .suspended
            let targetHeaderProgress = headerCollapseRange > 0
                ? (targetOffset.y + collectionView.adjustedContentInset.top) / headerCollapseRange
                : headerCollapseProgress

            UIView.animate(
                withDuration: 0.25,
                delay: 0,
                options: [.allowUserInteraction, .beginFromCurrentState, .curveEaseInOut]
            ) {
                self.setHeaderCollapseProgress(targetHeaderProgress)
                self.collectionView.contentOffset = targetOffset
                self.collectionView.layoutIfNeeded()
            } completion: { [weak self] _ in
                self?.headerCollapseTracking = .contentOffset
            }
        }
    }

    private func targetContentOffset(forRoundWithId roundId: String) -> CGPoint? {
        let sectionIdentifier = SectionIdentifier.round(roundId)
        let snapshot = dataSource.snapshot()
        guard let section = snapshot.indexOfSection(sectionIdentifier) else { return nil }

        let headerIndexPath = IndexPath(item: 0, section: section)
        guard let headerAttributes = collectionView.layoutAttributesForSupplementaryElement(
            ofKind: ZippyqCollectionViewLayout.roundHeaderElementKind,
            at: headerIndexPath
        ), let layout = collectionView.collectionViewLayout as? ZippyqCollectionViewLayout,
           var targetOffset = layout.targetContentOffset(
            forRoundHeaderAt: headerAttributes.frame.minY
           ) else { return nil }

        let itemCount = snapshot.itemIdentifiers(inSection: sectionIdentifier).count
        guard itemCount > 0,
              let lastItemAttributes = collectionView.layoutAttributesForItem(
                at: IndexPath(item: itemCount - 1, section: section)
              ) else { return targetOffset }

        let collectionTop = collectionView.convert(collectionView.bounds, to: view).minY
        let visibleBottom: CGFloat
        if let tabBar = tabBarController?.tabBar, !tabBar.isHidden {
            visibleBottom = tabBar.convert(tabBar.bounds, to: view).minY
        } else {
            visibleBottom = collectionView.convert(collectionView.bounds, to: view).maxY
        }
        let visibleHeightAboveTabBar = max(0, visibleBottom - collectionTop)
        let minimumOffsetForVisibleRound = lastItemAttributes.frame.maxY
            + Constants.expandedRoundBottomMargin
            - visibleHeightAboveTabBar

        targetOffset.y = min(
            maximumContentOffsetY,
            max(targetOffset.y, minimumOffsetForVisibleRound)
        )
        return targetOffset
    }

    var maximumContentOffsetY: CGFloat {
        return max(
            -collectionView.adjustedContentInset.top,
            collectionView.collectionViewLayout.collectionViewContentSize.height
                - collectionView.bounds.height
                + collectionView.adjustedContentInset.bottom
        )
    }
}

// MARK: - UICollectionViewDelegate

extension ZippyqViewController: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        guard let identifier = dataSource.itemIdentifier(for: indexPath),
              let user = snapshotController.frequencyViewModel(for: identifier)?.user else {
            return
        }
        showUserProfile(user)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.isDragging || scrollView.isDecelerating {
            lastUserScrollTime = CACurrentMediaTime()
        }
        guard !collectionView.isHidden, shouldDisplaySmartJoinHeader, headerCollapseRange > 0,
              headerCollapseTracking != .suspended else { return }

        let offset = scrollView.contentOffset.y + scrollView.adjustedContentInset.top
        if offset <= 0 {
            headerCollapseTracking = .contentOffset
            setHeaderCollapseProgress(0)
        } else if headerCollapseTracking == .relativeOffset {
            let delta = offset - lastHeaderScrollOffset
            setHeaderCollapseProgress(headerCollapseProgress + delta / headerCollapseRange)
            if headerCollapseProgress >= 1, delta > 0 {
                headerCollapseTracking = .contentOffset
            }
        } else {
            setHeaderCollapseProgress(offset / headerCollapseRange)
        }
        lastHeaderScrollOffset = offset
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        lastUserScrollTime = CACurrentMediaTime()
        lastHeaderScrollOffset = scrollView.contentOffset.y + scrollView.adjustedContentInset.top
    }

    func scrollViewWillEndDragging(_ scrollView: UIScrollView,
                                   withVelocity velocity: CGPoint,
                                   targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        guard headerCollapseRange > 0 else { return }

        let currentOffset = scrollView.contentOffset.y + scrollView.adjustedContentInset.top
        let projectedOffset = targetContentOffset.pointee.y + scrollView.adjustedContentInset.top

        if velocity.y < Constants.fastUpwardScrollVelocity, headerCollapseProgress > 0 {
            headerCollapseTracking = .relativeOffset
            lastHeaderScrollOffset = currentOffset
            let requiredDistance = headerCollapseProgress * headerCollapseRange
            let projectedDistance = max(0, currentOffset - projectedOffset)
            if projectedDistance < requiredDistance {
                targetContentOffset.pointee.y -= requiredDistance - projectedDistance
            }
            return
        }

        if headerCollapseTracking == .relativeOffset {
            guard headerCollapseProgress > 0, headerCollapseProgress < 1 else { return }

            let projectedProgress = headerCollapseProgress
                + (projectedOffset - currentOffset) / headerCollapseRange
            let targetProgress: CGFloat = projectedProgress >= 0.5 ? 1 : 0
            targetContentOffset.pointee.y += (targetProgress - projectedProgress) * headerCollapseRange
            return
        }

        guard projectedOffset > 0, projectedOffset < headerCollapseRange else { return }

        let targetProgress: CGFloat = projectedOffset >= headerCollapseRange / 2 ? 1 : 0
        targetContentOffset.pointee.y = targetProgress * headerCollapseRange
            - scrollView.adjustedContentInset.top
    }
}

extension ZippyqViewController {

    var headerCollapseRange: CGFloat {
        return headerLayoutMetrics?.collapseRange ?? 0
    }

    var expandedHeaderHeight: CGFloat {
        return headerLayoutMetrics?.expandedHeight ?? ZippyqHeaderView.initialLayoutHeight
    }

    func setHeaderCollapseProgress(_ progress: CGFloat) {
        guard shouldDisplaySmartJoinHeader else { return }

        let progress = min(max(progress, 0), 1)
        guard progress != headerCollapseProgress else { return }
        headerCollapseProgress = progress
        headerView?.collapseProgress = headerCollapseProgress
        (collectionView.collectionViewLayout as? ZippyqCollectionViewLayout)?
            .headerCollapseProgress = headerCollapseProgress
    }

    func applyHeaderLayoutMetrics(_ metrics: ZippyqHeaderView.LayoutMetrics) {
        guard headerLayoutMetrics != metrics else { return }
        headerLayoutMetrics = metrics
        collectionView.setCollectionViewLayout(makeCollectionViewLayout(), animated: false)
    }
}
