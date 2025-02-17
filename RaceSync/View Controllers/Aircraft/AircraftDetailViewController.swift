//
//  AircraftDetailViewController.swift
//  RaceSync
//
//  Created by Ignacio Romero Zurbuchen on 2020-02-17.
//  Copyright © 2020 MultiGP Inc. All rights reserved.
//

import UIKit
import SnapKit
import RaceSyncAPI
import Presentr

protocol AircraftDetailViewControllerDelegate {
    func aircraftDetailViewController(_ viewController: AircraftDetailViewController, didEditAircraft aircraftId: ObjectId)
    func aircraftDetailViewController(_ viewController: AircraftDetailViewController, didDeleteAircraft aircraftId: ObjectId)
}

class AircraftDetailViewController: UIViewController {

    // MARK: - Public Variables

    var isEditable: Bool = true
    var isNew: Bool = false
    var shouldShowHeader: Bool = true

    var delegate: AircraftDetailViewControllerDelegate?

    // MARK: - Private Variables

    fileprivate lazy var headerView: ProfileHeaderView = {
        let view = ProfileHeaderView()
        view.locationButton.isHidden = true
        view.delegate = self
        return view
    }()

    fileprivate lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(cellType: FormTableViewCell.self)
        tableView.contentInsetAdjustmentBehavior = .always
        tableView.tableFooterView = UIView()
        return tableView
    }()

    fileprivate lazy var activityIndicatorView: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(style: .large)
        view.hidesWhenStopped = true
        return view
    }()

    fileprivate lazy var deleteButton: ActionButton = {
        let button = ActionButton(type: .system)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 21, weight: .regular)
        button.setTitleColor(Color.red, for: .normal)
        button.setTitle("Retire Aircraft", for: .normal)
        button.backgroundColor = Color.white
        button.layer.cornerRadius = Constants.padding/2
        button.layer.borderColor = Color.gray100.cgColor
        button.layer.borderWidth = 0.5
        button.addTarget(self, action:#selector(didPressDeleteButton), for: .touchUpInside)
        return button
    }()

    fileprivate lazy var deleteButtonView: UIView = {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 96))

        view.addSubview(deleteButton)
        deleteButton.snp.makeConstraints {
            $0.top.equalToSuperview().offset(Constants.padding*2)
            $0.leading.equalToSuperview().offset(Constants.padding)
            $0.bottom.trailing.equalToSuperview().offset(-Constants.padding)
        }

        return view
    }()

    var isLoading: Bool = false {
        didSet {
            if isLoading { activityIndicatorView.startAnimating() }
            else { activityIndicatorView.stopAnimating() }
        }
    }

    fileprivate var aircraftViewModel: AircraftViewModel {
        didSet { title = aircraftViewModel.displayName }
    }
    fileprivate let aircraftApi = AircraftApi()
    fileprivate var selectedRow: AircraftFormRow?

    fileprivate enum Constants {
        static let padding: CGFloat = UniversalConstants.padding
        static let cellHeight: CGFloat = 50
    }

    // MARK: - Initialization

    init(with aircraftViewModel: AircraftViewModel) {
        self.aircraftViewModel = aircraftViewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()

        // required delay for setting up the layout before reloading the tableview
        setupLayout()
        isLoading = true
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // reloading tableview once the view appears so the content isn't displayed underneath the header view
        isLoading = false
        tableView.reloadData()

        if isEditable {
            tableView.tableFooterView = deleteButtonView
        }

        if isNew {
            // Promote uploading an aircraft avatar after the creation step
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                self?.headerView.presentUploadSheet(.main)
            }
        }
    }

    // MARK: - Layout

    fileprivate func setupLayout() {
        guard let aircraft = aircraftViewModel.aircraft else { return }

        title = aircraftViewModel.displayName
        view.backgroundColor = Color.white

        if shouldShowHeader {
            headerView.isEditable = isEditable
            headerView.topLayoutInset = topOffset
            headerView.viewModel = ProfileViewModel(with: aircraft)
            tableView.tableHeaderView = headerView
        }

        view.addSubview(tableView)
        tableView.snp.makeConstraints {
            $0.top.leading.trailing.bottom.equalToSuperview()
        }

        if shouldShowHeader {
            let headerViewSize = headerView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
            headerView.snp.makeConstraints {
                $0.size.equalTo(headerViewSize)
            }
        }

        view.addSubview(activityIndicatorView)
        activityIndicatorView.snp.makeConstraints {
            $0.centerX.centerY.equalToSuperview()
        }
    }

    // MARK: - Actions

    @objc func didPressDeleteButton() {
        ActionSheetUtil.presentDestructiveActionSheet(withTitle: "Are you sure you want to retire \"\(aircraftViewModel.displayName)\"?", destructiveTitle: "Yes, retire", completion: { (action) in
            self.deleteAircraft()
        }, cancel: nil)
    }
}

