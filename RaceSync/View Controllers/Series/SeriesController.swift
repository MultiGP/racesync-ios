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
    let series: Series
    let pilotResultViewModels: [SeriesResultViewModel]
    let chapterResultViewModels: [SeriesResultViewModel]
    let seriesApi = SeriesApi()

    var menuCompletion: BoolCompletionBlock? = nil

    // MARK: - Private

    fileprivate var visibleViewController: UIViewController? {
        UIViewController.topMostViewController()
    }

    // MARK: - Initialization

    init(with series: Series) {
        self.series = series
        self.pilotResultViewModels = SeriesResultViewModel.viewModels(with: series.pilotResults,
                                                                      scoreType: series.scoreType)

        self.chapterResultViewModels = SeriesResultViewModel.viewModels(with: series.chapterResults,
                                                                        scoreType: series.scoreType)
    }

    // MARK: - Data Update


    // MARK: - Actions

    func showShareMenu() {

        let url = MGPWeb.getURL(for: .seriesView, value: series.id)
        let items: [Any] = [url]

        var activities = [UIActivity]()
        activities += [MGPActivity(), CopyLinkActivity()]

        let vc = UIActivityViewController(activityItems: items, applicationActivities: activities)
        vc.excludeAllActivityTypes(except: [.airDrop])
        visibleViewController?.present(vc, animated: true)
    }

    // MARK: - Navigation Action Builders

    enum SeriesAction: Int, CaseIterable {
        case edit, share
        
        var image: UIImage? {
            switch self {
                case .edit:     return ButtonImg.edit
                case .share:    return ButtonImg.share
            }
        }

        func makeButton(target: Any?, action: Selector) -> UIBarButtonItem {
            return UIBarButtonItem(image: image, style: .plain, target: target, action: action)
        }
    }

    func navigationItems(for options: [SeriesAction] = [.edit, .share]) -> [UIBarButtonItem]{
        guard !options.isEmpty else { return [UIBarButtonItem]() }
        
        let filtered = options.filter { option in
            switch option {
                case .edit:         return series.canBeEdited
                case .share:        return true
            }
        }.sorted { $0.rawValue > $1.rawValue }
        
        if #available(iOS 26, *) {
            return filtered.map { option in
                let item = option.makeButton(target: self, action: #selector(seriesActionTapped(_:)))
                item.tag = option.rawValue
                return item
            }.interspersed(with: UIBarButtonItem.spacer())
        } else {
            // Still needed for versions of iOS previous to iOS26
            let actions = options.map { (image: $0.image, selector: #selector(seriesActionTapped(_:)), tag: $0.rawValue) }
            return [UIBarButtonItem.stackedBarButtonItem(for: actions)]
        }
    }

    @objc private func seriesActionTapped(_ sender: UIButton) {
        guard let action = SeriesAction(rawValue: sender.tag) else { return }
        showContextualMenu(action)
    }

    func showContextualMenu(_ action: SeriesAction, completion: BoolCompletionBlock? = nil) {

        menuCompletion = completion

        switch action {
        case .edit:
            return
        case .share:
            showShareMenu()
        }
    }
}
