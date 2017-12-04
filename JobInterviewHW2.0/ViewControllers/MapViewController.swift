//
//  MapViewController.swift
//  SomeApp
//
//  Created by Perry on 2/13/16.
//  Copyright © 2016 PerrchicK. All rights reserved.
//

import Foundation
import UIKit
import GoogleMaps
import GoogleMapsBase
import BetterSegmentedControl

class MapViewController: IHUViewController, GMSMapViewDelegate, UISearchBarDelegate, UIGestureRecognizerDelegate, PredictionsViewDelegate {
    enum SearchType: String {
        case people
        case addresses
    }

    enum MovementState {
        case walking
        case driving
    }

    enum MapState {
        case parkingSeeker
        case peopleSeeker
        case placesSeeker
    }

    // Yes, I'm using an explicit unwarp here, taking the "risk" in case a developer will try to put nil here. Which is not suposed to happen.
    var searchType: SearchType! {
        didSet {
            if searchType == .addresses {
                searchBar.placeholder = "search address".localized()
                onSearchCommand = { [weak self] in
                    guard let searchPhrase = self?.searchBar.text else { return }
                    LocationHelper.fetchAutocompleteSuggestions(forPhrase: searchPhrase) { [weak self] (resultTupple) in
                        guard let strongSelf = self, let resultTupple = resultTupple, resultTupple.keyword == self?.searchBar.text else { self?.dismissPredictionsList(); return }
                        
                        strongSelf.presentPredictions(predictions: resultTupple.predictions)
                    }
                }
            } else { // SearchType.people
                searchBar.placeholder = "search people".localized()
                onSearchCommand = { [weak self] in
                    guard let searchPhrase = self?.searchBar.text else { return }
                    
                    FirebaseHelper.queryIndexedData(startsWith: searchPhrase, callback: { [weak self] (people: [PersonSharedLocation]) in
                        self?.presentPredictions(predictions: people)
                    })
                }
            }
        }
    }

    // Same here, using an explicit unwarp here.
    var mapState: MapState! {
        didSet {
            switch mapState {
            case .parkingSeeker:
                onCameraChanged = { [weak self] in
                    guard let strongSelf = self else { return }
                    strongSelf.observationHandler = FirebaseHelper.observeParkingLocations(overlappingCoordinates: strongSelf.getOverlappingCoordinates(), onUpdate: { (parkingLocations: [AvailableParkingLocation]) in
                        📗(parkingLocations)
                    })
                }
            case .placesSeeker:
                onCameraChanged = nil // do nothing
            case .peopleSeeker:
                onCameraChanged = { [weak self] in
                    guard let strongSelf = self else { return }
                    FirebaseHelper.observePeopleLocations(overlappingCoordinates: strongSelf.getOverlappingCoordinates(), onUpdate: { (parkingLocations: [AvailableParkingLocation]) in
                        📗(parkingLocations)
                    })
                }
            default:
                📕("unhandled state")
            }
        }
    }

    //MARK: - Function pointers, will be assigned according to user's needs
    var onSearchCommand: (() -> ())?
    var onCameraChanged: (() -> ())?
    override var shouldForceLocationPermissions: Bool {
        return true
    }
    private var observationHandler: DatabaseReference?
    private var panGestureRecognizer: UIGestureRecognizer?
    private var currentZoom: Float {
        return mapView.camera.zoom
    }
    var movementState: MovementState?
    var parkingCandidate: (timeInterval: TimeInterval, coordinate: CLLocationCoordinate2D)?

    weak var presentedAlertController: UIAlertController?
    lazy var throttler = Throttler()

    private var selectedMarker: GMSMarker?
    private weak var activityIndicatorView: UIActivityIndicatorView?
    lazy var uiBlockingLoaderView: UIView = {
        let uiBlockingLoaderView = UIView()
        self.view.addSubview(uiBlockingLoaderView)
        uiBlockingLoaderView.stretchToSuperViewEdges()
        uiBlockingLoaderView.backgroundColor = UIColor.gray.withAlphaComponent(0.7)
        let _activityIndicatorView = UIActivityIndicatorView()
        uiBlockingLoaderView.addSubview(_activityIndicatorView)
        self.activityIndicatorView = _activityIndicatorView
        _activityIndicatorView.pinToSuperViewCenter()
        _activityIndicatorView.startAnimating()

        return uiBlockingLoaderView
    }()

