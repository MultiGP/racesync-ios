//
//  QRViewController.swift
//  RaceSync
//
//  Created by Ignacio Romero Zurbuchen on 2019-11-15.
//  Copyright © 2019 MultiGP Inc. All rights reserved.
//

import UIKit
import RaceSyncAPI
import QRCode

class QRViewController: ImageExportViewController {

    // MARK: - Private Variables

    fileprivate let userId: String

    // MARK: - Initialization

    init(with userId: String) {
        self.userId = userId
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "QR Code"
        imageView.image = getQRImage(with: userId)
        captionLabel.text = userId
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    // MARK: - Layout

    func getQRImage(with userId: String) -> UIImage? {
        var qrCode = QRCode(userId)
        qrCode?.size = CGSize(width: 270, height: 270)
        qrCode?.color = CIColor(color: Color.black)
        qrCode?.backgroundColor = CIColor(color: Color.white)
        return qrCode?.image
    }
}
