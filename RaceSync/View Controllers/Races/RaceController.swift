//
//  RaceController.swift
//  RaceSync
//
//  Created by Ignacio Romero Zurbuchen on 2025-09-16.
//  Copyright © 2025 MultiGP Inc. All rights reserved.
//

import RaceSyncAPI
import UIKit

class RaceController {

    // MARK: - Public

    var raceId: ObjectId
    var race: Race?
    let raceApi = RaceApi()

    var parentViewController: RaceTabBarController? = nil
    var isLoading: Bool = false

    // MARK: - Private

    fileprivate var visibleViewController: UIViewController? {
        UIViewController.topMostViewController()
    }

    fileprivate var visibleNavigationController: NavigationController? {
        (visibleViewController as? NavigationController)
        ?? (visibleViewController?.navigationController as? NavigationController)
    }

    // MARK: - Initialization

    init(with race: Race) {
        self.raceId = race.id
        self.race = race
    }

    init(id raceId: ObjectId) {
        self.raceId = raceId
        self.race = nil
    }

    // MARK: - Data Update

    public func loadRace(completion: @escaping ObjectCompletionBlock<Race>) {
        guard !isLoading else { return }

        isLoading = true

        raceApi.view(race: raceId) { [weak self] race, error in
            guard let self = self else { return }

            if let race = race {
                // TODO: Temporary hack since race/view API doesn't include the raceOwnerName attribute
                // See issue https://github.com/MultiGP/multigp-com/issues/88
                race.ownerUserName = self.race?.ownerUserName ?? ""
                self.race = race
            }

            self.isLoading = false
            completion(self.race, error)
        }
    }

    public func reloadRace() {

        raceApi.view(race: raceId) { [weak self] race, error in
            guard let self = self else { return }

            if let race = race {
                // TODO: Temporary hack since race/view API doesn't include the raceOwnerName attribute
                // See issue https://github.com/MultiGP/multigp-com/issues/88
                race.ownerUserName = self.race?.ownerUserName ?? ""
                self.race = race

                reloadContentViews()
            }
        }
    }

    public func reloadContentViews() {
        parentViewController?.reloadRaceTabs()
    }

    public func raceUserViewModels() -> [UserViewModel] {
        var viewModels = [UserViewModel]()

        guard let race = race else { return viewModels }

        func populateScore(in userViewModels: [UserViewModel]) {
            guard race.isGQ == false else { return } // Don't display points for GQ race results

            for vm in userViewModels {
                if let raceEntry = race.entries?.filter ({ return $0.pilotId == vm.userId }).first {
                    vm.score = raceEntry.score
                }
            }
        }

        if race.canShowResults, let results = ResultEntryViewModel.combinedResults(from: race.results, for: race.trueScoringFormat) {
            viewModels += UserViewModel.viewModelsFromResults(results)
            populateScore(in: viewModels)
        }

        if let entries = race.entries, entries.count > 0 {
            // We need to include the pilots that didn't complete laps still
            if viewModels.count > 0, viewModels.count < entries.count {
                viewModels += UserViewModel.viewModels(viewModels, withoutResults: entries)
                populateScore(in: viewModels)

            // No race results, so let's just populate with race entries instead
            } else if viewModels.count == 0 {
                viewModels += UserViewModel.viewModelsFromEntries(entries)
            }
        }

        return viewModels
    }

    // MARK: - Actions

    @objc func didPressEditButton() {
        guard let race = race else { return }

        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.view.tintColor = Color.blue

        if race.canBeEdited {
            alert.addAction(makeEditRaceAction())
            alert.addAction(makeManagePilotsAction())
        }

        if race.canChangeEnrollment {
            alert.addAction(makeEnrollmentToggleAction(for: race))
        }

        if race.canBeDuplicated {
            alert.addAction(makeDuplicateAction())
        }

        if race.canBeFinalized {
            alert.addAction(makeFinalizeAction(for: race))
        }

        if race.canBeDeleted {
            alert.addAction(makeDeleteAction(for: race))
        }

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        visibleViewController?.present(alert, animated: true)
    }

    @objc func didPressCalendarButton() {
        guard let race = race, let event = race.createCalendarEvent(with: race.id) else { return }

        ActionSheetUtil.presentActionSheet(
            withTitle: "Save the race details to your calendar?",
            buttonTitle: "Save to Calendar", completion: { (action) in
            CalendarUtil.add(event)
        })
    }

