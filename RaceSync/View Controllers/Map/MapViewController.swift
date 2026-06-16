//
//  RaceMapViewController.swift
//  RaceSync
//
//  Created by Ignacio Romero Zurbuchen on 2019-11-15.
//  Copyright © 2019 MultiGP Inc. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import RaceSyncAPI

struct MapViewLocation {
    let name: String
    let coordinate: CLLocationCoordinate2D
    let color: UIColor
}

protocol MapViewControllerDelegate: AnyObject {
    func mapViewController(_ mapViewController: MapViewController, didSelectLocation location: MapViewLocation)
}

class MapViewController: UIViewController {

    var delegate: MapViewControllerDelegate?

    var showsDirection: Bool = true {
        didSet {
            if showsDirection {
                navigationItem.rightBarButtonItem = navigationBarButtonItem
            } else {
                navigationItem.rightBarButtonItem = nil
            }
        }
    }

    var showsCompass: Bool = false {
        didSet {
            compassButton.isHidden = !showsCompass
            if showsCompass {
                updateCompassVisibility()
            }
        }
    }

    var viewportCoordinate: CLLocationCoordinate2D?

    // MARK: - Private Variables

    fileprivate let locations: [MapViewLocation]

    fileprivate lazy var mapView: MKMapView = {
        let mapView = MKMapView()
        mapView.showsScale = true
        mapView.showsUserLocation = true
        mapView.delegate = self
        return mapView
    }()

    fileprivate let initialSelectedMapSegment: MapSegment = .map

    fileprivate lazy var segmentedControl: UISegmentedControl = {
        let items = [MapSegment.map.title, MapSegment.hybrid.title, MapSegment.satellite.title]
        let segmentedControl = UISegmentedControl(items: items)
        segmentedControl.addTarget(self, action: #selector(didChangeSegment), for: .valueChanged)
        segmentedControl.selectedSegmentIndex = initialSelectedMapSegment.rawValue
        segmentedControl.backgroundColor = Color.gray100.withAlphaComponent(0.5)
        return segmentedControl
    }()

    fileprivate lazy var navigationBarButtonItem: UIBarButtonItem = {
        return UIBarButtonItem(image: ButtonImg.directions, style: .plain, target: self, action: #selector(didPressDirectionsButton))
    }()

    // MARK: - Compass

    fileprivate enum CompassState {
        case deselected, centered, heading
    }

    fileprivate var compassState: CompassState = .deselected {
        didSet { updateCompassAppearance(animated: true) }
    }

    fileprivate lazy var compassButton: UIButton = {
        let button = UIButton(type: .system)
        button.addTarget(self, action: #selector(didPressCompassButton), for: .touchUpInside)
        button.isHidden = true

        if #available(iOS 26, *) {
            var config = UIButton.Configuration.glass()
            config.cornerStyle = .capsule
            config.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
            button.configuration = config
        } else {
            button.backgroundColor = .clear
            button.layer.cornerRadius = Constants.compassSize / 2
            button.clipsToBounds = true

            let blur = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterial))
            blur.isUserInteractionEnabled = false
            blur.layer.cornerRadius = Constants.compassSize / 2
            blur.clipsToBounds = true
            button.insertSubview(blur, at: 0)
            blur.snp.makeConstraints { $0.edges.equalToSuperview() }
        }

        return button
    }()

    fileprivate lazy var locationManager: CLLocationManager = {
        let manager = CLLocationManager()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        return manager
    }()

    fileprivate var userHeading: CLLocationDirection = 0
    fileprivate var isUserInBoundary: Bool = false

    // MARK: - Gestures

    fileprivate lazy var doubleTapGesture: UITapGestureRecognizer = {
        let gesture = UITapGestureRecognizer(target: self, action: #selector(didDoubleTapMap))
        gesture.numberOfTapsRequired = 2
        gesture.delegate = self
        return gesture
    }()

    fileprivate lazy var panGesture: UIPanGestureRecognizer = {
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(didInteractWithMap))
        gesture.delegate = self
        return gesture
    }()

