//
//  ImageExportViewController.swift
//  RaceSync
//
//  Created by Ignacio Romero Zurbuchen on 2025-06-02.
//  Copyright © 2025 MultiGP Inc. All rights reserved.
//

import UIKit
import SnapKit

enum ImageExportOptions {
    case cameraroll, share
}

class ImageExportViewController: UIViewController {

    // MARK: - Initialization

    init(with caption: String?, image: UIImage, exportOptions: [ImageExportOptions]? = nil) {
        self.caption = caption
        self.image = image

        if let options = exportOptions {
            self.exportOptions = options
        }

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Private Variables

    fileprivate let caption: String?
    fileprivate let image: UIImage
    fileprivate var exportOptions: [ImageExportOptions] = [.cameraroll]

    lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.backgroundColor = Color.white
        imageView.contentMode = .center
        imageView.layer.cornerRadius = Constants.cornerRadius/2
        imageView.isUserInteractionEnabled = true
        imageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapImageView)))

        imageView.addSubview(captionLabel)
        captionLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(Constants.padding)
            $0.trailing.equalToSuperview().offset(-Constants.padding)
            $0.bottom.equalToSuperview().offset(-Constants.padding/2)
        }
        return imageView
    }()

    lazy var captionLabel: PasteboardLabel = {
        let label = PasteboardLabel()
        label.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        label.textColor = Color.black
        label.textAlignment = .center
        return label
    }()

    fileprivate lazy var photosButton: UIButton = {
        let image = UIImage(named: "icn_apple_photos")?.withRenderingMode(.alwaysOriginal)
        let button = UIButton(type: .system)
        button.setImage(image, for: .normal)
        button.setTitle("Save to Photos", for: .normal)
        button.addTarget(self, action: #selector(didPressPhotosButton), for: .touchUpInside)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 19, weight: .regular)
        button.tintColor = Color.black
        button.backgroundColor = Color.white
        button.imageEdgeInsets = UIEdgeInsets(left: -50)
        button.titleEdgeInsets = UIEdgeInsets(left: -30)
        button.layer.cornerRadius = Constants.cornerRadius/2
        button.layer.masksToBounds = true
        return button
    }()

    fileprivate lazy var buttonStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: actionButtons())
        stackView.backgroundColor = Color.clear
        stackView.axis = .vertical
        stackView.distribution = .fillEqually
        stackView.alignment = .center
        stackView.spacing = Constants.padding
        return stackView
    }()

    fileprivate func actionButtons() -> [UIView] {
        var buttons = [UIButton]()

        if exportOptions.contains(.cameraroll) {
            buttons += [photosButton]
        }

        return buttons
    }

    fileprivate enum Constants {
        static let padding: CGFloat = UniversalConstants.padding
        static let imageSize: CGSize = CGSize(width: 320, height: 320)
        static let cornerRadius: CGFloat = 24
        static let buttonHeight: CGFloat = 56
    }

    // MARK: - Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()

        setupLayout()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    // MARK: - Layout

    open func setupLayout() {

        imageView.image = image
        captionLabel.text = caption

        view.backgroundColor = Color.black.withAlphaComponent(0.7)
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapView)))

        view.addSubview(imageView)
        imageView.snp.makeConstraints {
            $0.centerY.equalToSuperview().offset(-Constants.padding*2)
            $0.centerX.equalToSuperview()
            $0.size.equalTo(Constants.imageSize)
        }

        view.addSubview(buttonStackView)
        buttonStackView.snp.makeConstraints {
            $0.top.equalTo(imageView.snp.bottom).offset(Constants.padding*3)
            $0.centerX.equalToSuperview()
            $0.width.equalTo(Constants.imageSize.width)
            $0.height.greaterThanOrEqualTo(Constants.buttonHeight)
        }

        photosButton.snp.makeConstraints {
            $0.width.equalTo(Constants.imageSize.width)
            $0.height.equalTo(Constants.buttonHeight)
        }
    }

    // MARK: - Actions

    @objc func didTapView() {
        dismiss(animated: true)
    }

    @objc func didTapImageView() {
        dismiss(animated: true)
    }

    @objc func didPressPhotosButton() {
        guard let image = imageView.image else { return }
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
    }

    @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            AlertUtil.presentAlertMessage(error.localizedDescription, title: "Save error")
        } else {
            AlertUtil.presentAlertMessage("The image has been saved to the Photos app!", title: "Saved Image")
        }
    }
}
