//
//  RaceFormViewController.swift
//  RaceSync
//
//  Created by Ignacio Romero Zurbuchen on 2022-12-26.
//  Copyright © 2022 MultiGP Inc. All rights reserved.
//

import Foundation
import RaceSyncAPI
import SnapKit
import UIKit

protocol RaceFormViewControllerDelegate {
    func raceFormViewController(_ viewController: RaceFormViewController, didUpdateRace race: Race)
    func raceFormViewControllerDidDismiss(_ viewController: RaceFormViewController)
}

class RaceFormViewController: UIViewController {

    // MARK: - Public Variables

    var editMode: RaceFormMode = .new
    var delegate: RaceFormViewControllerDelegate?

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
        let title = (currentSection == .specific) ? "Save" : "Next"
        let item = UIBarButtonItem(title: title, style: .done, target: self, action: #selector(goNextSection))
        item.isEnabled = canGoNextSection()
        return item
    }()

    fileprivate var isLoading: Bool = false {
        didSet {
            if isLoading {
                navigationItem.rightBarButtonItem = UIBarButtonItem(customView: activityIndicatorView)
                view.isUserInteractionEnabled = false
                activityIndicatorView.startAnimating()
            }
            else {
                navigationItem.rightBarButtonItem = rightBarButtonItem
                view.isUserInteractionEnabled = true
                activityIndicatorView.stopAnimating()
            }
        }
    }

    fileprivate var data: RaceData
    fileprivate var initialData: RaceData?

    fileprivate var currentSection: RaceFormSection
    fileprivate var selectedRow: RaceFormRow? {
        didSet {
            print("Selected Row : \(String(describing: selectedRow?.title))")
        }
    }

    fileprivate var chapters: [ManagedChapter]
    fileprivate var seasons: [Season]?
    fileprivate var courseApi = CourseApi()
    fileprivate var courses: [Course]?
    fileprivate var raceApi = RaceApi()
    fileprivate var seasonApi = SeasonApi()

    fileprivate let presenter = Appearance.defaultPresenter()
    fileprivate var formNavigationController: NavigationController?
    fileprivate var isQuickFormActive: Bool = false

    // Needs to be computed each time, since there are dynamic values
    fileprivate var sections: [RaceFormSection: [RaceFormRow]] {
        get {
            var general: [RaceFormRow] = [.name, .startDate, .endDate, .chapter, .location, .season, .privacy]

            // Payments are enabled at a chapter level
            if let chapter = chapters.filter ({ return $0.id == data.chapterId }).first, chapter.paymentsEnabled {
                general += [.fee, .feeRequired]
            }

            var specific: [RaceFormRow] = [.scoring, .class, .format, .schedule]

            // Only applicable for ZippyQ
            if data.qualifying == QualifyingType.open.rawValue {
                specific += [.rounds, .zDepth, .zIterator, .zNoKiosk]
            }

            specific += [.content, .notify]

            return [.general: general, .specific: specific]
        }
    }

    fileprivate enum Constants {
        static let padding: CGFloat = UniversalConstants.padding
        static let cellHeight: CGFloat = 56
    }

    // MARK: - Initialization

    init(with chapters: [ManagedChapter], selectedChapterId: ObjectId, selectedChapterName: String) {
        self.chapters = chapters
        self.data = RaceData(with: selectedChapterId, chapterName: selectedChapterName)
        self.currentSection = .general
        self.isQuickFormActive = true

        super.init(nibName: nil, bundle: nil)
        self.title = "New Event"
    }

    init(with chapters: [ManagedChapter], raceData: RaceData, initialRaceData: RaceData? = nil, section: RaceFormSection = .general) {
        self.chapters = chapters
        self.data = raceData
        self.initialData = initialRaceData
        self.currentSection = section

        super.init(nibName: nil, bundle: nil)
        self.title = data.name
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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

        if isQuickFormActive, editMode == .new {
            DispatchQueue.main.async { [weak self] in
                self?.showFormForNextRow(true)
            }
        }
    }

    // MARK: - Layout

