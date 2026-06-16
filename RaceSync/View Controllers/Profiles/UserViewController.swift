//
//  UserViewController.swift
//  RaceSync
//
//  Created by Ignacio Romero Zurbuchen on 2019-11-15.
//  Copyright © 2019 MultiGP Inc. All rights reserved.
//

import UIKit
import SnapKit
import RaceSyncAPI
import Presentr
import EmptyDataSet_Swift
import CoreLocation
import QRCode

class UserViewController: ProfileViewController, ViewJoinable, RaceEditable {

    // MARK: - Public Variables

    var raceController: RaceController?

    // MARK: - Private Variables

    fileprivate var user: User
    fileprivate let raceApi = RaceApi()
    fileprivate let chapterApi = ChapterApi()
    fileprivate let userApi = UserApi()

    fileprivate var raceViewModels = [RaceViewModel]()
    fileprivate var chapterViewModels = [ChapterViewModel]()
    fileprivate var presenter: Presentr?
    fileprivate var userCoordinate: CLLocationCoordinate2D?
    fileprivate var isPhotoEditale = false

    fileprivate let emptyStateRaces = EmptyStateViewModel(.noProfileRaces)
    fileprivate let emptyStateChapters = EmptyStateViewModel(.noProfileChapters)
    fileprivate let emptyStateMyRaces = EmptyStateViewModel(.noMyProfileRaces)
    fileprivate let emptyStateMyChapters = EmptyStateViewModel(.noMyProfileChapters)

    fileprivate enum Constants {
        static let padding: CGFloat = UniversalConstants.padding
        static let buttonHeight: CGFloat = 32
        static let buttonSpacing: CGFloat = 12
        static let avatarImageSize = CGSize(width: 50, height: 50)
    }

    // MARK: - Initialization

