//
//  SliderTableViewHeaderView.swift
//  RaceSync
//
//  Created by Ignacio Romero Zurbuchen on 2025-09-27.
//  Copyright © 2025 MultiGP Inc. All rights reserved.
//

import UIKit
import SnapKit

protocol SliderTableViewHeaderViewDelegate: AnyObject {
    func sliderNumberOfItems(_ slider: SliderTableViewHeaderView) -> Int
    func slider(_ slider: SliderTableViewHeaderView, imageFor view: UIImageView, at index: Int)
    func slider(_ slider: SliderTableViewHeaderView, didSelectImageAt index: Int)
}

class SliderTableViewHeaderView: UIView {

    // MARK: - Public

    var isCarouselEnabled: Bool = true

    weak var delegate: SliderTableViewHeaderViewDelegate?

    static var height: CGFloat {
        UIScreen.main.bounds.height / 4
    }

    // MARK: - Private

    fileprivate var totalElements: Int = 0
    fileprivate var numberOfItems: Int = 0
    fileprivate var currentIndex: Int = 0

    fileprivate lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = Constants.spacing
        layout.sectionInset = .zero

        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.showsHorizontalScrollIndicator = false
        view.decelerationRate = .fast
        view.backgroundColor = .clear
        view.delegate = self
        view.dataSource = self
        view.register(SliderImageCell.self, forCellWithReuseIdentifier: SliderImageCell.identifier)
        return view
    }()

    fileprivate lazy var pageControl: UIPageControl = {
        let control = UIPageControl()
        control.addTarget(self, action: #selector(didTapPageControl), for: .valueChanged)
        control.currentPageIndicatorTintColor = Color.gray400
        control.pageIndicatorTintColor = Color.gray200
        control.hidesForSinglePage = true
        return control
    }()

    fileprivate var autoScrollTimer: Timer?

    // MARK: - Constants

    fileprivate enum Constants {
        static let spacing: CGFloat = 20
        static let cellRatio: CGFloat = 0.7 // how much of width each cell takes
    }

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Public Reload

    func reloadData() {
        guard let delegate = delegate else { return }
        let count = delegate.sliderNumberOfItems(self)
        guard count > 0 else { return }

        let minimumCount = 3

        numberOfItems = count
        totalElements = count * minimumCount // repeat 3x for infinite scroll illusion
        pageControl.numberOfPages = count
        currentIndex = count // start in the middle block

        if count < minimumCount {
            isCarouselEnabled = false // disable it if no enough elements
        }

        collectionView.reloadData()

        DispatchQueue.main.async {
            self.scrollToIndex(self.currentIndex, animated: false)

            if self.isCarouselEnabled {
                self.startAutoScroll()
            }
        }
    }

    // MARK: - Setup

    fileprivate func setupLayout() {

        backgroundColor = Color.gray50

        addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(Self.height)
        }

        addSubview(pageControl)
        pageControl.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().offset(-Constants.spacing/5)
        }

        let separatorLine = UIView()
        separatorLine.backgroundColor = Color.gray100
        addSubview(separatorLine)
        separatorLine.snp.makeConstraints {
            $0.height.equalTo(0.5)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(self.snp.bottom)
        }
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric, height: Self.height)
    }

    override func layoutSubviews() {
        frame.size.height = Self.height
        super.layoutSubviews()
    }

    fileprivate func startAutoScroll(interval: TimeInterval = 3.0) {
        stopAutoScroll() // in case it's already running

        autoScrollTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.scrollToNextIndex()
        }
    }

    fileprivate func stopAutoScroll() {
        autoScrollTimer?.invalidate()
        autoScrollTimer = nil
    }

    fileprivate func scrollToIndex(_ index: Int, animated: Bool = true) {
        let indexPath = IndexPath(item: index, section: 0)
        collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: animated)

        currentIndex = index
        pageControl.currentPage = index % numberOfItems
    }

    fileprivate func scrollToNextIndex() {
        guard numberOfItems > 0 else { return }

        let nextIndex = (currentIndex + 1) % totalElements
        scrollToIndex(nextIndex, animated: true)
    }

    // MARK: - Actions

    @objc fileprivate func didTapPageControl(_ sender: UIPageControl) {
        stopAutoScroll()

        let index = sender.currentPage + numberOfItems // map to middle block
        scrollToIndex(index, animated: true)
    }
}

// MARK: - UICollectionViewDataSource & Delegate

