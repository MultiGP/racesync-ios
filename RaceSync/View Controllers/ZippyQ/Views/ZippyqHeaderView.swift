//
//  ZippyqHeaderView.swift
//  RaceSync
//
//  Created by Ignacio Romero on 2026-08-15.
//  Copyright © 2026 MultiGP Inc. All rights reserved.
//

import UIKit
import SnapKit

class ZippyqHeaderView: UICollectionReusableView {

    struct LayoutMetrics: Equatable {
        let expandedHeight: CGFloat
        let compactHeight: CGFloat

        var collapseRange: CGFloat {
            return expandedHeight - compactHeight
        }
    }

    // MARK: - Public Variables

    /// Used only for the first collection layout pass and replaced by measured Auto Layout metrics.
    static let initialLayoutHeight: CGFloat = 241
    static let identifier = "ZippyqHeaderView"

    var didSelectFrequency: ((String) -> Void)?
    var didTapJoinNextRound: (() -> Void)?
    var didResolveLayoutMetrics: ((LayoutMetrics) -> Void)?
    private(set) var layoutMetrics: LayoutMetrics?

    var collapseProgress: CGFloat = 0 {
        didSet {
            updateCollapseTransform()
        }
    }

    var isLoading: Bool {
        get { return joinButton.isLoading }
        set {
            joinButton.setImage(newValue ? nil : joinButtonImage, for: .normal)
            joinButton.isLoading = newValue
        }
    }

    // MARK: - Private Variables

    fileprivate let joinButtonImage = (UIImage(systemName: "person.fill.badge.plus") ?? SystemImg.personFill)?
        .withConfiguration(UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold))
    fileprivate var isConfigured = false

    fileprivate lazy var availabilityTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "My Preferred Channels".uppercased()
        label.font = Constants.availabilityTitleFont
        label.textColor = Color.gray400
        return label
    }()

    fileprivate lazy var preferenceLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        label.textColor = Color.gray300
        label.textAlignment = .right
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.8
        return label
    }()

    fileprivate lazy var titleStackView: UIStackView = {
        let spacerView = UIView()
        let stackView = UIStackView(arrangedSubviews: [availabilityTitleLabel, spacerView, preferenceLabel])
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = 8
        return stackView
    }()

    fileprivate lazy var frequencyStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .fill
        stackView.distribution = .fillEqually
        stackView.spacing = 10
        return stackView
    }()

    fileprivate lazy var availabilityView: UIView = {
        
        let view = UIView()
        view.addSubview(titleStackView)
        titleStackView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
        }
        
        view.addSubview(frequencyStackView)
        frequencyStackView.snp.makeConstraints {
            $0.top.equalTo(titleStackView.snp.bottom).offset(Constants.padding)
            $0.leading.bottom.equalToSuperview()
            $0.trailing.lessThanOrEqualToSuperview()
            $0.height.equalTo(Constants.toggleHeight)
        }
        return view
    }()

    fileprivate lazy var joinButton: ActionButton = {
        let button = ActionButton(type: .system)
        button.addTarget(self, action: #selector(didTapJoinButton), for: .touchUpInside)

        button.setTitle("Join Next Available", for: .normal)
        button.setTitleColor(Color.light, for: .normal)
        button.setImage(joinButtonImage?.withTintColor(Color.light, renderingMode: .alwaysOriginal), for: .normal)
        button.tintColor = Color.light
        button.backgroundColor = Color.green
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        button.contentEdgeInsets = UIEdgeInsets(top: Constants.padding/2, left: Constants.padding,
                                               bottom: Constants.padding/2, right: Constants.padding)
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: -6, bottom: 0, right: 6)
        button.layer.cornerCurve = .continuous
        button.layer.borderColor = Color.gray100.cgColor
        button.layer.borderWidth = 0.5
        button.spinnerView.color = Color.light
        button.bouncesOnPress = true

        if #available(iOS 26.0, *) {
            button.layer.cornerRadius = Constants.joinButtonHeight/2
        } else {
            button.layer.cornerRadius = 14
        }
        return button
    }()

    fileprivate lazy var statsLabel: UILabel = {
        let label = UILabel()
        label.font = Constants.statsFont
        label.textColor = Color.blue
        label.textAlignment = .center
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.75
        label.numberOfLines = 1
        return label
    }()

    fileprivate lazy var contentStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [availabilityView, joinButton, statsLabel])
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.spacing = Constants.contentSpacing
        return stackView
    }()

    fileprivate lazy var backgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = Color.cellColor
        return view
    }()

    fileprivate lazy var separatorView: UIView = {
        let view = UIView()
        view.backgroundColor = Color.gray100
        return view
    }()

    fileprivate enum Constants {
        static let padding = UniversalConstants.padding
        static let contentSpacing: CGFloat = 12
        static let joinButtonHeight: CGFloat = 50
        static let sectionSpacing: CGFloat = 18
        static let availabilityTitleFont = UIFont.systemFont(ofSize: 13, weight: .semibold)
        static let statsFont = UIFont.systemFont(ofSize: 14, weight: .medium)
        static let toggleWidthMax: CGFloat = 62
        static let toggleWidthMin: CGFloat = 60
        static let toggleHeight: CGFloat = 72
        static let toggleCornerRadius: CGFloat = 9
        static let toggleIconSize: CGFloat = 16
    }

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        guard isConfigured, layoutMetrics == nil, bounds.width > 0,
              contentStackView.frame.height > 0, availabilityView.frame.height > 0 else {
            return
        }

        let expandedHeight = contentStackView.frame.maxY + Constants.padding + Constants.sectionSpacing
        let collapsedContentOffset = contentStackView.frame.minY + availabilityView.frame.maxY
        let metrics = LayoutMetrics(
            expandedHeight: expandedHeight,
            compactHeight: expandedHeight - collapsedContentOffset
        )
        layoutMetrics = metrics
        updateCollapseTransform()

        DispatchQueue.main.async { [weak self] in
            self?.didResolveLayoutMetrics?(metrics)
        }
    }

    // MARK: - Configuration

    func configure(with viewModel: ZippyqHeaderViewModel) {
        
        preferenceLabel.text = viewModel.preferenceLabel
        preferenceLabel.textColor = viewModel.frequencyViewModels.contains(where: { $0.isSelected }) ? Color.gray300 : Color.red
        statsLabel.text = viewModel.statsLabel
        joinButton.isEnabled = viewModel.isJoinEnabled
        updateFrequencies(with: viewModel.frequencyViewModels)
        isConfigured = true
        setNeedsLayout()
    }
}