    fileprivate lazy var pinchGesture: UIPinchGestureRecognizer = {
        let gesture = UIPinchGestureRecognizer(target: self, action: #selector(didInteractWithMap))
        gesture.delegate = self
        return gesture
    }()

    fileprivate enum Constants {
        static let padding: CGFloat = UniversalConstants.padding
        static let cellHeight: CGFloat = UniversalConstants.cellHeight
        static let annotationIdentifier: String = "Annotation"
        static let compassSize: CGFloat = 44
        static let compassPadding: CGFloat = 12
        static let zoomFactor: Double = 0.5
    }

    // MARK: - Initialization

    init(with location: MapViewLocation) {
        self.locations = [location]
        super.init(nibName: nil, bundle: nil)
        title = "Location"
    }

    init(with locations: [MapViewLocation]) {
        self.locations = locations
        super.init(nibName: nil, bundle: nil)
        title = "Location"
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()
        setupLayout()
        loadMapView()
        locationManager.requestWhenInUseAuthorization()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setToolbarHidden(false, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        locationManager.stopUpdatingHeading()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    // MARK: - Layout

    fileprivate func setupLayout() {
        if navigationController?.viewControllers.count == 1 {
            navigationItem.leftBarButtonItem = UIBarButtonItem(image: ButtonImg.close, style: .plain, target: self, action: #selector(didPressCloseButton))
        }

        if showsDirection {
            navigationItem.rightBarButtonItem = navigationBarButtonItem
        }

        let space = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let toolbarItem = UIBarButtonItem(customView: segmentedControl)
        toolbarItems = [space, toolbarItem, space]

        let compassItem = UIBarButtonItem(customView: compassButton)
        if showsCompass {
            toolbarItems? += [compassItem]
        }
        
        view.addSubview(mapView)
        mapView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.bottom.equalToSuperview()
        }

//        view.addSubview()
//        compassButton.snp.makeConstraints {
//            $0.top.equalTo(view.safeAreaLayoutGuide).offset(Constants.compassPadding)
//            $0.trailing.equalToSuperview().inset(Constants.compassPadding)
//            $0.width.height.equalTo(Constants.compassSize)
//        }

//        mapView.addGestureRecognizer(doubleTapGesture)
//        mapView.addGestureRecognizer(panGesture)
//        mapView.addGestureRecognizer(pinchGesture)
    }

    fileprivate func loadMapView() {
        let distance: Double = 1000
        let meters = CLLocationDistance(distance)

        if let coordinate = viewportCoordinate {
            let region = MKCoordinateRegion(center: coordinate, latitudinalMeters: distance*2, longitudinalMeters: distance*2)
            mapView.cameraBoundary = MKMapView.CameraBoundary(coordinateRegion: region)
            mapView.cameraZoomRange = MKMapView.CameraZoomRange(
                minCenterCoordinateDistance: 2000,
                maxCenterCoordinateDistance: 10000
            )
            mapView.setRegion(region, animated: false)
        } else if let location = locations.first {
            let coordinate = location.coordinate
            let region = MKCoordinateRegion(center: coordinate, latitudinalMeters: meters, longitudinalMeters: meters)
            let mapRect = MKCoordinateRegion.mapRectForCoordinateRegion(region)
            let paddedMapRect = mapRect.offsetBy(dx: 0, dy: -(distance*2))
            mapView.setVisibleMapRect(paddedMapRect, animated: false)
        }

        for location in locations {
            let annotation = MKPointAnnotation()
            annotation.coordinate = location.coordinate
            annotation.title = location.name
            mapView.addAnnotation(annotation)
        }
    }

    // MARK: - Compass

    fileprivate func updateCompassAppearance(animated: Bool) {
        let symbolName: String

        switch compassState {
        case .deselected:
            symbolName = "location"
        case .centered:
            symbolName = "location.fill"
        case .heading:
            symbolName = "location.north.line.fill"
        }

        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
        let image = UIImage(systemName: symbolName, withConfiguration: config)

        let apply = {
            if #available(iOS 26, *) {
                var config = self.compassButton.configuration ?? UIButton.Configuration.glass()
                config.image = image
                config.cornerStyle = .capsule
                config.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
                config.baseBackgroundColor = UIColor.black.withAlphaComponent(0.6)
                config.baseForegroundColor = .white
                self.compassButton.configuration = config
            } else {
                self.compassButton.setImage(image, for: .normal)
                self.compassButton.tintColor = Color.black
            }

            // Rotate the icon to reflect heading in heading mode
            let angle: CGFloat = self.compassState == .heading ? CGFloat(self.userHeading) * (.pi / 180) : 0
            self.compassButton.imageView?.transform = CGAffineTransform(rotationAngle: -angle)
        }

        if animated {
            UIView.animate(withDuration: 0.25, animations: apply)
        } else {
            apply()
        }
    }

    fileprivate func updateCompassVisibility() {
        guard showsCompass else {
            compassButton.isHidden = true
            return
        }
        compassButton.isHidden = !isUserInBoundary
    }

    fileprivate func resetToDeselected() {
        guard compassState != .deselected else { return }
        compassState = .deselected
        locationManager.stopUpdatingHeading()

        // Reset map rotation
        let camera = mapView.camera.copy() as! MKMapCamera
        camera.heading = 0
        mapView.setCamera(camera, animated: true)
    }

    // MARK: - Actions

    @objc fileprivate func didPressCompassButton() {
        switch compassState {
        case .deselected:
            compassState = .centered
            locationManager.startUpdatingLocation()
            if let userCoord = mapView.userLocation.location?.coordinate {
                let camera = mapView.camera.copy() as! MKMapCamera
                camera.centerCoordinate = userCoord
                mapView.setCamera(camera, animated: true)
            }
        case .centered:
            compassState = .heading
            locationManager.startUpdatingHeading()
        case .heading:
            resetToDeselected()
        }
    }

    @objc fileprivate func didDoubleTapMap(_ gesture: UITapGestureRecognizer) {
        let point = gesture.location(in: mapView)
        let coordinate = mapView.convert(point, toCoordinateFrom: mapView)

        let camera = mapView.camera.copy() as! MKMapCamera
        camera.centerCoordinate = coordinate
        camera.centerCoordinateDistance *= Constants.zoomFactor
        mapView.setCamera(camera, animated: true)

        resetToDeselected()
    }

    @objc fileprivate func didInteractWithMap(_ gesture: UIGestureRecognizer) {
        if gesture.state == .began {
            resetToDeselected()
        }
    }

    @objc func didPressDirectionsButton() {
        guard let location = locations.first else { return }

        let coordinate = location.coordinate
        let lat = coordinate.latitude
        let long = coordinate.longitude

        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.view.tintColor = Color.blue

        alert.addAction(UIAlertAction(title: "Open in Maps", style: .default, handler: { (action) in
            guard let url = URL(string: "\(ExternalAppUrl.AppleMaps)?daddr=\(lat),\(long)&dirflg=d") else { return }
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }))

        if canOpenGoogleMaps {
            alert.addAction(UIAlertAction(title: "Open in Google Maps", style: .default, handler: { (action) in
                guard let url = URL(string: "\(ExternalAppUri.GoogleMaps)?daddr=\(lat),\(long)") else { return }
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }))
        }

        if canOpenWaze {
            alert.addAction(UIAlertAction(title: "Open in Waze", style: .default, handler: { (action) in
                guard let url = URL(string: "\(ExternalAppUri.Waze)?ll=\(lat),\(long)&navigate=yes") else { return }
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }))
        }

        alert.addAction(UIAlertAction(title: "Copy Coordinate", style: .default, handler: { (action) in
            UIPasteboard.general.string = "\(lat), \(long)"
        }))

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

        present(alert, animated: true)
    }

    @objc func didPressCloseButton() {
        dismiss(animated: true)
    }

    @objc fileprivate func didChangeSegment() {
        guard let segment = MapSegment(rawValue: segmentedControl.selectedSegmentIndex) else { return }
        mapView.mapType = segment.mapType
    }

    // MARK: - Integration

    fileprivate var canOpenGoogleMaps: Bool {
        guard let url = URL(string: ExternalAppUri.GoogleMaps) else { return false }
        return UIApplication.shared.canOpenURL(url)
    }

    fileprivate var canOpenWaze: Bool {
        guard let url = URL(string: ExternalAppUri.Waze) else { return false }
        return UIApplication.shared.canOpenURL(url)
    }
}

// MARK: - MKMapViewDelegate

extension MapViewController: MKMapViewDelegate {

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard annotation is MKPointAnnotation else { return nil }

        let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: Constants.annotationIdentifier) as? MKMarkerAnnotationView
            ?? MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: Constants.annotationIdentifier)