    lazy var customInputAccessoryView: UIView = {
        let customInputAccessoryButton = UIButton()
        customInputAccessoryButton.setTitle("dismiss keyboard".localized(), for: UIControlState.normal)
        customInputAccessoryButton.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 30)
        customInputAccessoryButton.backgroundColor = UIColor.gray
        customInputAccessoryButton.onClick({ [weak self] _ in
            self?.searchBar.resignFirstResponder()
        })
        return customInputAccessoryButton
    }()

    private(set) var currentMapViewCenter: CLLocationCoordinate2D?
    private var predictions: [Prediction]?
    @IBOutlet weak var predictionsViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var mapView: GMSMapView!
    @IBOutlet weak var predictionsView: PredictionsView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var toggleConsistCurrentLocationButton: UIButton!
    @IBOutlet weak var fetchPlacesButton: UIButton!
    @IBOutlet weak var magnifierRulerView: UIView!
    @IBOutlet weak var actualMagnifierBoundaries: UIView!
    @IBOutlet weak var radiusMagnifierHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var radiusMagnifierImageView: UIImageView!
    // A replacement for UISegmentedControl, more info at: https://littlebitesofcocoa.com/226-bettersegmentedcontrol
    @IBOutlet weak var searchTypeSegmentedControl: BetterSegmentedControl!

    override func viewDidLoad() {
        super.viewDidLoad()

        mapView.settings.rotateGestures = true
        mapView.delegate = self
        predictionsView.delegate = self
        searchBar.delegate = self

        searchType = .addresses
        mapState = .parkingSeeker

        panGestureRecognizer = magnifierRulerView.onPan { [unowned self] (panGestureRecognizer) in
            // Ron, following our discussion in the interview,
            // I almost never use 'unowned', but here is a good example for allowing myself to use it.
            // As I learned from our interview it keeps better performance, thanks :)
            
            let location = panGestureRecognizer.location(in: self.view)
            if let previousLocation = (panGestureRecognizer as? OnPanListener)?.previousLocation {
                let delta = location.y - previousLocation.y
                let newHeight = self.radiusMagnifierHeightConstraint.constant - delta
                if newHeight < self.radiusMagnifierHeightConstraint.constant &&
                    self.radiusMagnifierHeightConstraint.constant <= self.fetchPlacesButton.frame.height {
                    self.radiusMagnifierImageView.animateBounce()
                    return
                }
                if newHeight > self.radiusMagnifierHeightConstraint.constant &&
                    self.radiusMagnifierHeightConstraint.constant >= self.view.frame.height {
                    self.radiusMagnifierImageView.animateBounce()
                    return
                }

                self.radiusMagnifierHeightConstraint.constant = newHeight
            }
        }

        configureUi()
    }
    
    func configureUi() {
        searchTypeSegmentedControl.titles = [SearchType.addresses.rawValue.localized(), SearchType.people.rawValue.localized()]
        try? searchTypeSegmentedControl.setIndex(0)
        searchTypeSegmentedControl.backgroundColor = UIColor.brown
        searchTypeSegmentedControl.titleColor = UIColor.black
        searchTypeSegmentedControl.indicatorViewBackgroundColor = UIColor.red
        searchTypeSegmentedControl.selectedTitleColor = UIColor.white
        searchTypeSegmentedControl.addTarget(self, action: #selector(MapViewController.searchTypeControlValueChanged(_:)), for: .valueChanged)

        radiusMagnifierImageView.isUserInteractionEnabled = false
        predictionsView.isPresented = false
        toggleConsistCurrentLocationButton.transform = CGAffineTransform(rotationAngle: CGFloat(-Double.pi / 4)).concatenating(CGAffineTransform(scaleX: 1.5, y: 1.5))
        searchBar.placeholder = "Search address...".localized()
        searchBar.searchBarStyle = .minimal
        searchBar.barStyle = .blackTranslucent
        searchBar.inputAccessoryView = customInputAccessoryView
        let found: [UIView] = searchBar.findSubviewsInTree(predicateClosure: { $0 is UITextField })
        
        let innerTextFiled: UITextField? = found.first as? UITextField
        innerTextFiled?.textColor = .white
        predictionsView.getRoundedCornered()
    }
    
    lazy var maxMagnifierHeight: CGFloat = {
        return self.view.frame.height
    }()

    var maxPredictionsListViewHeight: CGFloat {
        let predictionsCount: CGFloat = CGFloat((self.predictions?.count) ?? 0)
        return min(self.view.frame.height / 2, predictionsCount * PredictionsView.PredictionCellHeight)
    }

    lazy var minMagnifierHeight: CGFloat = {
        return self.fetchPlacesButton.frame.height * 2
    }()

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // Never used it in this prject, but it will never harm
        if let lastCrashCallStack: [String] = UserDefaults.load(key: Configurations.Keys.Persistency.PermissionRequestCounter) as [String]? {
            presentedAlertController = UIAlertController.makeAlert(title: Configurations.Keys.Persistency.PermissionRequestCounter, message: "\(lastCrashCallStack)")
                .withAction(UIAlertAction(title: "fine", style: .cancel, handler: nil))
                .withAction(UIAlertAction(title: "delete", style: .default, handler: { (alertAction) in
                    UserDefaults.remove(key: Configurations.Keys.Persistency.PermissionRequestCounter).synchronize()
                }))
                .show()
        }

        LocationHelper.shared.startUpdate()

        NotificationCenter.default.addObserver(self, selector: #selector(drawerWillOpenNotification), name: Notification.Name.DrawerWillOpen, object: nil)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        observationHandler?.removeAllObservers()
        observationHandler = nil
    }

    override func onLocationUpdated(updatedLocation: CLLocation) {
        super.onLocationUpdated(updatedLocation: updatedLocation)

        if updatedLocation.speed == 0 {
            parkingCandidate = (Date().timeIntervalSince1970, updatedLocation.coordinate)
            📗("idle")
        }

        if shouldFollowUserLocation ?? false {
            moveCameraToLocation(coordinate: updatedLocation.coordinate, andZoom: 15)
        }

        guard movementState != MovementState.driving else { return }

        if updatedLocation.isDriving {
            movementState = MovementState.driving

            if let parkingCandidate = parkingCandidate {
                let timestamp = parkingCandidate.timeInterval.milliseconds
                FirebaseHelper.indexParking(timestamp, withLocationLatitude: parkingCandidate.coordinate.latitude, withLocationLongitude: parkingCandidate.coordinate.longitude, completionCallback: { (error) in
                    if let error = error {
                        📕("Failed to update location, error: \(error)")
                    }
                })
                putParkingOnMap(availableParkingLocation: AvailableParkingLocation(location: parkingCandidate.coordinate, timestamp: timestamp))
            }

            presentedNavigationAlertController()
        }
    }

    func presentedNavigationAlertController(coordinates: CLLocationCoordinate2D? = nil) {
        guard presentedAlertController == nil else { return }

        let coordinatesString: String
        if let coordinates = coordinates {
            coordinatesString = "\(coordinates.toString())&navigate=yes"
        } else {
            coordinatesString = ""
        }

        presentedAlertController = UIAlertController.makeAlert(title: "Driving?".localized(), message: "Wanna navigate anyware?".localized())
            .withAction(UIAlertAction(title: "Waze", style: UIAlertActionStyle.default, handler: { (alertAction) in
                if let wazeUrl = "waze://?ll=\(coordinatesString)".toUrl(), UIApplication.shared.canOpenURL(wazeUrl) {
                    UIApplication.shared.openURL(wazeUrl)
                }
            }))
            .withAction(UIAlertAction(title: "Apple Maps", style: UIAlertActionStyle.default, handler: { (alertAction) in
                if let mapsUrl = "maps://?ll=\(coordinatesString)".toUrl(), UIApplication.shared.canOpenURL(mapsUrl) {
                    UIApplication.shared.openURL(mapsUrl)
                }
            }))
            .withAction(UIAlertAction(title: "Google Maps", style: UIAlertActionStyle.default, handler: { (alertAction) in
                if let mapsUrl = "comgooglemaps://?center=\(coordinatesString)".toUrl(), UIApplication.shared.canOpenURL(mapsUrl) {
                    UIApplication.shared.openURL(mapsUrl)
                }
            }))
            .withAction(UIAlertAction(title: "dismiss alert".localized(), style: UIAlertActionStyle.cancel, handler: nil))
            .show()
    }

    func moveCameraToCurrentLocation() {
        guard let currentLocation = currentLocation else { return }
        moveCameraToLocation(coordinate: currentLocation.coordinate, andZoom: 3)
    }

    func moveCameraToLocation(coordinate: CLLocationCoordinate2D, andZoom zoomValue: Float? = nil) {
        if let zoomValue = zoomValue {
            mapView.animate(toZoom: zoomValue)
        }

        mapView.animate(toLocation: coordinate)
    }
    
    @objc func searchTypeControlValueChanged(_ sender: BetterSegmentedControl) {
        if sender.index == 0 {
            searchType = .addresses
        } else {
            searchType = .people
        }
    }
    @objc func drawerWillOpenNotification(notification: Notification) {
        searchBar.resignFirstResponder()
    }
    
    func presentPredictions(predictions: [Prediction]) {
        self.predictions = predictions

        if predictions.count == 0 {
            dismissPredictionsList()
        } else {
            predictionsViewHeightConstraint.constant = maxPredictionsListViewHeight - 2 // 2 pixels
            if predictionsView.isHidden {
                popInPredictionsView()
            }
        }
        predictionsView.refresh()
    }
    
    func popInPredictionsView() {
        let transition = CATransition()
        transition.startProgress = 0
        transition.endProgress = 1
        transition.type = kCATransitionPush
        transition.subtype = kCATransitionFromBottom
        transition.duration = 0.3
        
        // Add the transition animation to both layers
        predictionsView.layer.add(transition, forKey: "transition")
        
        // Finally, change the visibility of the layers.
        predictionsView.isPresented = true
    }

    func dismissPredictionsList() {
        let transition = CATransition()
        transition.startProgress = 0
        transition.endProgress = 1
        transition.type = kCATransitionPush
        transition.subtype = kCATransitionFromTop
        transition.duration = 0.3
        
        // Add the transition animation to both layers
        predictionsView.layer.add(transition, forKey: "transition")
        
        // Finally, change the visibility of the layers.
        predictionsView.isPresented = false
    }
    
    @IBAction func onToggleFollowLocationClicked(_ sender: UIButton) {
        toggleFollowLocation()
    }
    
    func toggleFollowLocation(shouldTurnOn turnOn: Bool? = nil) {
        let shouldTurnOn = turnOn ?? (toggleConsistCurrentLocationButton.alpha != 1)
        shouldFollowUserLocation = shouldTurnOn

        let rotation: CGFloat = shouldTurnOn ? CGFloat(-Double.pi / 4) : CGFloat(Double.pi / 8)
        let scaleValue: CGFloat = shouldTurnOn ? 1.5 : 1
        let alpha: CGFloat = shouldTurnOn ? 1 : 0.5
        let scaleTransform: CGAffineTransform = CGAffineTransform(scaleX: scaleValue, y: scaleValue)

        UIView.animate(withDuration: 0.2) { [weak self] in
            self?.toggleConsistCurrentLocationButton.alpha = alpha
            self?.toggleConsistCurrentLocationButton.transform = CGAffineTransform(rotationAngle: rotation).concatenating(scaleTransform)
        }
    }

    @IBAction func onSearchInRadiusClicked(_ sender: UIButton) {
        guard sender == fetchPlacesButton, let currentMapViewCenter = currentMapViewCenter else { return }
        sender.animateScaleAndFadeOut(scaleSize: 15) { [weak self] _ in
            self?.fetchPlacesButton.alpha = 1
            self?.fetchPlacesButton.transform = CGAffineTransform(scaleX: 1, y: 1)
        }

        let scale: Double = Configurations.Constants.ClosestZoomRatioScale / (pow(2, Double(currentZoom - 1)))
//                        CGFloat zoom = self.mapView.camera.zoom;
//                        CGFloat scale = kClosestZoomRatioScale / powf(2.0, zoom - 1);
        let metersPerPixel: Double = Double(scale / 512)
        var magnifierValue: Double = Double(PerrFuncs.percentOfValue(ofValue: self.radiusMagnifierHeightConstraint.constant, fromValue: self.view.frame.height))
        magnifierValue = magnifierValue / 100
        let range: Double = magnifierValue * 2
        let radius: Float = Float(range * metersPerPixel)

        LocationHelper.fetchNearByPlaces(aroundLocation: currentMapViewCenter, withRadius: radius) { [weak self] (locationAndResultsTuple) in
            guard let places = locationAndResultsTuple?.places else { return }
            let placeNames: [String] = places.flatMap({ (p) -> String? in
                return p.placeName
            })
            📗("fetched place names: \(placeNames)")

            for place in places {
                self?.putPlaceOnMap(place: place)
            }
        }
    }

    func putPersonOnMap(personSharedLocation: PersonSharedLocation) {
        let marker: GMSMarker = GMSMarker(position: personSharedLocation.location)
        marker.title = personSharedLocation.nickname
        marker.icon = GMSMarker.markerImage(with: UIColor.blue)
        marker.appearAnimation = .pop
        marker.map = mapView
        marker.userData = personSharedLocation
    }

    func putParkingOnMap(availableParkingLocation: AvailableParkingLocation) {
        let marker: GMSMarker = GMSMarker(position: availableParkingLocation.location)
        marker.title = "Parking"
        //marker.iconView = UIImageView(image: #imageLiteral(resourceName: "parking_sign"))
        marker.icon =  #imageLiteral(resourceName: "parking_sign")
        marker.appearAnimation = .pop
        marker.snippet = Date(timeIntervalSince1970: availableParkingLocation.timestamp.seconds).shortHourRepresentation()
        marker.map = mapView
        marker.userData = availableParkingLocation
    }

    func putPlaceOnMap(place: Place) {
        let marker: GMSMarker = GMSMarker(position: place.position)
        marker.title = place.placeName
        marker.appearAnimation = .pop
        marker.snippet = place.position.toString(precision: 6)
        marker.map = mapView
        marker.userData = place
    }
    
    func mapView(_ mapView: GMSMapView, didTapInfoWindowOf marker: GMSMarker) {
        if let place = marker.userData as? Place {
            presentPlaceInfo(place: place)
        } else if let personSharedLocation = marker.userData as? PersonSharedLocation {
            presentedNavigationAlertController(coordinates: personSharedLocation.location)
        } else if let availableParkingLocation = marker.userData as? AvailableParkingLocation {
            presentedNavigationAlertController(coordinates: availableParkingLocation.location)
        }
    }
    
    func getOverlappingCoordinates() -> CLLocationCoordinate2D {
        let cameraBounds = mapView.cameraBounds(inView: actualMagnifierBoundaries)
        let precision = (cameraBounds.bottomRight ~ cameraBounds.topLeft).latitude.exractPrecision()
        let multiplier = Double(10 * precision - 1)
        let latitude = Double(Int(cameraBounds.bottomRight.latitude * multiplier)) / multiplier
        let longitude = Double(Int(cameraBounds.bottomRight.longitude * multiplier)) / multiplier
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    func presentPlaceInfo(place: Place) {
        uiBlockingLoaderView.alpha = 0
        uiBlockingLoaderView.isPresented = true
        uiBlockingLoaderView.animateFade(fadeIn: true)
        LocationHelper.fetchPlace(byPlaceId: place.placeId, andPlaceName: place.placeName) { [weak self] placeInfoTuple in
            self?.uiBlockingLoaderView.animateFade(fadeIn: false)
            guard let place = placeInfoTuple?.place else { return }

            let placeInfoAlertController = UIAlertController.makeActionSheet(title: place.placeName, message: place.address ?? place.position.toString())
                .withAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil))
            
            if let phoneNumber = place.phoneNumber {
                placeInfoAlertController.addAction(UIAlertAction(title: phoneNumber, style: UIAlertActionStyle.default, handler: { _ in
                    UIAlertController.makeActionSheet(title: phoneNumber, message: "actions")
                        .withAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil))
                        .withAction(UIAlertAction(title: "Copy", style: UIAlertActionStyle.default, handler: { _ in
                            PerrFuncs.copyToClipboard(stringToCopy: phoneNumber)
                        }))
                        .withAction(UIAlertAction(title: "Call", style: UIAlertActionStyle.default, handler: { _ in
                            if let phoneNumberUrl = "tel://\(phoneNumber)".toUrl(), UIApplication.shared.canOpenURL(phoneNumberUrl) {
                                UIApplication.shared.openURL(phoneNumberUrl)
                            }
                        }))
                        .show()
                }))
            }
            
            if let websiteString = place.website, let websiteUrl = websiteString.toUrl(), UIApplication.shared.canOpenURL(websiteUrl) {
                placeInfoAlertController.addAction(UIAlertAction(title: "Website", style: UIAlertActionStyle.default, handler: { _ in
                    UIAlertController.makeActionSheet(title: "website", message: websiteString)
                        .withAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil))
                        .withAction(UIAlertAction(title: "Copy", style: UIAlertActionStyle.default, handler: { _ in
                            PerrFuncs.copyToClipboard(stringToCopy: websiteString)
                        }))
                        .withAction(UIAlertAction(title: "Visit", style: UIAlertActionStyle.default, handler: { _ in
                            UIApplication.shared.openURL(websiteUrl)
                        }))
                        .show()
                }))
            }
            
            placeInfoAlertController.show()
        }
    }

    //MARK: - Swizzled UIGestureRecognizerDelegate

    @objc func swizzled_gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        toggleFollowLocation(shouldTurnOn: false)
        return true
    }

    //MARK: - GMSMapViewDelegate
    
    func mapView(_ mapView: GMSMapView, didChange position: GMSCameraPosition) {
        currentMapViewCenter = position.target
        onCameraChanged?()
    }
  
    func mapView(_ mapView: GMSMapView, didTapPOIWithPlaceID placeID: String, name: String, location: CLLocationCoordinate2D) {
        let _selectedMarker = GMSMarker(position: location)
        selectedMarker = _selectedMarker
        selectedMarker?.title = name
        selectedMarker?.snippet = location.toString(precision: 6)
        selectedMarker?.map = mapView
        mapView.selectedMarker = selectedMarker
        LocationHelper.fetchPlace(byPlaceId: placeID) { placeInfoTuple in
            _selectedMarker.userData = placeInfoTuple?.place
        }
    }

    func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D) {
        searchBar.resignFirstResponder()
    }

    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
        selectedMarker = marker
        mapView.selectedMarker = selectedMarker
        return true
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        
        if let components: [String] = searchBar.text?
            .replacingOccurrences(of: " ", with: "")
            .components(separatedBy: ","),
            components.count == 2 {
            if let latitude = Double(components[0]), let longitude = Double(components[1]) {
                let locationFromString: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                moveCameraToLocation(coordinate: locationFromString)
            }
        }
    }

    var shouldFollowUserLocation: Bool?

    //MARK: - UISearchBarDelegate
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.count == 0 { dismissPredictionsList(); return }
        fetchPredictions(searchText: searchText)
    }
    
    func fetchPredictions(searchText: String? = nil) {
        guard let searchText = searchText, searchText.count > 0 else {
            dismissPredictionsList()
            return
        }

        // Supplies a much better solution than this one: https://github.com/PerrchicK/iOS-JobInterviewProject/blob/076e8bd26929d55f658addc73625eb32744e3930/CandidateProject/Classes/ViewControllers/MapViewController.m#L180
        throttler.throttle(timeout: 0.3) { [weak self] in
            self?.onSearchCommand?()
        }
    }

    //MARK: - PredictionsViewDelegate
    func didScroll(_ predictionsView: PredictionsView) {
        searchBar.resignFirstResponder()
    }

    func didSelectPrediction(_ predictionsView: PredictionsView, dataIndex: Int) {
        dismissPredictionsList()

        toggleFollowLocation(shouldTurnOn: false)

        if let addressPrediction = predictions?[safe: dataIndex] as? AddressPrediction {
            LocationHelper.fetchPlace(byPrediction: addressPrediction, resultCallback: { [weak self] (resultTuple) in
                guard let strongSelf = self, let resultTuple = resultTuple, let place = resultTuple.place else { return }
                📗("resultTuple: \(resultTuple)")
                strongSelf.moveCameraToLocation(coordinate: CLLocationCoordinate2D(latitude: place.latitude, longitude: place.longitude))
            })
        } else if let personSharedLocation = predictions?[safe: dataIndex] as? PersonSharedLocation {
            putPersonOnMap(personSharedLocation: personSharedLocation)
            moveCameraToLocation(coordinate: CLLocationCoordinate2D(latitude: personSharedLocation.location.latitude, longitude: personSharedLocation.location.longitude))
        }
    }
    
    func dataTitle(_ predictionsView: PredictionsView, dataIndex: Int) -> String {
        let title: String = (predictions?[safe: dataIndex])?.predictionDescription ?? ""

        return title
    }
    
    func dataCount(_ predictionsView: PredictionsView) -> Int {
        return predictions?.count ?? 0
    }
}

