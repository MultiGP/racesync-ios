//
//  ApprovalButton.swift
//  RaceSync
//
//  Created by Ignacio Romero Zurbuchen on 2026-04-11.
//  Copyright © 2026 MultiGP Inc. All rights reserved.
//

import UIKit
import SnapKit
import RaceSyncAPI

public enum ApprovableType {
    case race, series
}

class ApproveButton: CustomButton {

    /// Optional race/series id for callback usage
    var objectId: ObjectId?

    var type: ApprovableType?

    var approveState: ApproveState = .notApproved {
        didSet {
            updateLayout()
        }
    }

    var isLoading: Bool = false {
        didSet {
            updateAnimation()
        }
    }
    
    static let minHeight: CGFloat = {
        if #available(iOS 26.0, *) {
            return 36
        } else {
            return 32
        }
    }()
    
    static let minWidth: CGFloat = {
        if #available(iOS 26.0, *) {
            return 86
        } else {
            return 82
        }
    }()
    
    static let cornerRadius: CGFloat = {
        if #available(iOS 26.0, *) {
            return minHeight/2
        } else {
            return 6
        }
    }()

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

        imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        contentEdgeInsets = UIEdgeInsets(top: 5, left: 8, bottom: 5, right: 8)

        // Critical: prevent shrinking
        setContentHuggingPriority(.required, for: .horizontal)
        setContentCompressionResistancePriority(.required, for: .horizontal)

        layer.cornerCurve = .continuous
        layer.cornerRadius = Self.cornerRadius
        layer.borderWidth = 0
    }

    fileprivate func updateLayout() {

        func layout() {
            let state = approveState
            isHidden = false

            let icon = state.icon?.image(withColor: state.titleColor)

            setTitle(state.title, for: .normal)
            setTitleColor(state.titleColor, for: .normal)
            setImage(icon, for: .normal)
            backgroundColor = state.fillColor
            titleLabel?.font = state.font
            tintColor = state.titleColor
            imageView?.tintColor = state.titleColor
            isUserInteractionEnabled = state.interactionEnabled

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

        let state = approveState
        let icon = state.icon?.image(withColor: state.titleColor)
        setTitle(isLoading ? nil : state.title, for: .normal)
        setImage(isLoading ? nil : icon, for: .normal)
    }

    fileprivate func animateSpinner(_ animate: Bool) {
        if animate && !spinnerView.isAnimating {
            spinnerView.color = approveState.titleColor
            spinnerView.startAnimating()
        } else if !animate && spinnerView.isAnimating {
            spinnerView.stopAnimating()
        }
    }

    // MARK: - Overrides

    override var intrinsicContentSize: CGSize {
        if approveState == .remove {
            return CGSize(width: Self.minWidth/2, height: Self.minHeight)
        } else {
            return CGSize(width: Self.minWidth, height: Self.minHeight)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if #available(iOS 26.0, *) {
            layer.cornerRadius = bounds.height / 2
            layer.cornerCurve = .continuous  // matches Apple's "squircle" style
        }
    }
}

extension ApproveState {

    var icon: UIImage? {
        switch self {
        case .remove:       return SystemImg.trashFill?.withRenderingMode(.alwaysTemplate)
        default:            return nil
        }
    }

    var fillColor: UIColor {
        switch self {
        case .notApproved:  return Color.white
        case .approved:     return Color.green
        case .remove:       return Color.white
        case .completed:    return Color.gray100

        }
    }

    var outlineColor: UIColor? {
        switch self {
        case .notApproved:  return Color.green
        case .remove:       return Color.lightRed
        default:            return nil
        }
    }

    var titleColor: UIColor {
        switch self {
        case .notApproved:  return Color.green
        case .approved:     return Color.white
        case .remove:       return Color.lightRed
        case .completed:    return Color.black.withAlphaComponent(0.75)
        }
    }

    var font: UIFont {
        switch self {
        case .notApproved:  return .systemFont(ofSize: 14, weight: .bold)
        default:            return .systemFont(ofSize: 14, weight: .regular)
        }
    }

    var interactionEnabled: Bool {
        switch self {
        case .completed:    return false
        default:            return true
        }
    }
}
