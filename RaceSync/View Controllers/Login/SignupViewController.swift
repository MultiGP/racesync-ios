//
//  SignupViewController.swift
//  RaceSync
//
//  Created by Ignacio Romero Zurbuchen on 2025-02-27.
//  Copyright © 2025 MultiGP Inc. All rights reserved.
//

import UIKit
import RaceSyncAPI
import SnapKit

class SignupViewController: UIViewController {

    // MARK: - Private Variables

    fileprivate lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.register(cellType: FormTableViewCell.self)
        tableView.contentInsetAdjustmentBehavior = .always
        tableView.tableFooterView = UIView()
        tableView.dataSource = self
        tableView.delegate = self

        let backgroundView = UIView()
        backgroundView.backgroundColor = Color.gray20
        tableView.backgroundView = backgroundView

        return tableView
    }()

    fileprivate lazy var activityIndicatorView: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(style: .medium)
        view.hidesWhenStopped = true
        return view
    }()

    fileprivate lazy var rightBarButtonItem: UIBarButtonItem = {
        let title = (currentSection == .specific) ? "Submit" : "Next"
        let item = UIBarButtonItem(title: title, style: .done, target: self, action: #selector(didPressNextButton))
        item.isEnabled = canGoNextSection()
        return item
    }()

    fileprivate var sections: [SignupFormSection: [SignupFormRow]] {
        get {
            return [.general: [.firstName, .lastName, .dob, .gender, .country],
                    .specific: [.username, .email, .password, .isPublic]]
        }
    }

    fileprivate enum Constants {
        static let padding: CGFloat = UniversalConstants.padding
        static let cellHeight: CGFloat = 56
    }

    fileprivate var data: UserData = UserData()
    fileprivate var currentSection: SignupFormSection = .general
    fileprivate var selectedRow: SignupFormRow?

    fileprivate let presenter = Appearance.defaultPresenter()
    fileprivate var formNavigationController: NavigationController?
    fileprivate var isFormEnabled: Bool = true

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

//        // Bring up keyboard on first row, if applicable
//        if isFormEnabled, currentSection == .general, editMode == .new {
//            let rows = currentSectionRows()
//
//            DispatchQueue.main.async { [weak self] in
//                if let firstRow = rows?.first, firstRow.formType == .textfield {
//                    self?.showTextField(forRow: firstRow)
//                    self?.selectedRow = firstRow
//                }
//            }
//        }
    }

    // MARK: - Layout

    fileprivate func setupLayout() {

        title = "Register with MultiGP"

        view.backgroundColor = Color.white
        navigationItem.rightBarButtonItem = rightBarButtonItem

//        // Adds a close button in case of being presented modally
//        if navigationController?.viewControllers.count == 1 {
//            navigationItem.leftBarButtonItem = UIBarButtonItem(image: ButtonImg.close, style: .done, target: self, action: #selector(didPressCloseButton))
//        }

        view.addSubview(tableView)
        tableView.snp.makeConstraints {
            $0.top.leading.trailing.bottom.equalToSuperview()
        }
    }

    // MARK: - Actions

    @objc func didPressNextButton() {

        // Move to next step
//        if currentSection == .general {
//            let nextSection: RaceFormSection = .specific
//            let vc = RaceFormViewController(with: chapters, raceData: data, initialRaceData: initialData, section: nextSection)
//            vc.editMode = editMode
//            vc.delegate = delegate
//
//            navigationController?.pushViewController(vc, animated: true)
//        } else if currentSection == .specific {
//
//            func handleSubmission() {
//                switch editMode {
//                case .new:      createRace()
//                case .update:   editRace()
//                }
//            }
//
//            if data.sendNotification {
//                AlertUtil.presentAlertMessage("You are about to notify all the chapter members of \(data.chapterName). Are you sure?", title: "Heads Up", buttonTitle: "Send it!") { action in
//                    handleSubmission()
//                }
//            } else {
//                handleSubmission()
//            }
//        }
    }

    @objc fileprivate func didChangeSwitchValue(_ sender: UISwitch) {
        guard let rows = currentSectionRows() else { return }
        let row = rows[sender.tag]

        if row == .isPublic {
            data.isPublic = sender.isOn
        }
    }

    func showTextPicker(forRow row: SignupFormRow, pushed: Bool) {
        let values = values(for: row)
        let rowValue = row.value(from: data)

        let vc = TextPickerViewController(with: values, selectedItem: rowValue)
        vc.delegate = self
        vc.title = row.title

        if pushed {
            formNavigationController?.pushViewController(vc, animated: true)
            formNavigationController?.delegate = self
        } else {
            let nc = NavigationController(rootViewController: vc)
            customPresentViewController(presenter, viewController: nc, animated: true)

            if formNavigationController == nil {
                formNavigationController = nc
            }
        }
    }
}

