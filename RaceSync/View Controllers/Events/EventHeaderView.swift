//
//  EventHeaderView.swift
//  RaceSync
//
//  Created by Ignacio Romero on 2026-05-19.
//  Copyright © 2026 MultiGP Inc. All rights reserved.
//

import UIKit
import SnapKit

protocol EventHeaderViewDelegate: AnyObject {
    func headerView(_ headerView: EventHeaderView, didSelectDate date: Date)
    func headerView(_ headerView: EventHeaderView, didSelectFilter title: String)
    func headerViewDidTapMapButton(_ headerView: EventHeaderView)
}

// ---------------------------------------------------------------------------
// MARK: – EventHeaderView
// ---------------------------------------------------------------------------

class EventHeaderView: UIView {

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else { return }

        for button in dateStackView.arrangedSubviews.compactMap({ $0 as? UIButton }) {
            let color = button.isSelected ? tintColor : Color.gray50
            button.layer.borderColor = color?.resolvedColor(with: traitCollection).cgColor
        }
    }

    // MARK: - Public

    weak var delegate: EventHeaderViewDelegate?

    var selectedDate: Date? {
        guard selectedDateIndex < dates.count else { return nil }
        return dates[selectedDateIndex]
    }

    var selectedFilterTitle: String? {
        guard let index = selectedFilterIndex, index < filters.count else { return nil }
        return filters[index].0
    }

    func selectFilter(titled title: String) {
        guard let index = filters.firstIndex(where: { $0.0 == title }) else { return }
        selectFilter(at: index, notify: false)
    }
    
    func selectNextDate() {
        let nextIndex = selectedDateIndex + 1
        guard nextIndex < dates.count, let button = dateButton(at: nextIndex) else { return }
        animateButtonPress(button)
        selectDate(at: nextIndex)
    }

    func selectPreviousDate() {
        let prevIndex = selectedDateIndex - 1
        guard prevIndex >= 0, let button = dateButton(at: prevIndex) else { return }
        animateButtonPress(button)
        selectDate(at: prevIndex)
    }

    var isEnabled: Bool = true {
        didSet {
            let allButtons = dateStackView.arrangedSubviews.compactMap { $0 as? UIButton }
                           + filterStackView.arrangedSubviews.compactMap { $0 as? UIButton }
            allButtons.forEach { $0.isEnabled = isEnabled }

            if #available(iOS 26, *) {
                if !isEnabled {
                    dateButton(at: selectedDateIndex)?.isSelected = false
                    dateButton(at: selectedDateIndex)?.setNeedsUpdateConfiguration()
                    if let filterIndex = selectedFilterIndex {
                        filterButton(at: filterIndex)?.isSelected = false
                        filterButton(at: filterIndex)?.setNeedsUpdateConfiguration()
                    }
                } else {
                    dateButton(at: selectedDateIndex)?.isSelected = true
                    dateButton(at: selectedDateIndex)?.setNeedsUpdateConfiguration()
                    if let filterIndex = selectedFilterIndex {
                        filterButton(at: filterIndex)?.isSelected = true
                        filterButton(at: filterIndex)?.setNeedsUpdateConfiguration()
                    }
                }
            } else {
                if !isEnabled {
                    dateButton(at: selectedDateIndex)?.backgroundColor = Color.gray20
                    filterButton(at: selectedFilterIndex ?? -1)?.backgroundColor = Color.gray200
                } else {
                    select(dateButton(at: selectedDateIndex))
                    selectedFilterIndex.map { select(filterButton(at: $0)) }
                }
            }
        }
    }

    // MARK: - Private

    fileprivate let dates: [Date]
    fileprivate let filters: [(String, UIImage?)]
    fileprivate let timezone: TimeZone
    fileprivate let showsMapButton: Bool

    fileprivate var selectedDateIndex: Int = 0
    fileprivate var selectedFilterIndex: Int? = nil

    fileprivate lazy var dateScrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsHorizontalScrollIndicator = false
        sv.alwaysBounceHorizontal = true
        return sv
    }()
    
    fileprivate lazy var mapButton: UIButton = {
        let button = makeFilterButton(title: "", image: SystemImg.map, index: 0)
        button.removeTarget(self, action: #selector(didTapFilterButton(_:)), for: .touchUpInside)
        button.addTarget(self, action: #selector(didTapMapButton(_:)), for: .touchUpInside)
        button.tintColor = tintColor
        return button
    }()

    fileprivate lazy var dateStackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.distribution = .fillEqually
        sv.spacing = Constants.padding
        sv.isLayoutMarginsRelativeArrangement = true
        sv.layoutMargins = UIEdgeInsets(top: Constants.margin/2, left: Constants.margin, bottom: Constants.margin/2, right: Constants.margin)
        sv.tintColor = tintColor
        return sv
    }()

    fileprivate lazy var filterStackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.spacing = Constants.padding
        sv.distribution = .fill
        sv.alignment = .center
        sv.isLayoutMarginsRelativeArrangement = true
        sv.layoutMargins = UIEdgeInsets(top: 0, left: Constants.margin, bottom: Constants.margin/4, right: Constants.margin)

        if #available(iOS 26, *) {
            sv.backgroundColor = UIColor(hex: "f9f9f9")
        }
        return sv
    }()

    fileprivate enum Constants {
        static let padding: CGFloat = 12
        static let margin: CGFloat = 16
        static let dateRowHeight: CGFloat = 60
        static let filterRowHeight: CGFloat = 50
    }

    // MARK: - Init

    init(dates: [Date], filters: [(String, UIImage?)]? = nil, timezone: TimeZone, showsMapButton: Bool = false) {
        self.dates = dates
        self.timezone = timezone
        self.filters = filters ?? []
        self.showsMapButton = showsMapButton
        super.init(frame: .zero)

        setupLayout()
        setupDateButtons()
        setupFilterButtons()

        let initialIndex = Self.initialDateIndex(from: dates, timezone: timezone)
        selectDate(at: initialIndex, notify: false)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Layout

    fileprivate func setupLayout() {
        backgroundColor = Color.viewTint
        addSeparatorLine(.bottom)

        addSubview(dateScrollView)
        dateScrollView.addSubview(dateStackView)

        dateScrollView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.height.equalTo(Constants.dateRowHeight)
        }

        dateStackView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.height.equalToSuperview()
            $0.width.greaterThanOrEqualTo(self.snp.width)
        }
        
        if showsMapButton {
            addSubview(mapButton)
            mapButton.snp.makeConstraints {
                $0.top.equalTo(dateScrollView.snp.bottom)
                $0.trailing.bottom.equalToSuperview()
                $0.width.height.equalTo(Constants.filterRowHeight)
            }
        }

        if !filters.isEmpty {
            addSubview(filterStackView)
            filterStackView.snp.makeConstraints {
                $0.top.equalTo(dateScrollView.snp.bottom)
                $0.leading.bottom.equalToSuperview()
                $0.height.equalTo(Constants.filterRowHeight)
                
                if showsMapButton {
                    $0.trailing.equalTo(mapButton.snp.leading).offset(Constants.margin/2)
                } else {
                    $0.trailing.equalToSuperview()
                }
            }
        }
        
        if showsMapButton {
            bringSubviewToFront(mapButton)
        }
    }

    fileprivate func setupDateButtons() {
        for (index, date) in dates.enumerated() {
            let button = makeDateButton(for: date, index: index)
            dateStackView.addArrangedSubview(button)
        }
    }

    fileprivate func setupFilterButtons() {
        guard !filters.isEmpty else { return }

        for (index, (title, image)) in filters.enumerated() {
            let button = makeFilterButton(title: title, image: image, index: index)
            filterStackView.addArrangedSubview(button)
        }

        // Trailing spacer to keep buttons left-aligned
        let spacer = UIView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        filterStackView.addArrangedSubview(spacer)
    }

    // MARK: - Button Factories

    fileprivate func makeDateButton(for date: Date, index: Int) -> UIButton {
        let button = UIButton(type: .system)
        button.tag = index
        button.titleLabel?.numberOfLines = 2
        button.titleLabel?.textAlignment = .center
        button.addTarget(self, action: #selector(didTapDateButton(_:)), for: .touchUpInside)

        if #available(iOS 26, *) {
            var config = UIButton.Configuration.glass()
            config.attributedTitle = AttributedString(attributedTitle(for: date))
            button.configuration = config
        } else {
            button.setAttributedTitle(attributedTitle(for: date), for: .normal)
            button.contentEdgeInsets = UIEdgeInsets(top: 6, left: 8, bottom: 6, right: 8)
            button.backgroundColor = Color.gray20
            button.layer.cornerRadius = 8
            button.layer.cornerCurve = .continuous
            button.layer.borderWidth = 1
            button.layer.borderColor = Color.gray50.cgColor
        }

        return button
    }

    fileprivate func makeFilterButton(title: String, image: UIImage? = nil, index: Int) -> UIButton {
        
        if #available(iOS 26, *) {
            let button = UIButton(type: .system)
            button.tag = index
            button.setContentHuggingPriority(.defaultHigh, for: .horizontal)
            button.setContentCompressionResistancePriority(.required, for: .horizontal)
            button.addTarget(self, action: #selector(didTapFilterButton(_:)), for: .touchUpInside)
            
            var config = UIButton.Configuration.glass()
            config.title = title
            config.image = image?.withRenderingMode(.alwaysOriginal)
                .withConfiguration(UIImage.SymbolConfiguration(pointSize: 10, weight: .semibold))
            config.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 12, bottom: 10, trailing: 12)
            config.imagePadding = 4
            config.background.backgroundColor = Color.gray100.withAlphaComponent(0.5)
            button.configuration = config

            button.configurationUpdateHandler = { [weak self, title] button in
                guard let self else { return }
                var updated = button.configuration
                let active = button.isSelected && button.isEnabled
                let disabled = !button.isEnabled

                let foregroundColor: UIColor = disabled ? Color.gray100 : (active ? tintColor : Color.black)
                let foregroundImage = updated?.image?.withTintColor(foregroundColor)
                
                updated?.background.backgroundColor = active
                    ? tintColor.withAlphaComponent(0.2)
                    : Color.gray100.withAlphaComponent(0.5)

                updated?.baseForegroundColor = foregroundColor  // tints both image and title
                updated?.image = foregroundImage
                
                updated?.attributedTitle = AttributedString(NSAttributedString(
                    string: title,
                    attributes: [
                        .font: UIFont.systemFont(ofSize: 12, weight: .semibold),
                        .foregroundColor: foregroundColor
                    ]
                ))

                button.configuration = updated
            }
            return button
        } else {
            let button = UIButton(type: .custom)
            button.tag = index
            button.setContentHuggingPriority(.defaultHigh, for: .horizontal)
            button.setContentCompressionResistancePriority(.required, for: .horizontal)
            button.addTarget(self, action: #selector(didTapFilterButton(_:)), for: .touchUpInside)
            
            button.setTitle(title, for: .normal)
            button.setTitleColor(Color.black, for: .normal)
            button.setTitleColor(tintColor, for: .selected)
            button.setTitleColor(Color.gray100, for: .disabled)
            button.tintColor = Color.black  // unselected image color
            button.titleLabel?.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
            button.layer.cornerRadius = 8
            button.layer.cornerCurve = .continuous
            button.backgroundColor = Color.gray100.withAlphaComponent(0.5)
            
            let newImage = image?
                .withConfiguration(UIImage.SymbolConfiguration(pointSize: 10, weight: .semibold))
            button.setImage(newImage?.withTintColor(Color.black, renderingMode: .alwaysOriginal), for: .normal)
            button.setImage(newImage?.withTintColor(tintColor, renderingMode: .alwaysOriginal), for: .selected)
            button.setImage(newImage?.withTintColor(Color.gray100, renderingMode: .alwaysOriginal), for: .disabled)
            
            let spacing: CGFloat = 4
            if newImage != nil {
                button.imageEdgeInsets = UIEdgeInsets(top: 0, left: -spacing/2, bottom: 0, right: spacing)
                button.titleEdgeInsets = UIEdgeInsets(top: 0, left: spacing, bottom: 0, right: -spacing)
                button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12 + spacing*2)
            } else {
                button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
            }
            
            return button
        }
    }
    
    fileprivate func animateButtonPress(_ button: UIButton) {
        UIView.animate(
            withDuration: 0.12,
            animations: { button.transform = CGAffineTransform(scaleX: 0.88, y: 0.88) }
        ) { _ in
            UIView.animate(
                withDuration: 0.4,
                delay: 0,
                usingSpringWithDamping: 0.4,
                initialSpringVelocity: 8,
                options: .allowUserInteraction,
                animations: { button.transform = .identity }
            )
        }
    }

    // MARK: - Selection

    fileprivate func selectDate(at index: Int, notify: Bool = true) {
        guard index < dates.count else { return }

        deselect(dateButton(at: selectedDateIndex))

        selectedDateIndex = index
        select(dateButton(at: index))

        if notify, let date = selectedDate {
            delegate?.headerView(self, didSelectDate: date)
        }
    }

    fileprivate func selectFilter(at index: Int, notify: Bool = true) {
        if let prev = selectedFilterIndex {
            deselect(filterButton(at: prev))
        }

        selectedFilterIndex = index
        select(filterButton(at: index))

        if notify, let title = selectedFilterTitle {
            delegate?.headerView(self, didSelectFilter: title)
        }
    }

    fileprivate func select(_ button: UIButton?) {
        guard let button else { return }

        if #available(iOS 26, *) {
            button.isSelected = true
            button.setNeedsUpdateConfiguration()
        } else {
            if dateStackView.arrangedSubviews.contains(button) {
                button.isSelected = true
                button.setTitleColor(Color.white, for: .normal)
                button.backgroundColor = tintColor
                button.layer.borderColor = tintColor.cgColor
            } else {
                button.isSelected = true  // triggers UIKit image swap
                button.setTitleColor(tintColor, for: .normal)
                button.backgroundColor = tintColor.withAlphaComponent(0.2)
            }
        }
    }

    fileprivate func deselect(_ button: UIButton?) {
        guard let button else { return }

        if #available(iOS 26, *) {
            button.isSelected = false
            button.setNeedsUpdateConfiguration()
        } else {
            if dateStackView.arrangedSubviews.contains(button) {
                button.isSelected = false
                button.setTitleColor(Color.black, for: .normal)
                button.backgroundColor = Color.gray20
                button.layer.borderColor = Color.gray50.cgColor
                if let index = dateStackView.arrangedSubviews.firstIndex(of: button), index < dates.count {
                    button.setAttributedTitle(attributedTitle(for: dates[index]), for: .normal)
                }
            } else {
                button.isSelected = false  // triggers UIKit image swap
                button.setTitleColor(Color.black, for: .normal)
                button.backgroundColor = Color.gray100.withAlphaComponent(0.75)
            }
        }
    }

    private static func initialDateIndex(from dates: [Date], timezone: TimeZone) -> Int {
        guard let initialDate = dates.initialDate(timezone: timezone),
              let index = dates.firstIndex(of: initialDate) else { return 0 }
        return index
    }

    // MARK: - Button Accessors

    fileprivate func dateButton(at index: Int) -> UIButton? {
        dateStackView.arrangedSubviews[safe: index] as? UIButton
    }

    fileprivate func filterButton(at index: Int) -> UIButton? {
        filterStackView.arrangedSubviews[safe: index] as? UIButton
    }

    // MARK: - Actions

    @objc fileprivate func didTapDateButton(_ sender: UIButton) {
        guard sender.tag != selectedDateIndex else { return }
        selectDate(at: sender.tag)
    }

    @objc fileprivate func didTapFilterButton(_ sender: UIButton) {
        guard sender.tag != selectedFilterIndex else { return }
        selectFilter(at: sender.tag)
    }
    
    @objc fileprivate func didTapMapButton(_ sender: UIButton) {
        delegate?.headerViewDidTapMapButton(self)
    }

    // MARK: - Attributed Title

    fileprivate func attributedTitle(for date: Date) -> NSAttributedString {
        let f = DateFormatter()
        f.timeZone = timezone

        f.dateFormat = "EEE"
        let dayName = f.string(from: date)

        f.dateFormat = "MMM d"
        let dayDate = f.string(from: date)

        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center

        let result = NSMutableAttributedString()
        result.append(NSAttributedString(string: dayName + "\n", attributes: [
            .font: UIFont.systemFont(ofSize: 12, weight: .semibold),
            .paragraphStyle: paragraph
        ]))
        result.append(NSAttributedString(string: dayDate, attributes: [
            .font: UIFont.systemFont(ofSize: 11, weight: .regular),
            .paragraphStyle: paragraph
        ]))
        return result
    }
}

// ---------------------------------------------------------------------------
// MARK: – Array Extensions
// ---------------------------------------------------------------------------

fileprivate extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

public extension Array where Element == Date {
    func initialDate(timezone: TimeZone) -> Date? {
        var calendar = Calendar.current
        calendar.timeZone = timezone
        let today = Date()
        return first(where: { calendar.isDate($0, inSameDayAs: today) }) ?? first
    }
}
