//
//  ZippyqCollectionViewLayout.swift
//  RaceSync
//
//  Created by Ignacio Romero on 2026-08-20.
//  Copyright © 2026 MultiGP Inc. All rights reserved.
//

import UIKit

/// Pins and clips the ZippyQ header without changing the collection view's content geometry.
final class ZippyqCollectionViewLayout: UICollectionViewCompositionalLayout {

    struct RoundSectionConfiguration {
        let displaysMetadata: Bool

        init(viewModel: ZippyqRoundViewModel, isExpanded: Bool) {
            displaysMetadata = isExpanded
                && (viewModel.heatLabel != nil || viewModel.scoringFormatLabel != nil)
        }
    }

    static let headerElementKind = "ZippyqHeader"
    static let roundHeaderElementKind = "ZippyqRoundHeader"

    // MARK: - Public Variables

    var headerCollapseProgress: CGFloat = 0 {
        didSet {
            headerCollapseProgress = min(max(headerCollapseProgress, 0), 1)
            guard headerCollapseProgress != oldValue else { return }
            invalidateLayout()
        }
    }

    let displaysHeader: Bool

    private let expandedHeaderHeight: CGFloat
    private let compactHeaderHeight: CGFloat
    private var accordionTransitionSection: Int?

    private enum Constants {
        static let cellHeight: CGFloat = 60
        static let sectionSpacing: CGFloat = 18 // native spacing between section views in UITableView.grouped
    }

    // MARK: - Initialization

    init(displaysHeader: Bool,
         expandedHeaderHeight: CGFloat,
         compactHeaderHeight: CGFloat,
         headerCollapseProgress: CGFloat,
         roundSectionProvider: @escaping (Int) -> RoundSectionConfiguration?) {
        self.displaysHeader = displaysHeader
        self.expandedHeaderHeight = expandedHeaderHeight
        self.compactHeaderHeight = compactHeaderHeight
        self.headerCollapseProgress = headerCollapseProgress

        let sectionProvider: UICollectionViewCompositionalLayoutSectionProvider = { sectionIndex, _ in
            let itemSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1),
                heightDimension: .absolute(Constants.cellHeight)
            )
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            let group = NSCollectionLayoutGroup.vertical(layoutSize: itemSize, subitems: [item])
            let section = NSCollectionLayoutSection(group: group)

            guard let round = roundSectionProvider(sectionIndex) else { return section }
            section.contentInsets.bottom = Constants.sectionSpacing
            let headerHeight = round.displaysMetadata
                ? ZippyqCollapsableHeaderView.headerHeightWithSubtitle
                : ZippyqCollapsableHeaderView.headerHeight
            let headerSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1),
                heightDimension: .absolute(headerHeight)
            )
            section.boundarySupplementaryItems = [
                NSCollectionLayoutBoundarySupplementaryItem(
                    layoutSize: headerSize,
                    elementKind: ZippyqCollectionViewLayout.roundHeaderElementKind,
                    alignment: .top
                )
            ]
            return section
        }

        let headerSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .absolute(displaysHeader ? expandedHeaderHeight : 0)
        )
        let header = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: headerSize,
            elementKind: ZippyqCollectionViewLayout.headerElementKind,
            alignment: .top
        )
        header.pinToVisibleBounds = true

        let configuration = UICollectionViewCompositionalLayoutConfiguration()
        configuration.boundarySupplementaryItems = [header]
        super.init(sectionProvider: sectionProvider, configuration: configuration)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Layout

    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        return super.layoutAttributesForElements(in: rect)?.map { attributes in
            let attributes = attributes.copy() as! UICollectionViewLayoutAttributes
            updateHeaderAttributes(attributes)
            return attributes
        }
    }

    override func layoutAttributesForSupplementaryView(
        ofKind elementKind: String,
        at indexPath: IndexPath
    ) -> UICollectionViewLayoutAttributes? {
        guard let attributes = super.layoutAttributesForSupplementaryView(ofKind: elementKind, at: indexPath)?
            .copy() as? UICollectionViewLayoutAttributes else {
            return nil
        }
        updateHeaderAttributes(attributes)
        return attributes
    }

    override func initialLayoutAttributesForAppearingItem(
        at itemIndexPath: IndexPath
    ) -> UICollectionViewLayoutAttributes? {
        guard let attributes = super.initialLayoutAttributesForAppearingItem(at: itemIndexPath)?
            .copy() as? UICollectionViewLayoutAttributes else {
            return nil
        }
        if itemIndexPath.section == accordionTransitionSection {
            applyAccordionTransition(to: attributes, at: itemIndexPath)
        }
        return attributes
    }

    override func finalLayoutAttributesForDisappearingItem(
        at itemIndexPath: IndexPath
    ) -> UICollectionViewLayoutAttributes? {
        guard let attributes = super.finalLayoutAttributesForDisappearingItem(at: itemIndexPath)?
            .copy() as? UICollectionViewLayoutAttributes else {
            return nil
        }
        if itemIndexPath.section == accordionTransitionSection {
            applyAccordionTransition(to: attributes, at: itemIndexPath)
        }
        return attributes
    }

    override func finalizeCollectionViewUpdates() {
        super.finalizeCollectionViewUpdates()
        accordionTransitionSection = nil
    }

    func prepareAccordionTransition(forSection section: Int) {
        accordionTransitionSection = section
    }

    func targetContentOffset(forRoundHeaderAt minY: CGFloat) -> CGPoint? {
        guard let collectionView else { return nil }

        let topInset = collectionView.adjustedContentInset.top
        let collapseRange = expandedHeaderHeight - compactHeaderHeight
        var normalizedOffset = minY - compactHeaderHeight
        if normalizedOffset < collapseRange {
            normalizedOffset = 0
        }

        let minimumOffset = -topInset
        let maximumOffset = max(
            minimumOffset,
            collectionView.contentSize.height
                - collectionView.bounds.height
                + collectionView.adjustedContentInset.bottom
        )
        let offset = min(max(normalizedOffset - topInset, minimumOffset), maximumOffset)
        return CGPoint(x: collectionView.contentOffset.x, y: offset)
    }
}

private extension ZippyqCollectionViewLayout {

    func applyAccordionTransition(to attributes: UICollectionViewLayoutAttributes,
                                  at indexPath: IndexPath) {
        let headerIndexPath = IndexPath(item: 0, section: indexPath.section)
        guard let headerAttributes = layoutAttributesForSupplementaryView(
            ofKind: Self.roundHeaderElementKind,
            at: headerIndexPath
        ) else { return }

        attributes.transform = CGAffineTransform(
            translationX: 0,
            y: headerAttributes.frame.maxY - attributes.frame.maxY
        )
        attributes.zIndex = headerAttributes.zIndex - 1
    }

    func updateHeaderAttributes(_ attributes: UICollectionViewLayoutAttributes) {
        guard attributes.representedElementKind == Self.headerElementKind else { return }

        var frame = attributes.frame
        if displaysHeader {
            let collapseRange = expandedHeaderHeight - compactHeaderHeight
            frame.size.height = expandedHeaderHeight - collapseRange * headerCollapseProgress
            if let collectionView {
                frame.origin.y = max(
                    0,
                    collectionView.contentOffset.y + collectionView.adjustedContentInset.top
                )
            }
        } else {
            frame.size.height = 0.01
        }
        attributes.frame = frame
        attributes.zIndex = 1000
    }
}