fileprivate extension SignupViewController {

    func values(for row: SignupFormRow) -> [String] {
        switch row {

        case .country:
            let countryCodes = Locale.isoRegionCodes
            return countryCodes.compactMap { Locale.current.localizedString(forRegionCode: $0) }

//        case .firstName:
//            return data.firstName
//        case .lastName:
//            return data.lastName
//        case .chapter:
//            return chapters.compactMap { $0.name }
//        case .class:
//            return RaceClass.allCases.compactMap { $0.title }
//        case .format:
//            return ScoringFormat.allCases.compactMap { $0.title } // TODO: Implemented Global Qualifier support
//        case .schedule:
//            return QualifyingType.allCases.compactMap { $0.title }
//        case .privacy:
//            return EventType.allCases.compactMap { $0.title }
//        case .status:
//            return RaceStatus.allCases.compactMap { $0.title }
//        case .rounds:
//            return ["1","2","3","4","5","6","7","8","9","10"]
        default:
            return [String]()
        }
    }

    func showDatePicker(forRow row: SignupFormRow, pushed: Bool) {
        let date = data.dob ?? Date()

        let vc = DatePickerViewController(with: date)
        vc.title = row.title
        vc.delegate = self

        formNavigationController?.pushViewController(vc, animated: true)
        formNavigationController?.delegate = self
    }

    func currentSectionRows() -> [SignupFormRow]? {
        return sections[currentSection]
    }

    func currentSectionRequiredRows() -> [SignupFormRow] {
        guard let rows = currentSectionRows() else { return [SignupFormRow]() }

        return rows.filter({ (row) -> Bool in
            return row.isRowRequired
        })
    }

    // MARK: - Verification

    func canGoNextSection() -> Bool {
        for row in currentSectionRequiredRows() {
            if let value = row.requiredValue(from: data) {
                if value.isEmpty { return false }
            } else {
                return false
            }
        }
        return true
    }
}

// MARK: - UITableView Delegate

extension SignupViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

//        guard let rows = currentSectionRows() else { return }
//        guard let cell = tableView.cellForRow(at: indexPath) as? FormTableViewCell else { return }
//
//        let row = rows[indexPath.row]
//
//        if row.formType != .undefined {
//            selectedRow = row
//        }
//
//        if row.formType == .textfield {
//            showTextField(forRow: row)
//        } else if row.formType == .datePicker {
//            showDatePicker(forRow: row, pushed: false)
//            showDatePicker(forRow: row, pushed: false)
//        } else if row.formType == .textPicker {
//            if row == .season {
//                showSeasonPicker(for: row, cell: cell)
//            } else if row == .location {
//                showCoursePicker(for: row, cell: cell)
//            } else {
//                showTextPicker(forRow: row, pushed: false)
//            }
//        } else if row.formType == .textEditor {
//            showTextViewController(forRow: row)
//        }
    }
}

// MARK: - UITableView DataSource

extension SignupViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection sectionIdx: Int) -> Int {
        guard let rows = currentSectionRows() else { return 0 }
        return rows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(forIndexPath: indexPath) as FormTableViewCell
        guard let rows = currentSectionRows() else { return cell }

        let row = rows[indexPath.row]
        let rowValue = row.value(from: data)

        if row.isRowRequired {
            cell.textLabel?.text = row.title + " *"
        } else {
            cell.textLabel?.text = row.title
        }

        cell.textLabel?.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        cell.textLabel?.textColor = Color.black

        cell.detailTextLabel?.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        cell.detailTextLabel?.textColor = Color.gray300

        if row.formType == .switch {
            let accessory = UISwitch()
            accessory.tag = currentSectionRows()?.firstIndex(of: row) ?? 0
            accessory.addTarget(self, action: #selector(didChangeSwitchValue(_:)), for: .valueChanged)
            accessory.isOn = (rowValue != nil)
            cell.accessoryView = accessory
            cell.detailTextLabel?.text = nil
        } else {
            cell.detailTextLabel?.text = rowValue
            cell.accessoryType = .disclosureIndicator
            cell.accessoryView = nil
        }

        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return Constants.cellHeight
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return currentSection.header
    }

    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return currentSection.footer
    }
}