fileprivate extension AircraftDetailViewController {

    func presentPicker(forRow row: AircraftFormRow) {
        let items = row.values
        let selectedItem = row.value(from: aircraftViewModel) ?? row.defaultValue

        let presenter = Appearance.defaultPresenter()
        let vc = TextPickerViewController(with: items, selectedItem: selectedItem)
        vc.delegate = self
        vc.title = "Update \(row.title)"

        let nc = NavigationController(rootViewController: vc)
        customPresentViewController(presenter, viewController: nc, animated: true)
    }

    func presentTextField(forRow row: AircraftFormRow) {
        let text = row.value(from: aircraftViewModel)

        let presenter = Appearance.defaultPresenter()
        let vc = TextFieldViewController(with: text)
        vc.delegate = self
        vc.title = "Update \(row.title)"
        vc.textField.placeholder = "Aircraft Name"

        let nc = NavigationController(rootViewController: vc)
        customPresentViewController(presenter, viewController: nc, animated: true)
    }

    func deleteAircraft() {
        let aircraftId = aircraftViewModel.aircraftId

        aircraftApi.retire(aircraft: aircraftId) { [weak self] (status, error)  in
            guard let strongSelf = self else { return }
            if status {
                strongSelf.delegate?.aircraftDetailViewController(strongSelf, didDeleteAircraft: aircraftId)
            } else if let error = error {
                AlertUtil.presentAlertMessage(error.localizedDescription, title: "Error")
            }
        }
    }
}

extension AircraftDetailViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        guard let row = AircraftFormRow(rawValue: indexPath.row) else { return }
        guard isEditable else { return }

        if row == .name {
            presentTextField(forRow: row)
        } else {
            presentPicker(forRow: row)
        }

        selectedRow = row
    }
}

extension AircraftDetailViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return isLoading ? 0 : AircraftFormRow.allCases.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(forIndexPath: indexPath) as FormTableViewCell
        guard let row = AircraftFormRow(rawValue: indexPath.row) else { return cell }

        if row.isRowRequired, isEditable {
            cell.textLabel?.text = row.title + " *"
        } else {
            cell.textLabel?.text = row.title
        }

        cell.textLabel?.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        cell.textLabel?.textColor = Color.black

        cell.detailTextLabel?.text = row.displayText(from: aircraftViewModel)
        cell.detailTextLabel?.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        cell.detailTextLabel?.textColor = Color.gray300
        cell.accessoryType = isEditable ? .disclosureIndicator : .none
        
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return Constants.cellHeight
    }
}

// MARK: - TextFieldViewController Delegate

extension AircraftDetailViewController: FormBaseViewControllerDelegate {

    func formViewController(_ viewController: FormBaseViewController, didSelectItem item: String) {

        if viewController.formType == .textfield {
            handleTextfieldVC(viewController, selection: item)
        } else if viewController.formType == .textPicker {
            handleTextPickerVC(viewController, selection: item)
        }
    }

    func formViewController(_ viewController: FormBaseViewController, enableSelectionWithItem item: String) -> Bool {
        guard let row = selectedRow else { return false }
        guard item.count >= Aircraft.nameMinLength else { return false }
        guard item.count < Aircraft.nameMaxLength else { return false }
        
        if row.isRowRequired {
            return !item.isEmpty
        }

        return true
    }

    func formViewControllerDidDismiss(_ viewController: FormBaseViewController) {
        //
    }

    func handleTextfieldVC(_ viewController: FormBaseViewController, selection item: String) {
        guard let aircraft = aircraftViewModel.aircraft else { return }

        let aircraftData = AircraftData()
        aircraftData.name = item

        viewController.isLoading = true

        aircraftApi.update(aircraft: aircraftViewModel.aircraftId, with: aircraftData) {  [weak self] (status, error) in
            guard let strongSelf = self else { return }
            if status {
                let updatedAircraft = strongSelf.updateAircraft(aircraft, withItem: item, forRow: AircraftFormRow.name)
                strongSelf.handleAircraftUpdate(updatedAircraft, from: viewController)
            } else if let error = error {
                viewController.isLoading = false
                AlertUtil.presentAlertMessage(error.localizedDescription, title: "Error")
            }
        }
    }

