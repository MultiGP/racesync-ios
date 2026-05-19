//
//  RichEditorToolbar.swift
//  RaceSync
//
//  Created by Ignacio Romero Zurbuchen on 2023-01-04.
//
//  Heavily modified version of RichEditorView using WKWebView
//  https://github.com/Andrew-Chen-Wang/RichEditorView
//

import UIKit
import SnapKit

/// RichEditorToolbarDelegate is a protocol for the RichEditorToolbar.
@objc protocol RichEditorToolbarDelegate {

    /// Called when the Text Color toolbar item is pressed.
    @objc optional func richEditorToolbarChangeTextColor(_ toolbar: RichEditorToolbar)

    /// Called when the Background Color toolbar item is pressed.
    @objc optional func richEditorToolbarChangeBackgroundColor(_ toolbar: RichEditorToolbar)

    /// Called when the Insert Image toolbar item is pressed.
    @objc optional func richEditorToolbarInsertImage(_ toolbar: RichEditorToolbar)

    /// Called when the Insert Video toolbar item is pressed
    @objc optional func richEditorToolbarInsertVideo(_ toolbar: RichEditorToolbar)

    /// Called when the Insert Link toolbar item is pressed.
    @objc optional func richEditorToolbarInsertLink(_ toolbar: RichEditorToolbar)
    
    /// Called when the Insert Table toolbar item is pressed
    @objc optional func richEditorToolbarInsertTable(_ toolbar: RichEditorToolbar)
}

/// RichEditorToolbar is UIView that contains the toolbar for actions that can be performed on a RichEditorView
class RichEditorToolbar: UIView {

    weak var delegate: RichEditorToolbarDelegate?
    weak var editor: RichEditorView?

    var options: [RichEditorOption] = [] {
        didSet { updateToolbar() }
    }

    fileprivate lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.backgroundColor = .clear
        scrollView.keyboardDismissMode = .none
        return scrollView
    }()

    fileprivate lazy var stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = Constants.padding
        stack.alignment = .center
        return stack
    }()

    fileprivate enum Constants {
        static let padding: CGFloat = UniversalConstants.padding * 2
        static let buttonSize: CGFloat = 30
    }

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupLayout()
    }

    // MARK: - Layout

    private func setupLayout() {
        autoresizingMask = .flexibleWidth
        backgroundColor = Color.navigationBarColor
        addSeparatorLine()

        addSubview(scrollView)
        scrollView.addSubview(stackView)

        scrollView.snp.makeConstraints { $0.edges.equalToSuperview() }
        stackView.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 0, left: Constants.padding, bottom: 0, right: Constants.padding))
            $0.height.equalTo(scrollView)
        }

        updateToolbar()
    }

    func updateToolbar() {
        
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        guard !options.isEmpty else { return }

        for option in options {
            let button = UIButton(type: .system)
            button.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)

            if let image = option.image {
                button.setImage(image, for: .normal)
            } else {
                button.setTitle(option.title, for: .normal)
            }

            button.snp.makeConstraints {
                $0.width.greaterThanOrEqualTo(Constants.buttonSize)
                $0.height.equalTo(Constants.buttonSize)
            }

            // Store option index as tag for identification
            button.tag = options.firstIndex(where: { $0.title == option.title }) ?? 0
            button.tintColor = Color.blue
            stackView.addArrangedSubview(button)
        }

        // Content size is driven by Auto Layout — no manual calculation needed
        scrollView.layoutIfNeeded()
    }

    @objc private func buttonTapped(_ sender: UIButton) {
        guard sender.tag < options.count else { return }
        options[sender.tag].action(self)
    }
}
