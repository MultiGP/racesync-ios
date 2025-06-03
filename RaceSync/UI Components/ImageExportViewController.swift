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
    case cameraroll, shareto, instagram
}

class ImageExportViewController: UIViewController {

    // MARK: - Initialization

    init(with image: UIImage, size: CGSize = .zero, caption: String? = nil, contentMode: UIView.ContentMode? = nil, options: [ImageExportOptions]? = nil) {
        self.image = image
        self.caption = caption

        if size != .zero {
            imageSize = size
        }
        if let options = options {
            self.exportOptions = options
        }
        if let contentMode = contentMode {
            self.imageContentMode = contentMode
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
    fileprivate var imageSize: CGSize = CGSize(width: 320, height: 320)
    fileprivate var imageContentMode: UIView.ContentMode = .center

    lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.backgroundColor = Color.white
        imageView.layer.cornerRadius = Constants.cornerRadius/2
        imageView.layer.masksToBounds = true
        imageView.isUserInteractionEnabled = true
        imageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dissmissView(_:))))

        let hSwipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(dissmissView(_:)))
        hSwipeGesture.direction = [.left,.right]
        imageView.addGestureRecognizer(hSwipeGesture)

        let vSwipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(dissmissView(_:)))
        vSwipeGesture.direction = [.down,.up]
        imageView.addGestureRecognizer(vSwipeGesture)

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

    fileprivate lazy var shareButton: UIButton = {
        let image = UIImage(named: "icn_apple_share")?.withRenderingMode(.alwaysOriginal)
        let button = UIButton(type: .system)
        button.setImage(image, for: .normal)
        button.setTitle("Share to...", for: .normal)
        button.addTarget(self, action: #selector(didPressShareButton), for: .touchUpInside)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 19, weight: .regular)
        button.tintColor = Color.black
        button.backgroundColor = Color.white
        button.imageEdgeInsets = UIEdgeInsets(left: -30)
        button.titleEdgeInsets = UIEdgeInsets(left: 0)
        button.layer.cornerRadius = Constants.cornerRadius/2
        button.layer.masksToBounds = true
        return button
    }()

    fileprivate lazy var instagramButton: UIButton = {
        let image = UIImage(named: "icn_meta_instagram")?.withRenderingMode(.alwaysOriginal)
        let button = UIButton(type: .system)
        button.setImage(image, for: .normal)
        button.setTitle("Share to Instagram", for: .normal)
        button.addTarget(self, action: #selector(didPressInstagramButton), for: .touchUpInside)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 19, weight: .regular)
        button.tintColor = Color.black
        button.backgroundColor = Color.white
        button.imageEdgeInsets = UIEdgeInsets(left: -20)
        button.titleEdgeInsets = UIEdgeInsets(left: 0)
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
        return [
            exportOptions.contains(.cameraroll) ? photosButton : nil,
            exportOptions.contains(.shareto) ? shareButton : nil,
            exportOptions.contains(.instagram) ? instagramButton : nil
        ].compactMap { $0 }
    }

    fileprivate enum Constants {
        static let padding: CGFloat = UniversalConstants.padding
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
        imageView.contentMode = imageContentMode

        captionLabel.text = caption

        view.backgroundColor = Color.black.withAlphaComponent(0.7)
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dissmissView)))

        view.addSubview(imageView)
        imageView.snp.makeConstraints {
            $0.centerY.equalToSuperview().offset(-Constants.padding*2)
            $0.centerX.equalToSuperview()
            $0.size.equalTo(imageSize)
        }

        view.addSubview(buttonStackView)
        buttonStackView.snp.makeConstraints {
            $0.top.equalTo(imageView.snp.bottom).offset(Constants.padding*3)
            $0.centerX.equalToSuperview()
            $0.width.equalTo(imageSize.width)
            $0.height.greaterThanOrEqualTo(Constants.buttonHeight)
        }

        let map: [(ImageExportOptions, UIButton)] = [(.cameraroll, photosButton),
                                                     (.shareto, shareButton),
                                                     (.instagram, instagramButton)]

        map.filter { exportOptions.contains($0.0) }
            .forEach { _, button in
                button.snp.makeConstraints {
                    $0.width.equalTo(imageSize.width)
                    $0.height.equalTo(Constants.buttonHeight)
                }
            }
    }

    // MARK: - Actions

    @objc func dissmissView(_ gesture: UITapGestureRecognizer) {
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

    @objc func didPressShareButton() {
        shareToApps(image: image)
    }

    @objc func didPressInstagramButton() {
        shareToInstagramStory(image: image)
    }
}

extension ImageExportViewController {

    func shareToApps(image: UIImage) {
        let vc = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        vc.excludedActivityTypes = [.addToReadingList, .assignToContact, .openInIBooks, .markupAsPDF]
        present(vc, animated: true)
    }

    func shareToInstagramStory(image: UIImage) {
        guard let imageData = image.pngData() else { return }

        let pasteboardItems: [String: Any] = [
            "com.instagram.sharedSticker.backgroundImage": imageData
        ]

        let expirationDate = Date().addingTimeInterval(300)
        UIPasteboard.general.setItems([pasteboardItems], options: [
            .expirationDate: expirationDate
        ])

        let instagramUrl = URL(string: "instagram-stories://share")!

        if UIApplication.shared.canOpenURL(instagramUrl) {
            UIApplication.shared.open(instagramUrl, options: [:], completionHandler: nil)
        } else {
            print("Instagram app not installed.")
        }
    }
}
