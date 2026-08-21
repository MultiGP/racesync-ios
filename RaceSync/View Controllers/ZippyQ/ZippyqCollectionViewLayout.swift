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

    // MARK: - Public Variables

    var headerCollapseProgress: CGFloat = 0 {
        didSet {
            headerCollapseProgress = min(max(headerCollapseProgress, 0), 1)
            guard headerCollapseProgress != oldValue else { return }
            invalidateLayout()
        }
    }

    let displaysHeader: Bool

    private let headerElementKind: String
    private let expandedHeaderHeight: CGFloat
    private let compactHeaderHeight: CGFloat

    // MARK: - Initialization

    init(headerElementKind: String,
         displaysHeader: Bool,
         expandedHeaderHeight: CGFloat,
         compactHeaderHeight: CGFloat,
         sectionProvider: @escaping UICollectionViewCompositionalLayoutSectionProvider,
         configuration: UICollectionViewCompositionalLayoutConfiguration) {
        self.headerElementKind = headerElementKind
        self.displaysHeader = displaysHeader
        self.expandedHeaderHeight = expandedHeaderHeight
        self.compactHeaderHeight = compactHeaderHeight
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
}

private extension ZippyqCollectionViewLayout {

    func updateHeaderAttributes(_ attributes: UICollectionViewLayoutAttributes) {
        guard attributes.representedElementKind == headerElementKind else { return }

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
