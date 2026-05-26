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
}

// ---------------------------------------------------------------------------
// MARK: – EventHeaderView
// ---------------------------------------------------------------------------

class EventHeaderView: UIView {

    // MARK: - Public

    weak var delegate: EventHeaderViewDelegate?

    var selectedDate: Date? {
        guard selectedDateIndex < dates.count else { return nil }
        return dates[selectedDateIndex]
    }

    var selectedFilterTitle: String? {
        guard let index = selectedFilterIndex, index < filters.count else { return nil }
        return filters[index]
    }
    
    func selectFilter(titled title: String) {
        guard let index = filters.firstIndex(of: title) else { return }
        selectFilter(at: index, notify: false)
    }
    
    var isEnabled: Bool = true {
        didSet {
            let allButtons = dateStackView.arrangedSubviews.compactMap { $0 as? UIButton }
                           + filterStackView.arrangedSubviews.compactMap { $0 as? UIButton }
            allButtons.forEach { $0.isEnabled = isEnabled }

            if #available(iOS 26, *) {
                if !isEnabled {
                    // Strip selected state so glass loses its tint
                    dateButton(at: selectedDateIndex)?.isSelected = false
                    dateButton(at: selectedDateIndex)?.setNeedsUpdateConfiguration()
                    if let filterIndex = selectedFilterIndex {
                        filterButton(at: filterIndex)?.isSelected = false
                        filterButton(at: filterIndex)?.setNeedsUpdateConfiguration()
                    }
                } else {
                    // Restore selected appearance
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
    fileprivate let filters: [String]
    fileprivate let timezone: TimeZone

    fileprivate var selectedDateIndex: Int = 0
    fileprivate var selectedFilterIndex: Int? = nil

    fileprivate lazy var dateScrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsHorizontalScrollIndicator = false
        sv.alwaysBounceHorizontal = true
        return sv
    }()

    fileprivate lazy var dateStackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.distribution = .fillEqually
        sv.spacing = 12
        sv.isLayoutMarginsRelativeArrangement = true
        sv.layoutMargins = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
        sv.tintColor = tintColor
        return sv
    }()

    fileprivate lazy var filterStackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.spacing = 12
        sv.distribution = .fill
        sv.alignment = .center
        sv.isLayoutMarginsRelativeArrangement = true
        sv.layoutMargins = UIEdgeInsets(top: 0, left: 16, bottom: 4, right: 16)
        sv.backgroundColor = UIColor(hex: "f7f7f7")
        return sv
    }()

    fileprivate enum Constants {
        static let dateRowHeight: CGFloat = 60
        static let filterRowHeight: CGFloat = 36
    }

    // MARK: - Init

    init(dates: [Date], timezone: TimeZone, filters: [String]? = nil) {
        self.dates = dates
        self.filters = filters ?? []
        self.timezone = timezone
        super.init(frame: .zero)
        
        setupLayout()
        setupDateButtons()
        setupFilterButtons()
        
        selectDate(at: 0, notify: false) // TODO: select current date, if in between of the range of dates
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Layout

    fileprivate func setupLayout() {
        backgroundColor = Color.navigationBarColor
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

        if !filters.isEmpty {
            addSubview(filterStackView)
            filterStackView.snp.makeConstraints {
                $0.top.equalTo(dateScrollView.snp.bottom)
                $0.leading.trailing.bottom.equalToSuperview()
                $0.height.equalTo(Constants.filterRowHeight)
            }
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

        for (index, title) in filters.enumerated() {
            let button = makeFilterButton(title: title, index: index)
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

    fileprivate func makeFilterButton(title: String, index: Int) -> UIButton {
        let button = UIButton(type: .system)
        button.tag = index
        button.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        button.setContentCompressionResistancePriority(.required, for: .horizontal)
        button.addTarget(self, action: #selector(didTapFilterButton(_:)), for: .touchUpInside)

        if #available(iOS 26, *) {
            var config = UIButton.Configuration.glass()
            config.title = title
            config.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12)
            config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attrs in
                var updated = attrs
                updated.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
                return updated
            }
            button.configuration = config
            
            button.configurationUpdateHandler = { [weak self] button in
                guard let self else { return }
                var updated = button.configuration
                let active = button.isSelected && button.isEnabled
                let disabled = !button.isEnabled

                updated?.background.backgroundColor = active ? tintColor.withAlphaComponent(0.2) : .clear
                updated?.attributedTitle = AttributedString(NSAttributedString(
                    string: button.configuration?.title ?? "",
                    attributes: [
                        .font: UIFont.systemFont(ofSize: 12, weight: .semibold),
                        .foregroundColor: disabled ? Color.gray100 : (active ? tintColor as UIColor : Color.black)
                    ]
                ))

                button.configuration = updated
            }
        } else {
            button.setTitle(title, for: .normal)
            button.setTitleColor(Color.black, for: .normal)
            button.setTitleColor(tintColor, for: .selected)
            button.titleLabel?.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
            button.contentEdgeInsets = UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12)
            button.layer.cornerRadius = 8
            button.layer.cornerCurve = .continuous
        }

        return button
    }

    // MARK: - Selection

    fileprivate func selectDate(at index: Int, notify: Bool = true) {
        guard index < dates.count else { return }

        // Deselect previous
        deselect(dateButton(at: selectedDateIndex))

        selectedDateIndex = index
        select(dateButton(at: index))

        if notify, let date = selectedDate {
            delegate?.headerView(self, didSelectDate: date)
        }
    }

    fileprivate func selectFilter(at index: Int, notify: Bool = true) {
        // Deselect previous
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
        button.isSelected = true

        if #available(iOS 26, *) {
            button.setNeedsUpdateConfiguration()
        } else {
            if dateStackView.arrangedSubviews.contains(button) {
                button.setTitleColor(Color.white, for: .normal)
                button.backgroundColor = tintColor
                button.layer.borderColor = tintColor.cgColor
            } else {
                button.setTitleColor(tintColor, for: .normal)
                button.backgroundColor = tintColor.withAlphaComponent(0.2)
            }
        }
    }

    fileprivate func deselect(_ button: UIButton?) {
        guard let button else { return }
        button.isSelected = false

        if #available(iOS 26, *) {
            button.setNeedsUpdateConfiguration()
        } else {
            // Restore appearance based on which stack the button belongs to
            if dateStackView.arrangedSubviews.contains(button) {
                button.setTitleColor(tintColor, for: .normal)
                button.backgroundColor = Color.gray20
                button.layer.borderColor = Color.gray50.cgColor
            } else {
                button.setTitleColor(Color.black, for: .normal)
                button.backgroundColor = Color.gray200
            }
        }
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
// MARK: – Array safe subscript
// ---------------------------------------------------------------------------

fileprivate extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
