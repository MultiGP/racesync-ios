//
//  WebViewController.swift
//  RaceSync
//
//  Created by Ignacio Romero Zurbuchen on 2020-12-05.
//  Copyright © 2020 MultiGP Inc. All rights reserved.
//

import UIKit
import SafariServices
import RaceSyncAPI

class WebViewController: SFSafariViewController {

    // MARK: - Public

    static func open(_ url: String, style: UIModalPresentationStyle = .automatic, completion: (() -> Void)? = nil) {
        guard let URL = URL(string: url) else { return }
        open(URL, style: style, completion: completion)
    }

    static func open(_ URL: URL, style: UIModalPresentationStyle = .automatic, completion: (() -> Void)? = nil) {
        let webvc = WebViewController(url: URL)
        webvc.modalPresentationStyle = style
        UIViewController.topMostViewController()?.present(webvc, animated: true, completion: completion)
    }

    // MARK: - Initialization

    init(url URL: URL) {
        super.init(url: URL, configuration: Self.Configuration())
    }

    // MARK: - Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()
        configureLayout()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        AppUtil.lock(.allButUpsideDown)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }

    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        AppUtil.lockOrientation(.portrait, andRotateTo: .portrait)

        super.dismiss(animated: flag, completion: completion)
    }

    // MARK: - Layout

    func configureLayout() {
        preferredBarTintColor = Color.viewTint
        preferredControlTintColor = Color.blue
        dismissButtonStyle = .close
    }

}
