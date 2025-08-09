//
//  PaypalActivity.swift
//  RaceSync
//
//  Created by Ignacio Romero Zurbuchen on 2025-08-09.
//  Copyright © 2025 MultiGP Inc. All rights reserved.
//

import UIKit

class PaypalActivity: UIActivity {

    override var activityTitle: String? { "Open PayPal"}

    override var activityImage: UIImage? { UIImage(named: "icn_activity_paypal") }

    private var paypalURL: URL? {
        [ExternalAppUri.Paypal, ExternalAppUrl.Paypal]
            .compactMap { URL(string: $0) }
            .first { UIApplication.shared.canOpenURL($0) }
    }

    override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        paypalURL != nil
    }

    override func prepare(withActivityItems activityItems: [Any]) { }

    override func perform() {
        guard let url = paypalURL else {
            activityDidFinish(false)
            return
        }
        UIApplication.shared.open(url, options: [:]) { [weak self] completed in
            self?.activityDidFinish(completed)
        }
    }
}
