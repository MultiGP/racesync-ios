//
//  RaceEditable.swift
//  RaceSync
//
//  Created by Ignacio Romero Zurbuchen on 2025-12-18.
//  Copyright © 2025 MultiGP Inc. All rights reserved.
//

import UIKit
import RaceSyncAPI

protocol RaceEditable: UIViewController {

    var tableView: UITableView  { get }
    var raceController: RaceController? { get set }

    func didLongPress(_ gesture: UIGestureRecognizer)
    func loadContent(forced: Bool)
    func raceViewModel(for index: Int) -> RaceViewModel?

    // Default implementation
    func handleLongPress(_ gesture: UIGestureRecognizer)
}

extension RaceEditable {

    func handleLongPress(_ gesture: UIGestureRecognizer) {
        let location = gesture.location(in: tableView)
        guard let indexPath = tableView.indexPathForRow(at: location) else { return }

        if gesture.state == .began {
            tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
        } else {
            tableView.deselectRow(at: indexPath, animated: true)
            return
        }

        guard let viewModel = raceViewModel(for: indexPath.row), viewModel.race.canBeEdited else { return }

        raceController = RaceController(with: viewModel.race)
        raceController?.showContextualMenu(.edit, completion: { [weak self] status in
            guard status else { return }
            self?.loadContent(forced: true)
        })
    }
}
