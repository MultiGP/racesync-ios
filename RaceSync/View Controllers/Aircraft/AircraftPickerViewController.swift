//
//  AircraftPickerViewController.swift
//  RaceSync
//
//  Created by Ignacio Romero Zurbuchen on 2020-01-08.
//  Copyright © 2020 MultiGP Inc. All rights reserved.
//

import UIKit
import SnapKit
import RaceSyncAPI
import EmptyDataSet_Swift

protocol AircraftPickerViewControllerDelegate {
    func aircraftPickerViewController(_ viewController: AircraftPickerViewController, didSelectAircraft aircraftId: ObjectId)
    func aircraftPickerViewControllerDidError(_ viewController: AircraftPickerViewController)
    func aircraftPickerViewControllerDidDismiss(_ viewController: AircraftPickerViewController)
}

class AircraftPickerViewController: UIViewController {

    // MARK: - Public Variables

    var delegate: AircraftPickerViewControllerDelegate?

    var isLoading: Bool = false {
        didSet {
            if isLoading {
                let view = UIActivityIndicatorView(style: .medium)
                view.startAnimating()
                navigationItem.rightBarButtonItem = UIBarButtonItem(customView: view)
            }
            else {
                navigationItem.rightBarButtonItem = rightBarButtonItem
                activityIndicatorView.stopAnimating()
            }
        }
    }

    // MARK: - Private Variables