// MARK: - TextFieldViewController Delegate

extension SignupViewController: FormBaseViewControllerDelegate {

    func formViewController(_ viewController: FormBaseViewController, didSelectItem item: String) {
        guard let row = selectedRow else { return }

//        switch row {
//        case .name:
//            data.name = item
//            title = item
//        case .startDate:
//
//            // Incrementing the end date, when adjusting the start date
//            if let startDate = data.startDate, let endDate = data.endDate {
//
//                let newStart = DateUtil.standardDateFormatter.date(from: item)
//                let diff = endDate.timeIntervalSince(startDate)
//
//                if diff > 0 {
//                    if let newEnd = newStart?.addingTimeInterval(diff) {
//                        data.endDateString = DateUtil.standardDateFormatter.string(from: newEnd)
//                    }
//                } else if let minDate = newStart?.date(with: 30, type: .minute) {
//                    data.endDateString = DateUtil.standardDateFormatter.string(from: minDate)
//                }
//            }
//
//            data.startDateString = item
//        case .endDate:
//            data.endDateString = item
//        case .chapter:
//            if let chapter = chapters.filter ({ return $0.name == item }).first {
//                data.chapterName = chapter.name
//                data.chapterId = chapter.id
//            }
//        case .class:
//            if let value = RaceClass(title: item)?.rawValue {
//                data.raceClass = value
//            }
//        case .format:
//            if let value = ScoringFormat(title: item)?.rawValue {
//                data.format = value
//            }
//        case .schedule:
//            if let value = QualifyingType(title: item)?.rawValue {
//                data.qualifying = value
//            }
//        case .privacy:
//            if let value = EventType(title: item)?.rawValue {
//                data.privacy = value
//            }
//        case .status:
//            if let value = RaceStatus(title: item)?.rawValue {
//                data.status = value
//            }
//        case .rounds:
//            data.rounds = (item as NSString).intValue
//        case .season:
//            if let season = seasons?.filter ({ return $0.name == item }).first {
//                data.seasonId = season.id
//                data.seasonName = season.name
//            }
//        case .location:
//            if let course = courses?.filter ({ return $0.name == item }).first {
//                data.courseId = course.id
//                data.courseName = course.name
//            }
//        default:
//            break
//        }

        // refresh content
        if !item.isEmpty {
            tableView.reloadData()
            navigationItem.rightBarButtonItem?.isEnabled = canGoNextSection()
        }

        // handle next row
        if isFormEnabled, let rows = currentSectionRows(), row.rawValue < rows.count-1  {
            guard let nextRow = SignupFormRow(rawValue: row.rawValue + 1) else { return }

            if nextRow.formType == .textPicker {
                selectedRow = nextRow
                showTextPicker(forRow: nextRow, pushed: true)
            } else if nextRow.formType == .datePicker {
                selectedRow = nextRow
                showDatePicker(forRow: nextRow, pushed: true)
            }
        } else {
            formViewControllerDidDismiss(viewController)
        }
    }

    func formViewControllerDidDismiss(_ viewController: FormBaseViewController) {
        // invalidate form once reaching the section
//        isFormEnabled = false
//        selectedRow = nil

        viewController.dismiss(animated: true)
    }

    func formViewController(_ viewController: FormBaseViewController, enableSelectionWithItem item: String) -> Bool {
        guard let row = selectedRow else { return false }

        if row.formType == .textfield {
            guard item.count >= 3 else { return false }
        }

        if row.isRowRequired {
            return !item.isEmpty
        }

        return true
    }

    func formViewControllerRightBarButtonTitle(_ viewController: FormBaseViewController) -> String {
        guard let row = selectedRow, let rows = currentSectionRows() else { return "" }

        if isFormEnabled, row.rawValue < rows.count-1 {
            return "Next"
        }
        return "OK"
    }

    func formViewControllerKeyboardReturnKeyType(_ viewController: FormBaseViewController) -> UIReturnKeyType {
        return isFormEnabled ? .next : .done
    }
}

// MARK: - UINavigationControllerDelegate Delegate

extension SignupViewController: UINavigationControllerDelegate {

    func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationController.Operation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        guard let row = selectedRow else { return nil }

        if operation == .pop {
            selectedRow = SignupFormRow(rawValue: row.rawValue - 1)
        }

        return nil
    }
}