    fileprivate func setupLayout() {
        view.backgroundColor = Color.white
        navigationItem.rightBarButtonItem = rightBarButtonItem

        // Adds a close button in case of being presented modally
        if navigationController?.viewControllers.count == 1 {
            navigationItem.leftBarButtonItem = UIBarButtonItem(image: ButtonImg.close, style: .done, target: self, action: #selector(didPressCloseButton))
        }

        view.addSubview(tableView)
        tableView.snp.makeConstraints {
            $0.top.leading.trailing.bottom.equalToSuperview()
        }
    }

    // MARK: - Actions

    fileprivate func createRace() {
        isLoading = true

        let params = data.toParams()
        print("Creating race with params: \(params)")

        raceApi.createRace(withData: data) { object, error in
            if let race = object {
                self.delegate?.raceFormViewController(self, didUpdateRace: race)
            } else if let error = error {
                AlertUtil.presentAlertMessage("Failed to create the race. \(error.localizedDescription)", title: "Error", delay: 0.5)
                self.isLoading = false
            }
        }
    }

    fileprivate func editRace() {
        guard let id = data.raceId else { return }

        isLoading = true

        raceApi.updateRace(race: id, with: initialData, afterData: data) { object, error in
            if let race = object {
                self.delegate?.raceFormViewController(self, didUpdateRace: race)
            } else if let error = error {
                AlertUtil.presentAlertMessage("Failed to update the race. \(error.localizedDescription)", title: "Error", delay: 0.5)
                self.isLoading = false
            }
        }
    }

    @objc fileprivate func didChangeSwitchValue(_ sender: UISwitch) {
        guard let rows = currentSectionRows() else { return }
        let row = rows[sender.tag]

        if row == .feeRequired {
            data.feeRequired = sender.isOn
        } else if row == .scoring {
            data.funfly = sender.isOn
        } else if row == .zNoKiosk {
            data.zippyqNoKiosk = sender.isOn
        } else if row == .notify {
            data.sendNotification = sender.isOn
        }
    }

    @objc fileprivate func goNextSection() {
        // Move to next step
        if currentSection == .general {
            let nextSection: RaceFormSection = .specific
            let vc = RaceFormViewController(with: chapters, raceData: data, initialRaceData: initialData, section: nextSection)
            vc.isQuickFormActive = isQuickFormActive
            vc.editMode = editMode
            vc.delegate = delegate

            navigationController?.pushViewController(vc, animated: true)
        } else if currentSection == .specific {

            func handleSubmission() {
                switch editMode {
                case .new:      createRace()
                case .update:   editRace()
                }
            }

            if data.sendNotification {
                AlertUtil.presentAlertMessage("You are about to notify all the chapter members of \(data.chapterName). Are you sure?", title: "Heads Up", buttonTitle: "Send it!") { action in
                    handleSubmission()
                }
            } else {
                handleSubmission()
            }
        }
    }

    @objc fileprivate func didPressCloseButton() {
        delegate?.raceFormViewControllerDidDismiss(self)
    }

    // MARK: - Verification

    fileprivate func canGoNextSection() -> Bool {
        for row in currentSectionRequiredRows() {
            if let value = row.value(from: data) {
                if value.isEmpty { return false }
            } else {
                return false
            }
        }
        return true
    }
}

fileprivate extension RaceFormViewController {

    func showForm(forRow row: RaceFormRow, pushed: Bool) {
        switch row.formType {
        case .textfield:
            showTextField(forRow: row, pushed: pushed)
        case .textPicker:
            showTextPicker(forRow: row, pushed: pushed)
        case .datePicker:
            showDatePicker(forRow: row, pushed: pushed)
        case .switch:
            showSwitchPicker(forRow: row, pushed: pushed)
        default:
            break
            // TODO: Handle use case?
        }
    }

    @discardableResult
    func showFormForNextRow(_ pushed: Bool) -> Bool {
        if let nextRow = nextRowInCurrentSection(), nextRow.canQuickForm {
            showForm(forRow: nextRow, pushed: pushed)
            return true
        } else {
            return false
        }
    }

    func showTextField(forRow row: RaceFormRow, pushed: Bool) {
        let vc = TextFieldViewController(with: text(for: row))
        vc.delegate = self
        vc.title = row.title
        vc.textField.placeholder = row.tooltip
        vc.textField.keyboardType = row.keyboardType
        presentViewController(vc, forRow: row, pushed: pushed)
    }

    func showTextPicker(forRow row: RaceFormRow, pushed: Bool) {

        func show(_ items: [String], _ selected: String?) {
            var values = items
            if !row.isRequired { values.insert("", at: 0) } // Adding blank value, since they're optional

            let vc = TextPickerViewController(with: values, selectedItem: selected)
            vc.delegate = self
            vc.title = row.title

            presentViewController(vc, forRow: row, pushed: pushed)
        }

        switch row {
        case .season:
            present(seasons, fetch: { seasonApi.getSeasons(forChapter: data.chapterId, $0) },
                    set: { self.seasons = $0 }, selected: data.seasonName, name: { $0.name })
        case .location:
            present(courses, fetch: { courseApi.getCourses(forChapter: data.chapterId, $0) },
                    set: { self.courses = $0 }, selected: data.courseName, name: { $0.name })
        default:
            show(values(for: row), row.value(from: data))
        }

        func present<T>(_ cached: [T]?, fetch: (@escaping ([T]?, NSError?) -> Void) -> Void,
                        set: @escaping ([T]) -> Void,
                        selected: String?,
                        name: @escaping (T) -> String?) {
            if let cached = cached {
                show(cached.map { name($0) ?? "" }, selected)
            } else {
                setLoading(true, forRow: row, pushed: pushed)
                fetch { list, _ in
                    self.setLoading(false, forRow: row, pushed: pushed)
                    if let list = list { set(list) }
                    show(list?.map { name($0) ?? "" } ?? [], selected)
                }
            }
        }
    }

    func showDatePicker(forRow row: RaceFormRow, pushed: Bool) {
        let date = date(for: row)
        let minDate = minimumDate(for: row)

        let vc = DatePickerViewController(with: date, minDate: minDate)
        vc.title = row.title
        vc.delegate = self

        presentViewController(vc, forRow: row, pushed: pushed)
    }

    func showSwitchPicker(forRow row: RaceFormRow, pushed: Bool) {
        guard pushed else { return } // Only using when pushed

        let values = [false.localizedString, true.localizedString]
        let selected = (row.value(from: data) != nil) ? values.last : values.first

        let vc = TextPickerViewController(with: values, selectedItem: selected)
        vc.delegate = self
        vc.title = row.title

        presentViewController(vc, forRow: row, pushed: pushed)
    }

    func showTextViewController(forRow row: RaceFormRow) {
        // most common place to set this
        selectedRow = row

        let vc = TextEditorViewController(with: row == .content ? data.content : nil)
        vc.delegate = self
        vc.title = row.title
        vc.placeholder = row.tooltip
        navigationController?.pushViewController(vc, animated: true)
    }

    func presentViewController(_ viewController: UIViewController, forRow row: RaceFormRow, pushed: Bool) {
        // most common place to set this
        selectedRow = row

        if pushed && formNavigationController != nil {
            formNavigationController?.pushViewController(viewController, animated: true)
            formNavigationController?.delegate = self
        } else {
            let nc = NavigationController(rootViewController: viewController)
            customPresentViewController(presenter, viewController: nc, animated: true)
            formNavigationController = formNavigationController ?? nc

            if formNavigationController == nil {
                formNavigationController = nc
            }
        }
    }

    func setLoading(_ loading: Bool, forRow row: RaceFormRow, pushed: Bool = false) {
        if pushed {
            if let vc = formNavigationController?.viewControllers.last as? FormBaseViewController {
                vc.isLoading = loading
            }
        } else if let cell = tableViewCell(forRow: row) {
            cell.isLoading = loading
        }
    }
}

extension RaceFormViewController {