        guard let location = locations.first(where: { $0.coordinate == annotation.coordinate }) else { return nil }

        annotationView.annotation = annotation
        annotationView.canShowCallout = false
        annotationView.titleVisibility = .visible
        annotationView.markerTintColor = location.color
        annotationView.glyphImage = UIImage(named: "icn_activity_mgp")
        annotationView.glyphTintColor = Color.white
        return annotationView
    }

    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        mapView.deselectAnnotation(view.annotation, animated: false)
        
        guard let annotation = view.annotation as? MKPointAnnotation else { return }
        guard let location = locations.first(where: { $0.coordinate == annotation.coordinate }) else { return }
        
        delegate?.mapViewController(self, didSelectLocation: location)
    }

    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        guard let userCoord = userLocation.location?.coordinate else { return }

        // Check if the user is within the camera boundary region
        if let boundary = mapView.cameraBoundary {
            isUserInBoundary = boundary.region.contains(userCoord)
        } else {
            isUserInBoundary = true
        }

        updateCompassVisibility()

        // Keep map centered on user if in centered or heading state
        if compassState == .centered || compassState == .heading {
            guard isUserInBoundary else {
                resetToDeselected()
                return
            }
            let camera = mapView.camera.copy() as! MKMapCamera
            camera.centerCoordinate = userCoord
            mapView.setCamera(camera, animated: true)
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension MapViewController: CLLocationManagerDelegate {

    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        guard compassState == .heading else { return }
        userHeading = newHeading.trueHeading

        let camera = mapView.camera.copy() as! MKMapCamera
        camera.heading = newHeading.trueHeading
        mapView.setCamera(camera, animated: false)

        // Rotate the compass icon counter to the map rotation so it always points north visually
        UIView.animate(withDuration: 0.1) {
            self.compassButton.imageView?.transform = CGAffineTransform(rotationAngle: -CGFloat(newHeading.trueHeading) * (.pi / 180))
        }
    }
}

// MARK: - UIGestureRecognizerDelegate

extension MapViewController: UIGestureRecognizerDelegate {

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // Allow double-tap and pan/pinch to coexist with MKMapView's built-in gestures
        return true
    }
}

// MARK: - MapSegment

fileprivate enum MapSegment: Int {
    case map, hybrid, satellite

    var title: String {
        switch self {
        case .map:          return "Map"
        case .hybrid:       return "Hybrid"
        case .satellite:    return "Satellite"
        }
    }

    var mapType: MKMapType {
        switch self {
        case .map:          return .standard
        case .hybrid:       return .hybrid
        case .satellite:    return .satellite
        }
    }
}

// MARK: - MKCoordinateRegion + contains

fileprivate extension MKCoordinateRegion {
    func contains(_ coordinate: CLLocationCoordinate2D) -> Bool {
        let latDelta = span.latitudeDelta / 2
        let lonDelta = span.longitudeDelta / 2
        return abs(coordinate.latitude - center.latitude) <= latDelta
            && abs(coordinate.longitude - center.longitude) <= lonDelta
    }
}
