//
//  RaceDetailViewController.swift
//  RaceSync
//
//  Created by Ignacio Romero Zurbuchen on 2019-11-15.
//  Copyright © 2019 MultiGP Inc. All rights reserved.
//

import UIKit
import MapKit
import SnapKit
import SwiftValidators
import RaceSyncAPI

class RaceDetailViewController: UIViewController, ViewJoinable, RaceTabbable {

    // MARK: - Public Variables

    var raceController: RaceController
    
    var race: Race {
        get { return raceController.race! }
    }

    var raceApi: RaceApi {
        get { return raceController.raceApi }
    }

    // MARK: - Private Variables

    fileprivate lazy var mapView: MKMapView = {
        let mapView = MKMapView()
        mapView.isZoomEnabled = false
        mapView.isScrollEnabled = false
        mapView.isRotateEnabled = false
        mapView.isPitchEnabled = false
        mapView.showsUserLocation = false
        mapView.delegate = self

        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapMapView))
        mapView.addGestureRecognizer(tapGestureRecognizer)

        return mapView
    }()

    fileprivate lazy var titleLabel: PasteboardLabel = {
        let label = PasteboardLabel()
        label.font = UIFont.systemFont(ofSize: 23, weight: .regular)
        label.textColor = Color.black
        label.numberOfLines = 2
        return label
    }()

    fileprivate lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        label.textColor = Color.gray300
        label.numberOfLines = 1
        return label
    }()

    fileprivate lazy var feeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        label.textColor = Color.gray300
        label.textAlignment = .right
        label.numberOfLines = 1
        return label
    }()

    fileprivate lazy var rotatingIconView: RotatingIconView = {
        let view = RotatingIconView()
        view.tintColor = Color.yellow
        view.imageView.image = ButtonImg.trophy?.withRenderingMode(.alwaysTemplate)
        view.imageView.tintColor = Color.yellow
        return view
    }()

    fileprivate lazy var joinButton: JoinButton = {
        let button = JoinButton(type: .system)
        button.addTarget(self, action: #selector(didPressJoinButton), for: .touchUpInside)
        button.hitTestEdgeInsets = UIEdgeInsets(proportionally: -10)
        return button
    }()

    fileprivate lazy var miniJoinButton: JoinButton = {
        let button = JoinButton(type: .system)
        button.addTarget(self, action: #selector(didPressJoinButton), for: .touchUpInside)
        button.hitTestEdgeInsets = UIEdgeInsets(proportionally: -10)
        button.isCompact = true
        button.imageEdgeInsets = .zero
        button.contentEdgeInsets = .zero
        button.isHidden = true
        return button
    }()

    fileprivate lazy var memberBadgeView: MemberBadgeView = {
        let view = MemberBadgeView(type: .system)
        view.addTarget(self, action: #selector(didPressMembersBadge), for: .touchUpInside)
        view.isUserInteractionEnabled = true
        return view
    }()

    func contextualButton() -> PasteboardButton {
        let button = PasteboardButton(type: .system)
        button.shouldHighlight = true
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        button.titleLabel?.numberOfLines = 2
        button.tintColor = Color.black
        return button
    }

    fileprivate lazy var date1Button: PasteboardButton = {
        let button = contextualButton()
        button.addTarget(self, action: #selector(didPressDateButton), for: .touchUpInside)
        return button
    }()

    fileprivate lazy var date2Button: PasteboardButton = {
        let button = contextualButton()
        button.addTarget(self, action: #selector(didPressDateButton), for: .touchUpInside)
        button.isHidden = true
        return button
    }()

    fileprivate lazy var dateIconView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        view.backgroundColor = Color.clear
        return view
    }()

    fileprivate lazy var locationButton: PasteboardButton = {
        let button = contextualButton()
        button.addTarget(self, action: #selector(didPressLocationButton), for: .touchUpInside)
        button.tintColor = Color.link
        return button
    }()

    fileprivate lazy var locationIconView: UIImageView = {
        let view = UIImageView()
        view.image = SystemImg.pin_small?.withRenderingMode(.alwaysTemplate)
        view.contentMode = .scaleAspectFit
        view.backgroundColor = Color.clear
        view.tintColor = Color.link
        return view
    }()

    fileprivate lazy var htmlView: RichEditorView = {
        let view = RichEditorView()
        view.isEditable = false
        view.isScrollEnabled = false
        view.delegate = self
        return view
    }()

    fileprivate lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.backgroundColor = Color.white
        scrollView.isScrollEnabled = true
        scrollView.alwaysBounceVertical = true
        scrollView.delegate = self
        return scrollView
    }()

    fileprivate lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.register(cellType: FormTableViewCell.self)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.tableFooterView = UIView()
        tableView.isScrollEnabled = false

        let separatorLine = UIView.separatorLine()
        tableView.tableHeaderView = separatorLine
        separatorLine.snp.makeConstraints {
            $0.width.equalToSuperview()
        }
        return tableView
    }()

    fileprivate lazy var rightStackView: UIStackView = {
        let topStackView = UIStackView(arrangedSubviews: [miniJoinButton, joinButton])
        topStackView.axis = .horizontal
        topStackView.distribution = .equalSpacing
        topStackView.spacing = Constants.padding/4

        miniJoinButton.snp.makeConstraints {
            $0.width.height.equalTo(Constants.minButtonHeight)
        }

        var subviews: [UIView] = [topStackView, feeLabel, memberBadgeView]
        let stackView = UIStackView(arrangedSubviews: subviews)
        stackView.axis = .vertical
        stackView.alignment = .trailing
        stackView.distribution = .equalSpacing
        stackView.spacing = Constants.padding/2
        return stackView
    }()

    fileprivate lazy var leftStackView: UIStackView = {
        // vertical stack for the date buttons
        let stackView1 = UIStackView(arrangedSubviews: [date1Button, date2Button])
        stackView1.axis = .vertical
        stackView1.alignment = .leading
        stackView1.distribution = .fill

        // horizontal stack for the icon + the date stack
        let stackView2 = UIStackView(arrangedSubviews: [dateIconView, stackView1])
        stackView2.axis = .horizontal
        stackView2.alignment = .center
        stackView2.distribution = .fill
        stackView2.spacing = Constants.padding * 3/4

        if canDisplayAddress {
            let stackView3 = UIStackView(arrangedSubviews: [locationIconView, locationButton])
            stackView3.axis = .horizontal
            stackView3.alignment = .center
            stackView3.distribution = .fill
            stackView3.spacing = Constants.padding * 3/4

            // vertical stack containing the icon+dates row and the location button
            let stackView4 = UIStackView(arrangedSubviews: [stackView2, stackView3])
            stackView4.axis = .vertical
            stackView4.alignment = .leading
            stackView4.distribution = .equalSpacing
            stackView4.spacing = Constants.padding / 2

            return stackView4
        } else {
            return stackView2
        }
    }()

    fileprivate var raceCoordinates: CLLocationCoordinate2D? {
        if race.courseId != nil, let lat = CLLocationDegrees(race.latitude), let long = CLLocationDegrees(race.longitude) {
            return CLLocationCoordinate2D(latitude: lat, longitude: long)
        }
        return nil
    }

    fileprivate var canDisplayGQIcon: Bool {
        guard raceViewModel.race.raceClass != .esport else { return false }
        return race.officialStatus == .approved
    }

    fileprivate var canDisplayAddress: Bool {
        guard raceViewModel.race.raceClass != .esport else { return false }
        return raceViewModel.fullLocationLabel.count > 0
    }

    fileprivate var canDisplayEndDate: Bool {
        guard let text = raceViewModel.endDateLabel else { return false }
        return text.count > 0
    }

    fileprivate var canDisplayMap: Bool {
        guard raceViewModel.race.raceClass != .esport else { return false }
        return raceCoordinates != nil
    }

    fileprivate var canDisplayFee: Bool {
        return raceViewModel.feeLabel.count > 0
    }

    fileprivate var tableViewRows = [Row]()
    fileprivate var didTapCell: Bool = false

    fileprivate var raceViewModel: RaceViewModel
    fileprivate var chapterApi = ChapterApi()
    fileprivate var userApi = UserApi()
    fileprivate var seriesApi = SeriesApi()

    fileprivate var htmlViewHeightConstraint: Constraint?
//    fileprivate let ignoreFinalizingError: Bool = true // The API finalize(id) still returns 500 error. Reported https://github.com/MultiGP/multigp-com/issues/93

    fileprivate enum Constants {
        static let padding: CGFloat = UniversalConstants.padding
        static let contentInsets = UIEdgeInsets(top: padding/2, left: 10, bottom: padding/2, right: padding/2)
        static let mapHeight: CGFloat = UIScreen.main.bounds.height/3 // 1/3 of the screen
        static let cellHeight: CGFloat = 50
        static let maxButtonSize: CGFloat = 100
        static let minButtonHeight: CGFloat = 32
        static let buttonSpacing: CGFloat = 12
        static let htmlpadding: CGFloat = 12
    }

    // MARK: - Initialization

    init(with controller: RaceController) {
        self.raceController = controller
        self.raceViewModel = RaceViewModel(with: controller.race!)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()

        setupLayout()
        registerJoinable()
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

    fileprivate func setupLayout() {
        loadRows()
        populateContent()
        configureNavigationItems()

        let contentView = UIView()
        let headerView = UIView()
        view.backgroundColor = Color.white

        if canDisplayMap {
            contentView.addSubview(mapView)
            mapView.snp.makeConstraints {
                $0.top.equalToSuperview().offset(-topOffset)
                $0.leading.trailing.equalToSuperview()
                $0.height.equalTo(Constants.mapHeight)
            }
        }

        contentView.addSubview(headerView)
        headerView.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview()

            if canDisplayMap {
                $0.top.equalTo(mapView.snp.bottom).offset(Constants.padding)
            } else {
                $0.top.equalToSuperview().offset(Constants.padding)
            }
        }

        headerView.addSubview(subtitleLabel)
        subtitleLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(Constants.padding)
            $0.top.equalToSuperview()
        }

        if canDisplayGQIcon {
            headerView.addSubview(rotatingIconView)
            rotatingIconView.snp.makeConstraints {
                $0.top.equalTo(subtitleLabel.snp.bottom).offset(Constants.padding/2)
                $0.leading.equalToSuperview().offset(Constants.padding)
                $0.width.height.equalTo(20)
            }
        }

        headerView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints {
            $0.top.equalTo(subtitleLabel.snp.bottom).offset(Constants.padding/2)
            $0.trailing.equalToSuperview().offset(-Constants.padding)

            if canDisplayGQIcon {
                $0.leading.equalTo(rotatingIconView.snp.trailing).offset(Constants.padding/2)
            } else {
                $0.leading.equalToSuperview().offset(Constants.padding)
            }
        }

        headerView.addSubview(rightStackView)
        rightStackView.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(Constants.padding)
            $0.width.greaterThanOrEqualTo(Constants.maxButtonSize)
            $0.trailing.equalToSuperview().offset(-Constants.padding)
        }

        headerView.addSubview(leftStackView)
        leftStackView.snp.makeConstraints {
            $0.top.equalTo(rightStackView.snp.top)
            $0.leading.equalToSuperview().offset(Constants.padding)
            $0.trailing.equalTo(rightStackView.snp.leading).offset(-Constants.padding/2)
        }

        headerView.snp.makeConstraints {
            $0.bottom.equalToSuperview().priority(.low) // if needed
            $0.bottom.greaterThanOrEqualTo(rightStackView.snp.bottom).offset(Constants.padding/2)
            $0.bottom.greaterThanOrEqualTo(leftStackView.snp.bottom).offset(Constants.padding/2)
        }

        contentView.addSubview(htmlView)
        htmlView.snp.makeConstraints {
            $0.top.equalTo(headerView.snp.bottom)
            $0.leading.trailing.equalToSuperview()
            $0.width.equalTo(view.bounds.width)

            htmlViewHeightConstraint = $0.height.equalTo(0).constraint
            htmlViewHeightConstraint?.activate()
        }

        contentView.addSubview(tableView)
        tableView.snp.makeConstraints {
            $0.top.equalTo(htmlView.snp.bottom).offset(Constants.padding/2)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(Constants.cellHeight*CGFloat(tableViewRows.count))
            $0.bottom.equalToSuperview()
        }

        scrollView.addSubview(contentView)
        contentView.snp.makeConstraints {
            $0.top.leading.trailing.bottom.equalToSuperview()
        }

        view.addSubview(scrollView)
        scrollView.snp.makeConstraints {
            $0.width.equalTo(UIScreen.main.bounds.width)
            $0.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }
    }

    fileprivate func configureNavigationItems() {
        title = "Details"
        tabBarItem = UITabBarItem(title: title, image: SystemImg.calendarCclock, selectedImage: nil)

        navigationItem.rightBarButtonItem = raceController.navigationItems()
    }

    fileprivate func loadRows() {
        tableViewRows = [
            !race.ownerUserName.isEmpty && !race.ownerId.isEmpty ? Row.owner : nil,
            raceViewModel.chapterLabel.isEmpty ? nil : Row.chapter,
            raceViewModel.seriesLabel.isEmpty ? nil : Row.series,
            raceViewModel.seasonLabel.isEmpty ? nil : Row.season,
            race.isZippyQEnabled ? Row.zippyQ : nil,
            raceViewModel.subtitleLabel.string.isEmpty ? nil : Row.class,
            race.liveTimeEventUrl != nil ? Row.results : nil
        ].compactMap { $0 }
    }

    fileprivate func populateContent() {
        titleLabel.text = raceViewModel.titleLabel.uppercased()
        subtitleLabel.attributedText = raceViewModel.subtitleLabel
        memberBadgeView.count = raceViewModel.participantCount

        configureJoinButton()
        configureDateLabels()
        configureLocationLabels()
        configureMap()

        // Load the HTML on the next runloop
        DispatchQueue.main.async { [weak self] in
            guard let s = self else { return }
            s.configureHTML()
        }

        // lays out the content and helps calculating the content size
        let contentRect: CGRect = scrollView.subviews.reduce(into: .zero) { rect, view in
            rect = rect.union(view.frame)
        }
        
        // Seems like this is not doing anything?
        scrollView.contentSize = CGSize(width: contentRect.size.width, height: contentRect.size.height)
    }

    fileprivate func configureJoinButton() {
        joinButton.joinState = raceViewModel.joinState

        // showing an indicator if the user has joined, only if the race fee is still pending
        if race.isJoined && race.status == .open && race.isPayable {
            miniJoinButton.joinState = .joined
            miniJoinButton.isUserInteractionEnabled = true // set to false when compact mode
            miniJoinButton.isHidden = false
        } else {
            miniJoinButton.joinState = .closed
            miniJoinButton.isHidden = true
        }
    }

    fileprivate func configureDateLabels() {
        var date1Label: String?
        var date2Label: String?
        var dateImage: UIImage?

        if canDisplayEndDate {
            if raceViewModel.sameDay {
                date1Label = raceViewModel.dateLabel?.components(separatedBy: "@").first?.trimmingCharacters(in: .whitespaces)
                date2Label = raceViewModel.timeLabel
                dateImage = ButtonImg.date_path2
            } else {
                date1Label = raceViewModel.startDateLabel
                date2Label = raceViewModel.endDateLabel
                dateImage = ButtonImg.date_path1
            }
        } else {
            date1Label = raceViewModel.startDateLabel
            dateImage = ButtonImg.cal_small
        }

        date1Button.setTitle(date1Label, for: .normal)
        date2Button.setTitle(date2Label, for: .normal)
        date2Button.isHidden = !canDisplayEndDate
        dateIconView.image = dateImage
    }

    fileprivate func configureLocationLabels() {
        guard canDisplayAddress else { return }

        locationButton.setTitle(raceViewModel.fullLocationLabel, for: .normal)

        // Bring the icon to the first line, if there are more than 1 line of text
        if let label = locationButton.titleLabel, label.numberOfVisibleLines > 2 {
            locationButton.imageEdgeInsets = UIEdgeInsets(top: -Constants.padding, left: -Constants.padding, bottom: 0, right: 0)
        }

        if canDisplayFee {
            feeLabel.text = raceViewModel.feeLabel
        }

        locationButton.isHidden = !canDisplayAddress
        feeLabel.isHidden = !canDisplayFee
    }

    fileprivate func configureHTML() {
        var html = ""
        let spacing = Constants.padding * 3/4
        let race = raceViewModel.race

        if race.description.stripHTML().count > 0 {
            let description = race.description.replaceHTMLColorTag(with: Color.gray300).stripHTMLFontTag().stripHTMLEdges()
            html += "<div id=\"description\">\(description)</div>"
        }
        if race.content.stripHTML().count > 0 {
            let content = race.content.replaceHTMLColorTag(with: Color.black).stripHTMLFontTag().stripHTMLEdges()
            html += "<div id=\"content\" style=\"color:\(Color.black.toHexString()); padding-top: \(spacing)px; padding-bottom: \(spacing)px;\">\(content)</div>"
        }
        if race.itinerary.stripHTML().count > 0 {
            let itinerary = race.description.replaceHTMLColorTag(with: Color.gray100).stripHTMLFontTag().stripHTMLEdges()
            html += "<hr style=\"border-top: 0.25px solid;\">"
            html += "<div id=\"itinerary\" style=\"padding-top: \(spacing)px;\">\(itinerary)</div>"
        }

        htmlView.html = html
    }

    fileprivate func configureMap() {
        guard canDisplayMap, let coordinates = raceCoordinates else { return }

        let distance = CLLocationDistance(1000)
        let region = MKCoordinateRegion(center: coordinates, latitudinalMeters: distance, longitudinalMeters: distance)

        let mapRect = MKCoordinateRegion.mapRectForCoordinateRegion(region)
        let paddedMapRect = mapRect.offsetBy(dx: 0, dy: -1500) // TODO: Convert Screen points to Map points instead of harcoded value

        let location = MKPointAnnotation()
        location.coordinate = coordinates

        DispatchQueue.main.async {
            self.mapView.addAnnotation(location)
            self.mapView.setVisibleMapRect(paddedMapRect, animated: false)
        }
    }

    // MARK: - Actions

    @objc fileprivate func didTapMapView(_ sender: UITapGestureRecognizer) {
        showMapView()
    }

    @objc func didPressDateButton(_ sender: UITapGestureRecognizer) {
        raceController.saveInCalendar()
    }

    @objc fileprivate func didPressLocationButton(_ sender: UIButton) {
        guard canDisplayMap else { return }
        showMapView()
    }

    @objc fileprivate func didPressJoinButton(_ sender: JoinButton) {
        let state = sender.joinState

        toggleJoinButton(sender, forRace: raceViewModel.race, raceApi: raceApi) { [weak self] (newState) in
            if state != newState {
                self?.race.isJoined = (newState == .joined)
                self?.reloadRace()
            }
        }
    }

    @objc fileprivate func didPressMembersBadge(_ sender: UIButton) {
        guard let tabBarController = tabBarController as? RaceTabBarController else { return }
        tabBarController.selectTab(.pilots)
    }

    func canInteract(with cell: FormTableViewCell) -> Bool {
        guard !cell.isLoading else { return false }
        guard !didTapCell else { return false }
        return true
    }

    func showUserProfile(_ cell: FormTableViewCell) {
        guard canInteract(with: cell) else { return }
        setLoading(cell, loading: true)

        userApi.getUser(with: race.ownerId) { [weak self] (user, error) in
            if let user = user {
                let vc = UserViewController(with: user)
                self?.navigationController?.pushViewController(vc, animated: true)
            } else if let _ = error {
                // TODO: Handle error
            }
            self?.setLoading(cell, loading: false)
        }
    }

    func showClassRaces(_ cell: FormTableViewCell) {
        guard canInteract(with: cell) else { return }
        setLoading(cell, loading: true)

        let raceClass = race.raceClass

        raceApi.getRaces(with: [.upcoming], raceClass: raceClass) { [weak self] (races, error) in
            if let races = races {
                let sortedViewModels = RaceViewModel.sortedViewModels(with: races, sorting: .descending)
                let vc = RaceListViewController(sortedViewModels, raceClass: raceClass)
                self?.navigationController?.pushViewController(vc, animated: true)
            } else if let _ = error {
                // TODO: Handle error
            }
            self?.setLoading(cell, loading: false)
        }
    }

    func showChapterProfile(_ cell: FormTableViewCell) {
        guard canInteract(with: cell) else { return }
        setLoading(cell, loading: true)

        chapterApi.getChapter(with: race.chapterId) { [weak self] (chapter, error) in
            if let chapter = chapter {
                let vc = ChapterViewController(with: chapter)
                self?.navigationController?.pushViewController(vc, animated: true)
            } else if let _ = error {
                // TODO: Handle error
            }
            self?.setLoading(cell, loading: false)
        }
    }

    func showSeriesDetail(_ cell: FormTableViewCell) {
        guard canInteract(with: cell), let seriesId = race.seriesId else { return }
        setLoading(cell, loading: true)

        seriesApi.view(series: seriesId) { [weak self] (series, error) in
            if let series = series {
                let vc = SeriesTabBarController(with: series)
                self?.navigationController?.pushViewController(vc, animated: true)
            } else if let _ = error {
                // TODO: Handle error
            }
            self?.setLoading(cell, loading: false)
        }
    }

    func showSeasonRaces(_ cell: FormTableViewCell) {
        guard canInteract(with: cell), let seasonId = race.seasonId else { return }
        setLoading(cell, loading: true)

        raceApi.getRaces(seasonId: seasonId) { [weak self] (races, error) in
            if let races = races {
                let sortedViewModels = RaceViewModel.sortedViewModels(with: races)
                let vc = RaceListViewController(sortedViewModels, seasonId: seasonId)
                vc.title = self?.race.seasonName
                self?.navigationController?.pushViewController(vc, animated: true)
            } else if let _ = error {
                // TODO: Handle error
            }
            self?.setLoading(cell, loading: false)
        }
    }

    func showMapView() {
        guard let coordinates = raceCoordinates, let address = race.address else { return }

        let vc = MapViewController(with: coordinates, address: address)
        vc.title = "Race Location"
        vc.showsDirection = true
        let nc = NavigationController(rootViewController: vc)
        present(nc, animated: true)
    }

    func openRace(_ cell: FormTableViewCell) {
        guard canInteract(with: cell) else { return }
        setLoading(cell, loading: true)

        raceApi.open(race: race.id) { [weak self] (status, error) in
            if status {
                self?.race.status = .open
                self?.reloadRace()
            }
            self?.setLoading(cell, loading: false)
        }
    }

    func closeRace(_ cell: FormTableViewCell) {
        guard canInteract(with: cell) else { return }
        setLoading(cell, loading: true)

        raceApi.close(race: race.id) { [weak self] (status, error) in
            if status {
                self?.race.status = .closed
                self?.reloadRace()
            }

            self?.setLoading(cell, loading: false)
        }
    }

    func openZippyQSchedule(_ cell: FormTableViewCell) {
        let zippyqUrl = MGPWeb.getUrl(for: .zippyqView, value: race.id)
        WebViewController.open(zippyqUrl)
    }

    func openLiveFPV(_ cell: FormTableViewCell) {
        guard let url = race.liveTimeEventUrl else { return }
        WebViewController.open(url)
    }

    // MARK: - Data Update

    // ViewJoinable
    func loadContent(forced: Bool = false) {
        if forced {
            reloadRace()
        } else {
            reloadContent()
        }
    }

    // RaceTabbable
    func reloadContent() {
        raceViewModel = RaceViewModel(with: race)

        loadRows()
        populateContent()

        // updating the height of the table view, since the number of rows could have changed
        tableView.snp.updateConstraints { make in
            make.height.equalTo(Constants.cellHeight*CGFloat(tableViewRows.count))
        }

        tableView.reloadData()
    }

    func reloadRace() {
        raceController.reloadRace()
    }

    func setLoading(_ cell: FormTableViewCell, loading: Bool) {
        cell.isLoading = loading
        didTapCell = loading
    }
}