    func text(for row: RaceFormRow) -> String? {
        switch row {
        case .fee:
            return (data.fee > 0) ? String(format: "%.2f", data.fee) : nil // blank field
        default:
            return row.value(from: data)
        }
    }

    func values(for row: RaceFormRow) -> [String] {
        switch row {
        case .chapter:
            return chapters.compactMap { $0.name }
        case .class:
            return RaceClass.allCases.compactMap { $0.title }
        case .format:
            return ScoringFormat.allCases.compactMap { $0.title } // TODO: Implemented Global Qualifier support
        case .schedule:
            return QualifyingType.allCases.compactMap { $0.title }
        case .privacy:
            return EventType.allCases.compactMap { $0.title }
        default:
            return [String]()
        }
    }

    func date(for row: RaceFormRow) -> Date {
        if row == .startDate, let d = data.startDate {
            return d
        } else if row == .endDate {
            if let d = data.endDate {
                return d
            } else if let d = data.startDate {
                return d.date(with: 300, type: .minute) // default end time, 5 hours after start time
            }
        }
        return Date()
    }

    func minimumDate(for row: RaceFormRow) -> Date? {
        if row == .endDate, let d = data.startDate {
            return d.date(with: 30, type: .minute) // minimum end time, 30 mins after start time
        }
        return nil
    }

