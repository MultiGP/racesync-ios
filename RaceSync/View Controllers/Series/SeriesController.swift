//
//  SeriesController.swift
//  RaceSync
//
//  Created by Ignacio Romero Zurbuchen on 2026-01-09.
//  Copyright © 2026 MultiGP Inc. All rights reserved.
//

import RaceSyncAPI
import UIKit

class SeriesController {

    // MARK: - Public

    var seriesId: ObjectId
    var series: Series

    let seriesApi = SeriesApi()

    var menuCompletion: BoolCompletionBlock? = nil

    // MARK: - Private

    fileprivate var visibleViewController: UIViewController? {
        UIViewController.topMostViewController()
    }

    // MARK: - Initialization

    init(with series: Series) {
        self.seriesId = series.id
        self.series = series
    }

    // MARK: - Data Update


    // MARK: - Actions

    func showShareMenu() {

        let url = MGPWeb.getURL(for: .seriesView, value: seriesId)
        let items: [Any] = [url]

        var activities = [UIActivity]()
        activities += [MGPActivity(), CopyLinkActivity()]

        let vc = UIActivityViewController(activityItems: items, applicationActivities: activities)
        vc.excludeAllActivityTypes(except: [.airDrop])
        visibleViewController?.present(vc, animated: true)
    }

    // MARK: - Navigation Action Builders

    enum SeriesAction: Int, CaseIterable {
        case share

        func makeButton(target: Any?, action: Selector) -> UIButton {
            let button = CustomButton(type: .system)
            var image: UIImage?

            switch self {
            case .share:    image = ButtonImg.share
            }

            button.setImage(image, for: .normal)
            button.addTarget(target, action: action, for: .touchUpInside)
            return button
        }
    }

    func navigationItems(for options: [SeriesAction] = [.share]) -> UIBarButtonItem? {
        guard !options.isEmpty else { return nil }

        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.alignment = .lastBaseline
        stackView.spacing = 12

        for option in options {
            let button = option.makeButton(target: self, action: #selector(seriesActionTapped(_:)))
            button.tag = option.rawValue
            stackView.addArrangedSubview(button)
        }

        return UIBarButtonItem(customView: stackView)
    }

    @objc private func seriesActionTapped(_ sender: UIButton) {
        guard let action = SeriesAction(rawValue: sender.tag) else { return }
        showContextualMenu(action)
    }

    func showContextualMenu(_ action: SeriesAction, completion: BoolCompletionBlock? = nil) {

        menuCompletion = completion

        switch action {
        case .share:
            showShareMenu()
        }
    }
}
