//
//  JoinButton.swift
//  RaceSync
//
//  Created by Ignacio Romero Zurbuchen on 2019-11-15.
//  Copyright © 2019 MultiGP Inc. All rights reserved.
//

import UIKit
import SnapKit
import RaceSyncAPI

public enum JoinableType {
    case race, chapter
}

class JoinButton: CustomButton {

    // MARK: - Public Variables

    /// Optional race/chapter id for callback usage
    var objectId: ObjectId?

    var type: JoinableType?

    /// compact style to be used in small cells, with no interactivity
    var isCompact: Bool = false

    var joinState: JoinState = .notJoined {
        didSet {
            updateLayout()
        }
    }

    var isLoading: Bool = false {
        didSet {
            updateAnimation()
        }
    }

    static let minHeight: CGFloat = 32
    static let minWidth: CGFloat = 76
    static let cornerRadius: CGFloat = 6

    // MARK: - Private Variables

    fileprivate lazy var spinnerView: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(style: .medium)

        addSubview(view)
        view.snp.makeConstraints { (make) -> Void in
            make.centerX.centerY.equalToSuperview()
        }
        return view
    }()

    // MARK: - Initialization

    init() {
        super.init(frame: .zero)
        setupLayout()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Layout

    fileprivate func setupLayout() {
        titleLabel?.lineBreakMode = .byClipping
        titleLabel?.numberOfLines = 1
        titleLabel?.adjustsFontSizeToFitWidth = false

        adjustsImageWhenHighlighted = false
        adjustsImageWhenDisabled = true

        imageEdgeInsets = UIEdgeInsets(top: 0, left: -4, bottom: 0, right: 0)
        contentEdgeInsets = UIEdgeInsets(top: 5, left: 8, bottom: 5, right: 8)

        // Critical: prevent shrinking
        setContentHuggingPriority(.required, for: .horizontal)
        setContentCompressionResistancePriority(.required, for: .horizontal)

        layer.cornerRadius = Self.cornerRadius
        layer.borderWidth = 0
    }

    fileprivate func updateLayout() {

        func layout() {
            var state = joinState
            isHidden = false

            if isCompact {
                if state == .notJoined {
                    isHidden = true
                    return
                }
                else if case .notPaid = state {
                    state = .joined // display as joined
                }
            }

            let icon = state.icon?.image(withColor: state.titleColor.withAlphaComponent(isCompact ? 1 : 0.4))

            setTitle(isCompact ? nil : state.title, for: .normal)
            setTitleColor(state.titleColor, for: .normal)
            setImage(icon, for: .normal)
            backgroundColor = state.fillColor
            titleLabel?.font = state.font
            tintColor = state.titleColor
            imageView?.tintColor = state.titleColor
            isUserInteractionEnabled = !isCompact

            if let borderColor = state.outlineColor {
                layer.borderColor = borderColor.cgColor
                layer.borderWidth = 1
            } else {
                layer.borderWidth = 0
            }
        }

        UIView.performWithoutAnimation {
            layout()
        }
    }

    // MARK: - Animation

    fileprivate func updateAnimation() {
        spinnerView.isHidden = !isLoading
        isUserInteractionEnabled = !isLoading
        animateSpinner(isLoading)

        let state = joinState
        let icon = state.icon?.image(withColor: state.titleColor)
        setTitle(isLoading ? nil : state.title, for: .normal)
        setImage(isLoading ? nil : icon, for: .normal)
    }

    fileprivate func animateSpinner(_ animate: Bool) {
        if animate && !spinnerView.isAnimating {
            spinnerView.color = joinState.titleColor
            spinnerView.startAnimating()
        } else if !animate && spinnerView.isAnimating {
            spinnerView.stopAnimating()
        }
    }

    // MARK: - Overrides

    override var intrinsicContentSize: CGSize {
        return CGSize(width: Self.minWidth, height: Self.minHeight)
    }

    override var isHighlighted: Bool {
        get {
            if !joinState.interactionEnabled {
                return false
            } else {
                return super.isHighlighted
            }
        }
        set {
            super.isHighlighted = newValue
        }
    }

    override var isSelected: Bool {
        get {
            if !joinState.interactionEnabled {
                return false
            } else {
                return super.isSelected
            }
        }
        set {
            super.isSelected = newValue
        }
    }

    override func sendAction(_ action: Selector, to target: Any?, for event: UIEvent?) {
        guard joinState.interactionEnabled else { return }
        super.sendAction(action, to: target, for: event)
    }

    override func sendActions(for controlEvents: UIControl.Event) {
        guard joinState.interactionEnabled else { return }
        super.sendActions(for: controlEvents)
    }
}

extension JoinState {

    var icon: UIImage? {
        switch self {
        case .joined:       return ButtonImg.join_check?.withRenderingMode(.alwaysOriginal)
        case .closed:       return ButtonImg.join_cross?.withRenderingMode(.alwaysOriginal)
        default:            return nil
        }
    }

    var fillColor: UIColor {
        switch self {
        case .notJoined:    return Color.white
        case .joined:       return Color.green
        case .closed:       return Color.gray100
        case .notPaid(fee: _):
                            return Color.white
        }
    }

    var outlineColor: UIColor? {
        switch self {
        case .notJoined:    return Color.green
        case .notPaid(fee: _):
                            return Color.green
        default:            return nil
        }
    }

    var titleColor: UIColor {
        switch self {
        case .notJoined:    return Color.green
        case .joined:       return Color.white
        case .closed:       return Color.black
        case .notPaid(fee: _):
                            return Color.green
        }
    }

    var font: UIFont {
        switch self {
        case .notJoined, .notPaid(fee: _):
                            return UIFont.systemFont(ofSize: 14, weight: .bold)
        default:            return UIFont.systemFont(ofSize: 14, weight: .regular)

        }
    }

    var interactionEnabled: Bool {
        switch self {
        case .closed:   return false
        default:        return true
        }
    }
}