    func currentSectionRows() -> [RaceFormRow]? {
        return sections[currentSection]
    }

    func currentSectionRequiredRows() -> [RaceFormRow] {
        guard let rows = currentSectionRows() else { return [RaceFormRow]() }

        return rows.filter({ (row) -> Bool in
            return row.isRequired
        })
    }

    func nextRowInCurrentSection() -> RaceFormRow? {
        if selectedRow == nil {
            return currentSectionRows()?.first
        }
        return rowInCurrentSection(offset: 1)
    }

    func previousRowInCurrentSection() -> RaceFormRow? {
        rowInCurrentSection(offset: -1)
    }

    func isSelectedRowLastInSection() -> Bool {
        // If there is no next row, then the selected row is last in the section
        return nextRowInCurrentSection() == nil
    }

    func rowInCurrentSection(offset: Int) -> RaceFormRow? {
        guard let rows = currentSectionRows(),
              let row = selectedRow,
              let index = rows.firstIndex(of: row)
        else { return nil }

        return rows[safe: index + offset]
    }

    func tableViewCell(forRow row: RaceFormRow) -> FormTableViewCell? {
        guard let rows = currentSectionRows(),
              let index = rows.firstIndex(of: row)
        else { return nil }

        return tableView.cellForRow(at: IndexPath(row: index, section: 0)) as? FormTableViewCell
    }
}

// MARK: - UITableView Delegate

extension RaceFormViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        guard let rows = currentSectionRows() else { return }

        let row = rows[indexPath.row]

        if row.formType == .textEditor {
            showTextViewController(forRow: row)
        } else {
            showForm(forRow: row, pushed: false)
        }
    }
}

// MARK: - UITableView DataSource

extension RaceFormViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection sectionIdx: Int) -> Int {
        guard let rows = currentSectionRows() else { return 0 }
        return rows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(forIndexPath: indexPath) as FormTableViewCell
        guard let rows = currentSectionRows() else { return cell }

        let row = rows[indexPath.row]
        let rowValue = row.value(from: data)

        if row.isRequired {
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
        if let footer = currentSection.footer {
            return footer
        } else if currentSectionRequiredRows().count > 0 {
            return "* Required fields"
        } else {
            return nil
        }
    }
}

// MARK: - TextFieldViewController Delegate

extension RaceFormViewController: FormBaseViewControllerDelegate {