    init(with user: User) {
        self.user = user

        let profileViewModel = ProfileViewModel(with: user)
        super.init(with: profileViewModel)

        if let latitude = CLLocationDegrees(user.latitude), let longitude = CLLocationDegrees(user.longitude) {
            self.userCoordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()

        loadContent()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    deinit {
        unregisterJoinable()
    }

    // MARK: - Layout

    override func setupLayout() {
        super.setupLayout()

        registerJoinable()
        configureBarButtonItems()

        tableView.register(cellType: UserRaceTableViewCell.self)
        tableView.register(cellType: ChapterTableViewCell.self)
        tableView.dataSource = self
        tableView.emptyDataSetSource = self
        tableView.emptyDataSetDelegate = self

        let longPress = UILongPressGestureRecognizer(target: self,action: #selector(didLongPress(_:)))
        longPress.minimumPressDuration = 0.3
        longPress.delaysTouchesBegan = true
        tableView.addGestureRecognizer(longPress)

        headerView.isEditable = user.isMe && isPhotoEditale
        headerView.avatarView.isUserInteractionEnabled = isPhotoEditale
        headerView.delegate = self
    }
    
    fileprivate func configureBarButtonItems() {
        // Build the action list
        var actions: [BarButtonAction] = [
            (ButtonImg.share, #selector(didPressShareButton), 0)
        ]
        if user.isMe {
            actions.append((ButtonImg.qrcode, #selector(didPressQRButton), 0))
        }

        if #available(iOS 26, *) {
            navigationItem.rightBarButtonItems = actions.map { action in
                UIBarButtonItem(image: action.image, style: .plain, target: self, action: action.selector)
            }.interspersed(with: UIBarButtonItem.spacer())
        } else {
            // Still needed for versions of iOS previous to iOS26
            navigationItem.rightBarButtonItem = UIBarButtonItem.stackedBarButtonItem(for: actions, target: self)
        }

        if navigationController?.viewControllers.count == 1 {
            navigationItem.leftBarButtonItem = UIBarButtonItem(image: ButtonImg.close, style: .plain, target: self, action: #selector(didPressCloseButton))
        }
    }

    // MARK: - Actions

    override func didChangeSegment() {
        super.didChangeSegment()

        loadContent()
    }

    override func didPressLocationButton() {
        // Let's not display a user's location on a map
    }

    override func didSelectRow(at indexPath: IndexPath) {
        if selectedSegment == .left, let viewModel = raceViewModel(for: indexPath.row) {
            let vc = RaceTabBarController(with: viewModel.race)
            navigationController?.pushViewController(vc, animated: true)
        } else if selectedSegment == .right, let viewModel = chapterViewModel(for: indexPath.row) {
            let vc = ChapterViewController(with: viewModel.chapter)
            navigationController?.pushViewController(vc, animated: true)
        }
    }

    @objc func didPressCloseButton() {
        dismiss(animated: true)
    }

    func getQRImage(with userId: String) -> UIImage? {
        var qrCode = QRCode(userId)
        qrCode?.size = CGSize(width: 270, height: 270)
        qrCode?.color = CIColor(color: Color.black)
        qrCode?.backgroundColor = CIColor(color: Color.white)
        return qrCode?.image
    }

    @objc func didPressQRButton() {
        guard let qrImage = getQRImage(with: user.id) else { return }
        let vc = ImageExportViewController(with: qrImage, caption: user.id)

        let presenter = Presentr(presentationType: .fullScreen)
        presenter.blurBackground = false
        presenter.backgroundOpacity = 0.65
        presenter.transitionType = .crossDissolve
        presenter.dismissTransitionType = .crossDissolve
        presenter.dismissAnimated = true
        presenter.dismissOnSwipe = false
        presenter.backgroundTap = .dismiss
        presenter.outsideContextTap = .passthrough

        customPresentViewController(presenter, viewController: vc, animated: true)
        self.presenter = presenter
    }

    @objc func didPressJoinButton(_ sender: JoinButton) {
        guard let objectId = sender.objectId, let race = raceViewModels.race(withId: objectId) else { return }
        let state = sender.joinState

        toggleJoinButton(sender, forRace: race, raceApi: raceApi) { [weak self] (newState) in
            if state != newState {
                // reload races to reflect race changes, specially join counts
                self?.fetchRaces(nil)
            }
        }
    }

    @objc func didLongPress(_ gesture: UIGestureRecognizer) {
        handleLongPress(gesture)
    }

    @objc func didPressShareButton() {
        guard let userURL = URL(string: user.url) else { return }

        let activities: [UIActivity] = [MGPActivity(), CopyLinkActivity()]

        let vc = UIActivityViewController(activityItems:  [userURL], applicationActivities: activities)
        vc.excludeAllActivityTypes(except: [.airDrop])
        present(vc, animated: true)
    }

    // MARK: - Data Update

    // ViewJoinable
    func loadContent(forced: Bool = false) {
        if selectedSegment == .left {
            loadRaces(forced)
        } else {
            loadChapters(forced)
        }
    }

    fileprivate func loadRaces(_ forced: Bool = false) {
        loadList(forced: forced, isEmpty: raceViewModels.isEmpty,
                segment: .left, fetch: fetchRaces)
    }

    fileprivate func loadChapters(_ forced: Bool = false) {
        loadList(forced: forced, isEmpty: chapterViewModels.isEmpty,
                segment: .right, fetch: fetchChapters)
    }

    fileprivate func fetchRaces(_ completion: VoidCompletionBlock? = nil) {
        raceApi.getRaces(with: [.joined], userId: user.id) { (races, error) in
            if let races = races {
                let sortedRaces = races.sorted(by: { $0.startDate?.compare($1.startDate ?? Date()) == .orderedDescending })
                self.raceViewModels = RaceViewModel.viewModels(with: sortedRaces)
            } else {
                Clog.log("getRaces error : \(error.debugDescription)")
            }

            completion?()
        }
    }

    fileprivate func fetchChapters(_ completion: VoidCompletionBlock? = nil) {
        chapterApi.getChapters(forUser: user.id) { [weak self] (chapters, error) in
            guard let strongSelf = self else { return }

            if let chapters = chapters {
                let chapterViewModels = ChapterViewModel.viewModels(with: chapters)

                strongSelf.chapterViewModels = chapterViewModels.sorted(by: { (c1, c2) -> Bool in
                    return c1.titleLabel.lowercased() < c2.titleLabel.lowercased()
                })

                // first display my managed chapters, then alphabetically
                if strongSelf.user.isMe, let myManagedChapterIds = APIServices.shared.myManagedChapters?.compactMap({ $0.id }) {
                    strongSelf.chapterViewModels = strongSelf.chapterViewModels.sorted(by: { (c1, c2) -> Bool in
                        return myManagedChapterIds.contains(c1.chapter.id)
                    })
                }

            } else {
                Clog.log("getChapters error : \(error.debugDescription)")
            }

            completion?()
        }
    }

    fileprivate func loadList(forced: Bool,
                          isEmpty: Bool,
                          segment: ProfileSegment,
                          fetch: (@escaping () -> Void) -> Void ){

        guard isEmpty || forced else {
            tableView.reloadData()
            return
        }

        let showShimmer = shouldShowShimmer(for: segment)

        if showShimmer {
            isLoadingList(true)
        }

        fetch { [weak self] in
            guard let self else { return }

            if showShimmer {
                self.isLoadingList(false)   // triggers its own reload
            } else {
                self.tableView.reloadData()
            }
        }
    }

    func shouldShowShimmer(for segment: ProfileSegment) -> Bool {
        if selectedSegment == .left {
            return raceViewModels.count == 0
        } else {
            return chapterViewModels.count == 0
        }
    }

    func raceViewModel(for index: Int) -> RaceViewModel? {
        if index >= 0, index < raceViewModels.count {
            return raceViewModels[index]
        }
        return nil
    }

    func chapterViewModel(for index: Int) -> ChapterViewModel? {
        if index >= 0, index < chapterViewModels.count {
            return chapterViewModels[index]
        }
        return nil
    }
}

// MARK: - UITableView DataSource

extension UserViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if selectedSegment == .left {
            return raceViewModels.count
        } else {
            return chapterViewModels.count
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if selectedSegment == .left {
            return userRaceTableViewCell(for: indexPath)
        } else {
            return chapterTableViewCell(for: indexPath)
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UserRaceTableViewCell.height
    }

    func userRaceTableViewCell(for indexPath: IndexPath) -> UserRaceTableViewCell {
        let cell = tableView.dequeueReusableCell(forIndexPath: indexPath) as UserRaceTableViewCell
        guard let viewModel = raceViewModel(for: indexPath.row) else { return cell }

        cell.dateLabel.text = viewModel.startDateLabel //"Saturday Sept 14 @ 9:00 AM"
        cell.titleLabel.text = viewModel.titleLabel
        cell.joinButton.type = .race
        cell.joinButton.objectId = viewModel.race.id
        cell.joinButton.joinState = viewModel.joinState
        cell.joinButton.addTarget(self, action: #selector(didPressJoinButton), for: .touchUpInside)
        cell.memberBadgeView.count = viewModel.participantCount
        cell.avatarImageView.imageView.setImage(with: viewModel.imageUrl, placeholderImage: PlaceholderImg.medium, size: Constants.avatarImageSize)
        return cell
    }

    func chapterTableViewCell(for indexPath: IndexPath) -> ChapterTableViewCell {
        let cell = tableView.dequeueReusableCell(forIndexPath: indexPath) as ChapterTableViewCell
        guard let viewModel = chapterViewModel(for: indexPath.row) else { return cell }

        cell.titleLabel.text = viewModel.titleLabel
        cell.subtitleLabel.text = viewModel.locationLabel
        cell.avatarImageView.imageView.setImage(with: viewModel.imageUrl, placeholderImage: PlaceholderImg.medium, size: Constants.avatarImageSize)
        return cell
    }
}

extension UserViewController: ProfileHeaderViewDelegate {

    func shouldUploadImage(_ image: UIImage, imageType: ImageType, for id: ObjectId) {

        userApi.uploadProfileImage(image, imageType: imageType) { [weak self] (url, error) in
            if let url = url {
                self?.updateUserProfileUrl(url, for: imageType)
            } else {
                AlertUtil.presentAlertMessage(error?.localizedDescription)
            }
        }
    }

    func updateUserProfileUrl(_ url: String, for imageType: ImageType) {

        if imageType == .main {
            user.profilePictureUrl = url
        } else {
            user.profileBackgroundUrl = url
        }
        
        let viewModel = ProfileViewModel(with: user)
        headerView.viewModel = viewModel
    }
}

extension UserViewController: EmptyDataSetSource {

    func getEmptyStateViewModel() -> EmptyStateViewModel {
        if user.isMe {
            if selectedSegment == .left {
                return emptyStateMyRaces
            } else {
                return emptyStateMyChapters
            }
        } else {
            if selectedSegment == .left {
                return emptyStateRaces
            } else {
                return emptyStateChapters
            }
        }
    }

    func title(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        return getEmptyStateViewModel().title
    }

    func description(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        return getEmptyStateViewModel().description
    }

    func verticalOffset(forEmptyDataSet scrollView: UIScrollView) -> CGFloat {

        let headerViewHeight = headerView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
        let segmentedControlHeight = SegmentedTableViewHeaderView.headerHeight
        let tableViewHeaderHeight = headerViewHeight + segmentedControlHeight + Constants.padding*2

        // Add a small difference to align for smaller screens
        if scrollView.frame.height/2 < tableViewHeaderHeight {
            return -(scrollView.frame.height/2 - tableViewHeaderHeight) * 4
        }
        return 0
    }
}

extension UserViewController: EmptyDataSetDelegate {

    func emptyDataSetShouldAllowScroll(_ scrollView: UIScrollView) -> Bool {
        return true
    }

    func emptyDataSetShouldDisplay(_ scrollView: UIScrollView) -> Bool {
        return !shimmeringView.isShimmering
    }
}