    @objc public func didPressShareButton() {
        guard let race = race else { return }

        let url = MGPWeb.getURL(for: .raceView, value: race.id)

        var items: [Any] = [url]
        var activities = [UIActivity]()

        if race.canManagePayments {
            activities += [PaypalActivity()]
        }

        activities += [MultiGPActivity(), CopyLinkActivity()]

        // Calendar integration
        if let event = race.createCalendarEvent(with: raceId) {
            items += [event]
            activities += [CalendarActivity()]
        }

        let vc = UIActivityViewController(activityItems: items, applicationActivities: activities)
        vc.excludeAllActivityTypes(except: [.airDrop])
        visibleViewController?.present(vc, animated: true)
    }

    @objc fileprivate func didPressZippyQButton() {
        guard let race = race else { return }

        let url = MGPWeb.getURL(for: .zippyqView, value: race.id)

        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }

    // MARK: - Navigation Action Builders

    enum RaceAction: Int, CaseIterable {
        case edit, calendar, share, zippyQ

        func makeButton(target: Any?, action: Selector) -> UIButton {
            let button = CustomButton(type: .system)
            var image: UIImage?

            switch self {
            case .edit:     image = ButtonImg.edit
            case .calendar: image = ButtonImg.calendar
            case .share:    image = ButtonImg.share
            case .zippyQ:   image = ButtonImg.safari
            }

            button.setImage(image, for: .normal)
            button.addTarget(target, action: action, for: .touchUpInside)
            return button
        }
    }

    func navigationItems(for options: [RaceAction] = [.edit, .calendar, .share]) -> UIBarButtonItem? {
        guard let race = race else { return nil }
        guard !options.isEmpty else { return nil }

        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.alignment = .lastBaseline
        stackView.spacing = 12

        for option in options {
            if (option == .edit && !race.canBeEdited) { continue }
            if (option == .calendar && !race.canCreateCalendarEvent()) { continue }
            if (option == .zippyQ && !race.isZippyQEnabled) { continue }

            let button = option.makeButton(target: self, action: #selector(raceActionTapped(_:)))
            button.tag = option.rawValue
            stackView.addArrangedSubview(button)
        }

        return UIBarButtonItem(customView: stackView)
    }

    @objc private func raceActionTapped(_ sender: UIButton) {
        guard let option = RaceAction(rawValue: sender.tag) else { return }

        switch option {
        case .edit:
            didPressEditButton()
        case .calendar:
            didPressCalendarButton()
        case .share:
            didPressShareButton()
        case .zippyQ:
            didPressZippyQButton()
        }
    }

    // MARK: - Alert Action Builders

    fileprivate func makeEditRaceAction() -> UIAlertAction {
        UIAlertAction(title: "Edit Race", style: .default) { [weak self] _ in
            self?.editRace()
        }
    }

    fileprivate func makeManagePilotsAction() -> UIAlertAction {
        UIAlertAction(title: "Manage Pilots", style: .default) { [weak self] _ in
            self?.managePilots()
        }
    }

    fileprivate func makeEnrollmentToggleAction(for race: Race) -> UIAlertAction {
        let isClosed = (race.status == .closed)
        let title = isClosed ? "Open Enrollment" : "Close Enrollment"
        let message = isClosed ? "Are you sure you want to open race enrollment?" : "Are you sure you want to close race enrollment?"

        return UIAlertAction(title: title, style: .default) { [weak self] _ in
            ActionSheetUtil.presentActionSheet(
                withTitle: message, completion: { [weak self] _ in
                self?.toggleRaceEnrollment()
            })
        }
    }

    fileprivate func makeDuplicateAction() -> UIAlertAction {
        UIAlertAction(title: "Duplicate", style: .default) { [weak self] _ in
            self?.duplicateRace()
        }
    }

    fileprivate func makeFinalizeAction(for race: Race) -> UIAlertAction {
        UIAlertAction(title: "Finalize", style: .destructive) { [weak self] _ in
            ActionSheetUtil.presentDestructiveActionSheet(
                withTitle: "Are you sure you want to finalize \"\(race.name)\"?",
                message: "Finalizing this race will close enrollment, email the results to the pilots, and initialize the next race if configured.",
                destructiveTitle: "Yes, Finalize", completion: { [weak self] _ in
                    self?.finalizeRace()
                })
        }
    }

    fileprivate func makeDeleteAction(for race: Race) -> UIAlertAction {
        UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            ActionSheetUtil.presentDestructiveActionSheet(
                withTitle: "Are you sure you want to delete \"\(race.name)\"?",
                destructiveTitle: "Yes, Delete", completion: { [weak self] _ in
                    self?.deleteRace()
                })
        }
    }