// MARK: - UITableView Delegate

extension RaceDetailViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) as? FormTableViewCell else { return }
        let row = tableViewRows[indexPath.row]

        if row == .class {
            showClassRaces(cell)
        } else if row == .owner {
            showUserProfile(cell)
        } else if row == .chapter {
            showChapterProfile(cell)
        } else if row == .series {
            showSeriesDetail(cell)
        } else if row == .season {
            showSeasonRaces(cell)
        } else if row == .zippyQ {
            openZippyQSchedule(cell)
        } else if row == .results {
            openLiveFPV(cell)
        }

        tableView.deselectRow(at: indexPath, animated: true)
    }
}

// MARK: - UITableView DataSource

extension RaceDetailViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableViewRows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return formTableViewCell(for: indexPath)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return Constants.cellHeight
    }

    func formTableViewCell(for indexPath: IndexPath) -> FormTableViewCell {
        let cell = tableView.dequeueReusableCell(forIndexPath: indexPath) as FormTableViewCell

        let row = tableViewRows[indexPath.row]
        cell.textLabel?.text = row.title
        cell.isLoading = false
        cell.detailImage = nil

        if row == .chapter {
            cell.detailTextLabel?.text = raceViewModel.chapterLabel
        } else if row == .owner {
            cell.detailTextLabel?.text = raceViewModel.ownerLabel
        } else if row == .series {
            cell.detailTextLabel?.text = raceViewModel.seriesLabel
        } else if row == .season {
            cell.detailTextLabel?.text = raceViewModel.seasonLabel
        } else if row == .zippyQ {
            cell.detailTextLabel?.text = "multigp.com"
        } else if row == .class {
            cell.detailImage = raceViewModel.raceClassImage()
        } else if row == .results, let url = race.liveTimeEventUrl {
            if let web = AppWeb(url: url) {
                cell.detailImage = web.image

                if cell.detailImage == nil {
                    cell.detailTextLabel?.text = URL(string: url)?.rootDomain ?? ""
                }
            }
        }

        return cell
    }
}