private extension ZippyqHeaderView {
    
    // MARK: - Layout

    func setupLayout() {

        backgroundColor = Color.clear
        clipsToBounds = true

        addSubview(backgroundView)
        backgroundView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.bottom.equalToSuperview().offset(-Constants.sectionSpacing)
        }

        addSubview(contentStackView)
        contentStackView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview().inset(Constants.padding)
        }

        joinButton.snp.makeConstraints {
            $0.height.equalTo(Constants.joinButtonHeight)
        }

        addSubview(separatorView)
        separatorView.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(backgroundView.snp.bottom)
            $0.height.equalTo(0.5)
        }
    }

    func updateCollapseTransform() {
        let progress = min(max(collapseProgress, 0), 1)
        let collapseRange = layoutMetrics?.collapseRange ?? 0
        contentStackView.transform = CGAffineTransform(translationX: 0, y: -collapseRange * progress)
    }

    func updateFrequencies(with viewModels: [ZippyqHeaderFrequencyViewModel]) {
        frequencyStackView.arrangedSubviews.forEach {
            frequencyStackView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        viewModels.forEach { frequencyStackView.addArrangedSubview(makeFrequencyButton(with: $0)) }
    }

    func makeFrequencyButton(with viewModel: ZippyqHeaderFrequencyViewModel) -> UIButton {
        let button = UIButton(type: .custom)
        button.snp.makeConstraints {
            $0.width.equalTo(Constants.toggleWidthMax).priority(999)
            $0.width.greaterThanOrEqualTo(Constants.toggleWidthMin).priority(998)
        }
        button.isEnabled = viewModel.isEnabled
        button.backgroundColor = viewModel.isSelected ? Color.gray20 : Color.cellColor
        button.layer.cornerCurve = .continuous
        button.layer.cornerRadius = Constants.toggleCornerRadius
        button.layer.borderWidth = viewModel.isSelected ? 1.0 : 0.5
        button.layer.borderColor = (viewModel.isSelected ? Color.blue : Color.gray100).cgColor

        if #available(iOS 26, *) {
            var configuration = UIButton.Configuration.glass()
            configuration.cornerStyle = .fixed
            configuration.background.cornerRadius = Constants.toggleCornerRadius
            configuration.background.backgroundColor = viewModel.isSelected
                ? Color.gray20.withAlphaComponent(0.12)
                : Color.cellColor.withAlphaComponent(0.2)
            button.configuration = configuration
            button.backgroundColor = .clear
        }
        
        guard let frequency = viewModel.frequency,
              let channelLabel = viewModel.channelLabel,
              let queuedPilotCount = viewModel.queuedPilotCount else {
            if #available(iOS 26, *) {
                var configuration = button.configuration ?? UIButton.Configuration.glass()
                configuration.background.backgroundColor = Color.gray20.withAlphaComponent(0.2)
                button.configuration = configuration
            } else {
                button.backgroundColor = Color.gray20.withAlphaComponent(0.35)
            }
            return button
        }

        let channel = UILabel()
        channel.text = channelLabel
        channel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        channel.textColor = viewModel.isSelected ? Color.blue : Color.black
        channel.textAlignment = .center
        channel.isUserInteractionEnabled = false

        let countIcon = UIImageView(image: SystemImg.personFill)
        countIcon.tintColor = viewModel.isSelected ? Color.blue : Color.gray300
        countIcon.contentMode = .scaleAspectFit

        let count = UILabel()
        count.text = "\(queuedPilotCount)"
        count.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        count.textColor = viewModel.isSelected ? Color.blue : Color.gray300

        let countStack = UIStackView(arrangedSubviews: [countIcon, count])
        countStack.axis = .horizontal
        countStack.alignment = .center
        countStack.spacing = 3
        countStack.isUserInteractionEnabled = false
        countIcon.snp.makeConstraints { $0.width.height.equalTo(Constants.toggleIconSize) }
        countIcon.isUserInteractionEnabled = false

        let colorBar = UIView()
        colorBar.backgroundColor = viewModel.color ?? Color.gray100
        colorBar.layer.cornerRadius = 1.5
        colorBar.isUserInteractionEnabled = false

        button.addSubview(channel)
        channel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(Constants.padding/2)
            $0.leading.trailing.equalToSuperview().inset(Constants.padding/4)
        }
        button.addSubview(countStack)
        countStack.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalTo(channel.snp.bottom).offset(Constants.padding/4)
        }
        button.addSubview(colorBar)
        colorBar.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.bottom.equalToSuperview().inset(Constants.padding/4)
            $0.width.equalToSuperview().multipliedBy(0.45)
            $0.height.equalTo(3)
        }

        button.addAction(UIAction { [weak self] _ in
            self?.didSelectFrequency?(frequency)
        }, for: .touchUpInside)
        return button
    }

    // MARK: - Actions

    @objc func didTapJoinButton() {
        didTapJoinNextRound?()
    }

}