extension Place {
    var position: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

extension CLLocationCoordinate2D {
    func toString(precision: Int? = nil) -> String {
        if let precision = precision {
            return String(format: "%.\(precision)f,%.\(precision)f", latitude, longitude)
        }

        return String(format: "\(latitude),\(longitude)")
    }
}

extension GMSMapView {
    // From: https://stackoverflow.com/questions/31943778/google-maps-sdk-ios-calculate-radius-according-zoom-level
    // and: http://jslim.net/blog/2013/07/02/ios-get-the-radius-of-mkmapview/
    func getCenterCoordinate() -> CLLocationCoordinate2D {
        let centerPoint = self.center
        let centerCoordinate = self.projection.coordinate(for: centerPoint)
        return centerCoordinate
    }
    
    func cameraBounds(inView _view: UIView? = nil) -> (topLeft: CLLocationCoordinate2D, bottomRight: CLLocationCoordinate2D) {
        let view = _view ?? self
        
        let topLeftPoint = convert(CGPoint(x: 0, y: 0), from: view)
        let bottomRightPoint = convert(CGPoint(x: view.frame.size.width, y: view.frame.size.width), from: view)
        let topLeftCoordinate = projection.coordinate(for: topLeftPoint)
        let bottomRightCoordinate = projection.coordinate(for: bottomRightPoint)
        return (topLeftCoordinate, bottomRightCoordinate)
    }