    fileprivate lazy var collectionViewLayout: UICollectionViewLayout = {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: AircraftCollectionViewCell.height, height: AircraftCollectionViewCell.height)
        layout.minimumInteritemSpacing = Constants.padding
        layout.sectionInset = UIEdgeInsets(top: 0, left: Constants.padding, bottom: 0, right: Constants.padding)
        return layout
    }()

    fileprivate lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout:collectionViewLayout)
        collectionView.register(cellType: AircraftCollectionViewCell.self)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.backgroundColor = Color.white
        collectionView.emptyDataSetSource = self
        collectionView.emptyDataSetDelegate = self
        return collectionView
    }()

    fileprivate lazy var rightBarButtonItem: UIBarButtonItem = {
        return UIBarButtonItem(image: ButtonImg.add, style: .done, target: self, action: #selector(didPressCreateButton))
    }()

    fileprivate lazy var activityIndicatorView: UIActivityIndicatorView = {
        return UIActivityIndicatorView(style: .large)
    }()

    fileprivate let race: Race
    fileprivate let aircraftApi = AircraftApi()
    fileprivate var aircraftViewModels = [AircraftViewModel]()

    fileprivate var emptyStateAircraft = EmptyStateViewModel(.noMatchingAircraft)

    fileprivate enum Constants {
        static let padding: CGFloat = UniversalConstants.padding
        static let margin: UIEdgeInsets = UIEdgeInsets(proportionally: Constants.padding)
        static let title: String = "Select an Aircraft"
    }

    // MARK: - Initialization

    init(with race: Race) {
        self.race = race
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()

        setupLayout()
        fetchMyAircraft()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    // MARK: - Layout

    fileprivate func setupLayout() {

        title = Constants.title
        view.backgroundColor = Color.white

        navigationItem.leftBarButtonItem = UIBarButtonItem(image: ButtonImg.close, style: .done, target: self, action: #selector(didPressCloseButton))
        navigationItem.rightBarButtonItem = rightBarButtonItem

        view.addSubview(collectionView)
        collectionView.snp.makeConstraints {
            $0.top.leading.trailing.bottom.equalToSuperview()
        }

        view.addSubview(activityIndicatorView)
        activityIndicatorView.snp.makeConstraints {
            $0.centerX.centerY.equalToSuperview()
        }
    }

    // MARK: - Actions

    @objc func didPressCreateButton() {

        let sheetTitle = "Join the race with a new aircraft?"

        let alert = UIAlertController(title: sheetTitle, message: nil, preferredStyle: .actionSheet)
        alert.view.tintColor = Color.blue

        alert.addAction(UIAlertAction(title: "New Aircraft", style: .default, handler: { [weak self] (actionButton) in
            self?.presentNewAircraftForm()
        }))
        alert.addAction(UIAlertAction(title: "Generic Aircraft", style: .default, handler: { [weak self] (actionButton) in
            let title = "Are you sure? This will create a generic aircraft matching the race specs, then join the race."
            ActionSheetUtil.presentDestructiveActionSheet(withTitle: title, destructiveTitle: "Yes, Create and Join",
                                                          completion: { (action) in
                                                            self?.pickGenericAircraft()
            }) { (action) in
                //
            }
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

        navigationController?.present(alert, animated: true)
    }

    @objc func didPressCloseButton() {
        delegate?.aircraftPickerViewControllerDidDismiss(self)
    }

    func presentNewAircraftForm() {
        let data = AircraftData(with: race)
        data.name = nil
        
        let vc = AircraftFormViewController(with: data)
        vc.delegate = self
        let nc = UINavigationController(rootViewController: vc)
        navigationController?.present(nc, animated: true)
    }

    func pickGenericAircraft() {

        title = "Creating Generic Aircraft..."
        isLoading = true

        let data = AircraftData(with: race)

        aircraftApi.createAircraft(with: data) { [weak self] (aircraft, error) in
            guard let strongSelf = self else { return }
            strongSelf.isLoading = false

            if let aircraft = aircraft {
                strongSelf.delegate?.aircraftPickerViewController(strongSelf, didSelectAircraft: aircraft.id)
            } else {
                strongSelf.title = Constants.title
                strongSelf.delegate?.aircraftPickerViewControllerDidError(strongSelf)
            }
        }
    }
}

extension AircraftPickerViewController {

    func fetchMyAircraft() {
        activityIndicatorView.startAnimating()

        let data = AircraftRaceData(with: race)

        aircraftApi.getMyAircraft(forRaceData: data) { [weak self] (aircraft, error) in
            if let aircraft = aircraft {
                self?.aircraftViewModels += AircraftViewModel.viewModels(with: aircraft)
                self?.activityIndicatorView.stopAnimating()
                self?.collectionView.reloadData()
            } else if error != nil {
                Clog.log("fetchMyUser error : \(error.debugDescription)")
            }
        }
    }
}

extension AircraftPickerViewController: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {

        let viewModel = aircraftViewModels[indexPath.row]

        let sheetTitle = "Join the race with \(viewModel.displayName)?"
        let buttonTitle = "Yes, Join Race"

        ActionSheetUtil.presentActionSheet(withTitle: sheetTitle, buttonTitle: buttonTitle, completion: { [weak self] (action) in
            guard let strongSelf = self else { return }

            let viewModel = strongSelf.aircraftViewModels[indexPath.row]
            strongSelf.delegate?.aircraftPickerViewController(strongSelf, didSelectAircraft: viewModel.aircraftId)
        }) { [weak self] (cancel) in
            self?.collectionView.deselectAllItems()
        }
    }
}

extension AircraftPickerViewController: UICollectionViewDataSource {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return aircraftViewModels.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(forIndexPath: indexPath) as AircraftCollectionViewCell

        let viewModel = aircraftViewModels[indexPath.row]
        cell.titleLabel.text = viewModel.displayName
        cell.avatarImageView.imageView.setImage(with: viewModel.imageUrl, placeholderImage: PlaceholderImg.largeAircraft)
        return cell
    }
}

extension AircraftPickerViewController: AircraftFormViewControllerDelegate {

    func aircraftFormViewController(_ viewController: AircraftFormViewController, didCreateAircraft aircraft: Aircraft) {
        viewController.dismiss(animated: true)

        delegate?.aircraftPickerViewController(self, didSelectAircraft: aircraft.id)
    }

    func aircraftFormViewControllerDidDismiss(_ viewController: AircraftFormViewController) {
        viewController.dismiss(animated: true)
    }

    func aircraftFormViewController(_ viewController: AircraftFormViewController, valuesFor row: AircraftFormRow) -> [String]? {
        let aircraftRaceData = AircraftRaceData(with: race)
        return row.aircraftRaceSpecValues(for: aircraftRaceData)
    }
}

extension AircraftPickerViewController: EmptyDataSetSource {

    func title(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        return emptyStateAircraft.title
    }

    func description(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        return emptyStateAircraft.description
    }

    func buttonTitle(forEmptyDataSet scrollView: UIScrollView, for state: UIControl.State) -> NSAttributedString? {
        return emptyStateAircraft.buttonTitle(state)
    }

    func verticalOffset(forEmptyDataSet scrollView: UIScrollView) -> CGFloat {
        return -(navigationController?.navigationBar.frame.height ?? 0)
    }
}

extension AircraftPickerViewController: EmptyDataSetDelegate {

    func emptyDataSetShouldDisplay(_ scrollView: UIScrollView) -> Bool {
        return !activityIndicatorView.isAnimating
    }

    func emptyDataSetShouldAllowScroll(_ scrollView: UIScrollView) -> Bool {
        return true
    }

    func emptyDataSet(_ scrollView: UIScrollView, didTapButton button: UIButton) {
        didPressCreateButton()
    }
}