    // MARK: - Race Editing

    func editRace() {
        guard let race = race else { return }
        guard let chapters = APIServices.shared.myManagedChapters, chapters.count > 0 else { return }
        guard let chapter = chapters.filter ({ return $0.id == race.chapterId }).first else { return }

        let data = RaceData(with: race)
        let initialData = RaceData(with: race)

        let vc = RaceFormViewController(with: [chapter], raceData: data, initialRaceData: initialData, section: .general)
        vc.editMode = .update
        vc.delegate = self

        let nc = NavigationController(rootViewController: vc)
        nc.modalPresentationStyle = .fullScreen
        visibleViewController?.present(nc, animated: true)
    }

    func managePilots() {
        guard let race = race else { return }
        let vc = RacePilotsPickerController(with: race)
        vc.externalUserViewModels = raceUserViewModels()
        vc.delegate = self

        let nc = NavigationController(rootViewController: vc)
        nc.modalPresentationStyle = .fullScreen
        visibleViewController?.present(nc, animated: true)
    }

    func toggleRaceEnrollment() {
        guard let race = race else { return }

        if race.status == .closed {
            raceApi.open(race: race.id) { [weak self] status, error in
                if status == true {
                    self?.reloadRace()
                } else if let error = error {
                    AlertUtil.presentAlertMessage("Couldn't open this race. Please try again later. \(error.localizedDescription)", title: "Error", delay: 0.5)
                }
            }
        } else {
            raceApi.close(race: race.id) { [weak self] status, error in
                if status == true {
                    self?.reloadRace()
                } else if let error = error {
                    AlertUtil.presentAlertMessage("Couldn't close this race. Please try again later. \(error.localizedDescription)", title: "Error", delay: 0.5)
                }
            }
        }
    }

    func duplicateRace() {
        guard let race = race else { return }
        guard let chapters = APIServices.shared.myManagedChapters, chapters.count > 0 else { return }

        let data = RaceData(with: race)

        let vc = RaceFormViewController(with: chapters, raceData: data, section: .general)
        vc.editMode = .new
        vc.delegate = self

        let nc = NavigationController(rootViewController: vc)
        nc.modalPresentationStyle = .fullScreen
        visibleViewController?.present(nc, animated: true)
    }

    func finalizeRace() {
        guard let race = race else { return }
        raceApi.finalizeRace(with: race.id) { status, error in
            if status {
                self.reloadRace()
            } else if let error = error {
                AlertUtil.presentAlertMessage("Couldn't finalize this race. Please try again later. \(error.localizedDescription)", title: "Error", delay: 0.5)
            }
        }
    }

    func deleteRace() {
        guard let race = race else { return }
        raceApi.deleteRace(with: race.id) { status, error in
            if status == true {
                self.visibleNavigationController?.popViewController(animated: true)
            } else if let error = error {
                AlertUtil.presentAlertMessage("Couldn't delete this race. Please try again later. \(error.localizedDescription)", title: "Error", delay: 0.5)
            }
        }
    }
}

extension RaceController: RaceFormViewControllerDelegate {

    func raceFormViewController(_ viewController: RaceFormViewController, didUpdateRace race: Race) {

        switch viewController.editMode {
        case .update:
            self.race = race
            self.reloadRace()
            viewController.dismiss(animated: true, completion: nil)
        case .new:
            let vc = RaceTabBarController(with: race)
            vc.isDismissable = true
            viewController.navigationController?.pushViewController(vc, animated: true)

            if let nc = viewController.presentingViewController as? NavigationController {
                nc.popViewController(animated: false) // let's pop, so when the current view is dismissed, we see the list of races
            }
        }
    }

    func raceFormViewControllerDidDismiss(_ viewController: RaceFormViewController) {
        viewController.dismiss(animated: true, completion: nil)
    }
}

extension RaceController: RacePilotsPickerControllerDelegate {

    func pickerControllerDidUpdate(_ viewController: RacePilotsPickerController) {
        reloadRace()
    }
}