    func getTopCenterCoordinate() -> CLLocationCoordinate2D {
        // to get coordinate from CGPoint of your map
        let topCenterCoor = self.convert(CGPoint(x: self.frame.size.width / 2.0, y: 0), from: self)
        let point = self.projection.coordinate(for: topCenterCoor)
        return point
    }

    func getRadius() -> CLLocationDistance {
        let centerCoordinate = getCenterCoordinate()
        // init center location from center coordinate
        let centerLocation = CLLocation(latitude: centerCoordinate.latitude, longitude: centerCoordinate.longitude)
        let topCenterCoordinate = getTopCenterCoordinate()
        let topCenterLocation = CLLocation(latitude: topCenterCoordinate.latitude, longitude: topCenterCoordinate.longitude)
        
        let radius = CLLocationDistance(centerLocation.distance(from: topCenterLocation))
        
        return round(radius)
    }
}

extension Double {
    func exractPrecision() -> Int {
        // Keep the sign
        let sign: Double = self < 0 ? -1 : 1
        let unsigned: Double = self * sign

        var precision: Int = 0
        var precisioned: Double = unsigned

        while precisioned < 1 {
            precisioned *= 10
            precision += 1
        }
        
        return precision
    }
}

extension CLLocation {
    var isDriving: Bool {
        return speed > 5 // 5 = 20kph
    }
}

extension TimeInterval {
    var milliseconds: Int64 {
        return Int64(self * TimeInterval(1000))
    }
}

extension Int64 {
    var seconds: TimeInterval {
        return TimeInterval(self) / TimeInterval(1000)
    }
}