extension RaceDetailViewController: RichEditorDelegate {

    func richEditor(_ editor: RichEditorView, heightDidChange height: Int) {
        var offset = CGFloat(height)
        offset += Constants.htmlpadding*2

        htmlViewHeightConstraint?.update(offset: offset)
    }

    func richEditor(_ editor: RichEditorView, shouldInteractWith url: URL) -> Bool {

        if let link = DeepLink.create(from: url), ApplicationControl.shared.canHandleDeepLink(link) {
            ApplicationControl.shared.handle(link)
        } else if Validator.isEmail().apply(url.absoluteString) {
            // leave the system handle emails
            UIApplication.shared.open(url)
        } else {
            // open url using in-app browser, else the url is open on the WKWebView
            WebViewController.open(url)
        }
        return false
    }
}

// MARK: - MKMapView Delegate

extension RaceDetailViewController: MKMapViewDelegate {

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard annotation is MKPointAnnotation else { return nil }

        let identifier = "Annotation"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)

        if annotationView == nil {
            annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            annotationView?.image = ButtonImg.map_annotation
            annotationView!.canShowCallout = true
        } else {
            annotationView!.annotation = annotation
        }

        return annotationView
    }
}

fileprivate enum Row: Int, EnumTitle, CaseIterable {
    case chapter, owner, series, season, zippyQ, `class`, results

    var title: String {
        switch self {
        case .chapter:          return "Chapter"
        case .owner:            return "Coordinator"
        case .series:           return "Series"
        case .season:           return "Season"
        case .zippyQ:           return "ZippyQ"
        case .class:            return "Class"
        case .results:          return "Results on"
        }
    }
}