    func formViewController(_ viewController: FormBaseViewController, didSelectItem item: String) {
        guard let row = selectedRow else { return }

        switch row {
        case .name:
            data.name = item
            title = item
        case .startDate:

            // Incrementing the end date, when adjusting the start date
            if let startDate = data.startDate, let endDate = data.endDate {

                let newStart = DateUtil.standardDateFormatter.date(from: item)
                let diff = endDate.timeIntervalSince(startDate)

                if diff > 0 {
                    if let newEnd = newStart?.addingTimeInterval(diff) {
                        data.endDateString = DateUtil.standardDateFormatter.string(from: newEnd)
                    }
                } else if let minDate = newStart?.date(with: 30, type: .minute) {
                    data.endDateString = DateUtil.standardDateFormatter.string(from: minDate)
                }
            }

            data.startDateString = item
        case .endDate:
            data.endDateString = item
        case .chapter:
            if let chapter = chapters.filter ({ return $0.name == item }).first {
                data.chapterId = chapter.id
                data.chapterName = chapter.name
            }
        case .class:
            if let value = RaceClass(title: item)?.rawValue {
                data.raceClass = value
            }
        case .format:
            if let value = ScoringFormat(title: item)?.rawValue {
                data.format = value
            }
        case .schedule:
            if let value = QualifyingType(title: item)?.rawValue {
                data.qualifying = value
            }
        case .privacy:
            if let value = EventType(title: item)?.rawValue {
                data.privacy = value
            }
        case .fee:
            let amount = Float32(item) ?? 0
            if amount == 0 { data.feeRequired = false }
            data.fee = amount
        case .feeRequired:
            data.feeRequired = (item == true.localizedString)
        case .scoring:
            data.funfly = (item == true.localizedString)
        case .rounds:
            data.rounds = (item as NSString).intValue
        case .zDepth:
            data.zippyqDepth = (item as NSString).intValue
        case .zIterator:
            data.zippyqIterator = (item as NSString).intValue
        case .zNoKiosk:
            data.zippyqNoKiosk = (item == true.localizedString)
        case .season:
            if let season = seasons?.filter ({ return $0.name == item }).first {
                data.seasonId = season.id
                data.seasonName = season.name
            } else {
                data.seasonId = nil
                data.seasonName = nil
            }
        case .location:
            if let course = courses?.filter ({ return $0.name == item }).first {
                data.courseId = course.id
                data.courseName = course.name
            } else {
                data.courseId = nil
                data.courseName = nil
            }
        default:
            break
        }

        // refresh content
        tableView.reloadData()
        navigationItem.rightBarButtonItem?.isEnabled = canGoNextSection()

        // handle next row
        if isQuickFormActive  {
            if isSelectedRowLastInSection() {
                goNextSection()
                formViewControllerDidDismiss(viewController)
            } else if !showFormForNextRow(true) {
                formViewControllerDidDismiss(viewController)
            }
        }
        else {
            formViewControllerDidDismiss(viewController)
        }
    }

    func formViewControllerDidDismiss(_ viewController: FormBaseViewController) {
        // invalidate form once reaching the section
        isQuickFormActive = false
        selectedRow = nil

        viewController.dismiss(animated: true)
    }

    func formViewController(_ viewController: FormBaseViewController, enableSelectionWithItem item: String) -> Bool {
        guard let row = selectedRow else { return false }

        if row.formType == .textfield {
            if row == .name {
                guard item.count >= Race.nameMinLength else { return false }
                guard item.count < Race.nameMaxLength else { return false }
            } else if row == .fee || row == .rounds {
                return true // allow any length
            }
        }

        if row.isRequired {
            return !item.isEmpty
        }

        return true
    }

    func formViewControllerRightBarButtonTitle(_ viewController: FormBaseViewController) -> String {
        return isQuickFormActive ? "Next" : "OK"
    }

    func formViewControllerKeyboardReturnKeyType(_ viewController: FormBaseViewController) -> UIReturnKeyType {
        return isQuickFormActive ? .next : .done
    }
}

// MARK: - TextEditorViewController Delegate

extension RaceFormViewController: TextEditorViewControllerDelegate {

    func textEditorViewController(_ viewController: TextEditorViewController, didEditText text: String) {
        guard let row = selectedRow, row.formType == .textEditor else { return }

        if row == .content {
            data.content = text
        }

        navigationController?.popViewController(animated: true)
        tableView.reloadData()
    }
}

// MARK: - UINavigationControllerDelegate Delegate

extension RaceFormViewController: UINavigationControllerDelegate {

    func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationController.Operation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {

        if operation == .pop {
            selectedRow = previousRowInCurrentSection()
        }
        return nil
    }
}