extension SliderTableViewHeaderView: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return totalElements
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SliderImageCell.identifier, for: indexPath) as? SliderImageCell else {
            return UICollectionViewCell()
        }

        if let delegate = delegate {
            let index = indexPath.item % numberOfItems
            delegate.slider(self, imageFor: cell.imageView, at: index)
        }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.bounds.width * Constants.cellRatio
        let height = collectionView.bounds.height * Constants.cellRatio
        return CGSize(width: width, height: height)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        stopAutoScroll()

        if let cell = collectionView.cellForItem(at: indexPath) {
            UIView.animate(withDuration: 0.1,
                           animations: {
                               cell.transform = CGAffineTransform(scaleX: 0.96, y: 0.96)
                           },
                           completion: { _ in
                               UIView.animate(withDuration: 0.1) {
                                   cell.transform = .identity
                               }
                           })
        }

        let selectedIdx = indexPath.item % numberOfItems
        let currentIdx = currentIndex % numberOfItems

        if selectedIdx == currentIdx {
            delegate?.slider(self, didSelectImageAt: selectedIdx)
        } else {
            scrollToIndex(indexPath.item, animated: true)
        }
    }
}

extension SliderTableViewHeaderView: UIScrollViewDelegate {

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        stopAutoScroll()
    }

    func scrollViewWillEndDragging(_ scrollView: UIScrollView,
                                   withVelocity velocity: CGPoint,
                                   targetContentOffset: UnsafeMutablePointer<CGPoint>) {

        guard let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout else { return }

        let cellWidth = collectionView.bounds.width * Constants.cellRatio
        let pageWidth = cellWidth + layout.minimumLineSpacing
        let tolerance = 0.5

        // Where the scroll would naturally stop
        let estimatedIndex = scrollView.contentOffset.x / pageWidth
        var index = round(estimatedIndex)

        if velocity.x > 0 { // force forward
            if velocity.x < tolerance {
                index = ceil(estimatedIndex + 1)
            } else {
                index = floor(estimatedIndex + 1)
            }
        } else if velocity.x < 0 { // force backward
            if velocity.x > -tolerance {
                index = floor(estimatedIndex - 1)
            } else {
                index = ceil(estimatedIndex - 1)
            }
        }

        // Clamp index
        let maxIndex = totalElements - 1
        let newIndex = max(0, min(Int(index), maxIndex))

        // Offset to center the cell
        let newOffset = CGFloat(newIndex) * pageWidth - (collectionView.bounds.width - cellWidth)/2
        targetContentOffset.pointee = CGPoint(x: newOffset, y: 0)

        // Update state
        currentIndex = newIndex
        pageControl.currentPage = newIndex % numberOfItems
    }


    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        adjustInfiniteScroll()
    }

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        adjustInfiniteScroll()
    }

    fileprivate func adjustInfiniteScroll() {
        let center = collectionView.center
        let point = convert(center, to: collectionView)

        if let indexPath = collectionView.indexPathForItem(at: point) {
            currentIndex = indexPath.item
            pageControl.currentPage = currentIndex % numberOfItems

            // Reset to middle block if scrolled too far
            if currentIndex < numberOfItems || currentIndex >= 2*numberOfItems {
                let newIndex = numberOfItems + (currentIndex % numberOfItems)
                let indexPath = IndexPath(item: newIndex, section: 0)
                collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: false)
                currentIndex = newIndex
            }
        }
    }
}

// MARK: - Custom Cell

private final class SliderImageCell: UICollectionViewCell {

    // MARK: - Public Variables

    static let identifier = "SliderImageCell"

    let imageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        view.layer.cornerRadius = 12
        view.layer.masksToBounds = true
        return view
    }()

    // MARK: - Private Variables

    fileprivate let shadowView: UIView = {
        let view = UIView()
        view.layer.shadowRadius = 2
        view.layer.shadowOpacity = 0.35
        view.layer.shadowColor = Color.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 2.0)
        view.layer.masksToBounds = false
        return view
    }()

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Layout

    fileprivate func setupLayout() {
        contentView.addSubview(shadowView)
        shadowView.snp.makeConstraints { $0.edges.equalToSuperview() }

        shadowView.addSubview(imageView)
        imageView.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let cornerRadius: CGFloat = 12
        shadowView.layer.cornerRadius = cornerRadius
        shadowView.layer.shadowPath = UIBezierPath(roundedRect: shadowView.bounds, cornerRadius: cornerRadius).cgPath
    }
}