    func handleTextPickerVC(_ viewController: FormBaseViewController, selection item: String) {
        guard let row = selectedRow else { return }
        guard let aircraft = aircraftViewModel.aircraft else { return }

        let aircraftData = AircraftData()

        switch row {
        case .type:
            aircraftData.type = AircraftType(title: item)?.rawValue
        case .size:
            aircraftData.size = AircraftSize(title: item)?.rawValue
        case .battery:
            aircraftData.battery = BatterySize(title: item)?.rawValue
        case .propSize:
            aircraftData.propSize = PropellerSize(title: item)?.rawValue
        case .videoTx:
            aircraftData.videoTxType = VideoTxType(title: item)?.rawValue
        case .antenna:
            aircraftData.antenna = AntennaPolarization(title: item)?.rawValue
        default:
            break
        }

        viewController.isLoading = true

        aircraftApi.update(aircraft: aircraft.id, with: aircraftData) { [weak self] (status, error) in
            guard let strongSelf = self else { return }
            if status {
                let updatedAircraft = strongSelf.updateAircraft(aircraft, withItem: item, forRow: row)
                strongSelf.handleAircraftUpdate(updatedAircraft, from: viewController)
            }  else if let error = error {
                viewController.isLoading = false
                AlertUtil.presentAlertMessage(error.localizedDescription, title: "Error")
            }
        }
    }

    func updateAircraft(_ aircraft: Aircraft, withItem item: String, forRow row: AircraftFormRow) -> Aircraft {
        switch row {
        case .name:
            aircraft.name = item
        case .type:
            let type = AircraftType(title: item)
            aircraft.type = type
        case .size:
            let type = AircraftSize(title: item)
            aircraft.size = type
        case .battery:
            let type = BatterySize(title: item)
            aircraft.battery = type
        case .propSize:
            let type = PropellerSize(title: item)
            aircraft.propSize = type
        case .videoTx:
            let type = VideoTxType(title: item)
            aircraft.videoTxType = type ?? .´5800mhz´
        case .antenna:
            let type = AntennaPolarization(title: item)
            aircraft.antenna = type ?? .both
        }
        return aircraft
    }

    func handleAircraftUpdate(_ aircraft: Aircraft, from viewController: UIViewController) {
        aircraftViewModel = AircraftViewModel(with: aircraft)
        tableView.reloadData()
        delegate?.aircraftDetailViewController(self, didEditAircraft: aircraft.id)
        viewController.dismiss(animated: true)

        RateMe.sharedInstance.userDidPerformEvent(showPrompt: true)
    }

    func updateAircraftImageUrl(_ url: String, for imageType: ImageType) {
        guard let aircraft = aircraftViewModel.aircraft else { return }

        if imageType == .main {
            aircraft.mainImageUrl = url
        } else {
            aircraft.backgroundImageUrl = url
        }

        aircraftViewModel = AircraftViewModel(with: aircraft)
        headerView.viewModel = ProfileViewModel(with: aircraft)

        delegate?.aircraftDetailViewController(self, didEditAircraft: aircraft.id)
    }
}

extension AircraftDetailViewController: ProfileHeaderViewDelegate {

    func shouldUploadImage(_ image: UIImage, imageType: ImageType, for objectId: ObjectId) {

        aircraftApi.uploadImage(image, imageType: imageType, forAircraft: objectId) { [weak self] (url, error) in
            if let url = url {
                self?.updateAircraftImageUrl(url, for: imageType)
                Clog.log("Uploaded Image at url: \(url)")
            } else {
                AlertUtil.presentAlertMessage(error?.localizedDescription)
                Clog.log("Upload failed with error \(error.debugDescription)")
            }
        }
    }
}

// MARK: - ScrollView Delegate

extension AircraftDetailViewController: UIScrollViewDelegate {

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if shouldShowHeader {
            stretchHeaderView(with: scrollView.contentOffset)
        }
    }
}

// MARK: - HeaderStretchable

extension AircraftDetailViewController: HeaderStretchable {

    var targetHeaderView: StretchableView {
        return headerView.backgroundView
    }

    var targetHeaderViewSize: CGSize {
        return headerView.backgroundViewSize
    }

    var topLayoutInset: CGFloat {
        return topOffset
    }

    var anchoredViews: [UIView]? {
        return [headerView.cameraButton]
    }
}
