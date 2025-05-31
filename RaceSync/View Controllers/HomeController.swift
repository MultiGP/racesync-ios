//
//  HomeController.swift
//  RaceSync
//
//  Created by Ignacio Romero Zurbuchen on 2020-03-05.
//  Copyright © 2020 MultiGP Inc. All rights reserved.
//

import UIKit
import RaceSyncAPI

class HomeController {

    static func homeViewController() -> UIViewController {

        let api = StandingApi()
        api.getStandings(forSeason: "2025") { (standings, error) in

        }

        let settings = APIServices.shared.settings
        let filters = settings.raceFeedFilters

        let vc = RaceFeedViewController(filters, selectedFilter: filters.first!)
        return NavigationController(rootViewController: vc)
    }
}
