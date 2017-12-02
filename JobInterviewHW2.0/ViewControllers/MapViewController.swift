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

class MapViewController: IHUViewController, GMSMapViewDelegate, UISearchBarDelegate, UIGestureRecognizerDelegate, PredictionsViewDelegate {
    //, PlaceInfoViewControllerDelegate {
    
    override var shouldForceLocationPermissions: Bool {
        return true
    }
    private var panGestureRecognizer: UIGestureRecognizer?
    private var currentZoom: Float {
        return mapView.camera.zoom
    }
    lazy var throttler = Throttler()
    private var selectedMarker: GMSMarker?
    lazy var customInputAccessoryView: UIView = {
        let customInputAccessoryButton = UIButton()
        customInputAccessoryButton.setTitle("dismiss", for: UIControlState.normal)
        customInputAccessoryButton.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 50)
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
    @IBOutlet weak var radiusMagnifierHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var radiusMagnifierImageView: UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()

        mapView.settings.rotateGestures = true
        mapView.delegate = self
        predictionsView.delegate = self
        searchBar.delegate = self

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

                self.radiusMagnifierHeightConstraint.constant = newHeight - 2 // 2 pixels
            }
        }
        panGestureRecognizer?.delegate = self

        configureUi()
    }
    
    func configureUi() {
        radiusMagnifierImageView.isUserInteractionEnabled = false
        predictionsView.isPresented = false
        searchBar.placeholder = "Search address...".localized()
        searchBar.searchBarStyle = .minimal
        searchBar.barStyle = .blackTranslucent
        searchBar.inputAccessoryView = customInputAccessoryView
        let found: [UIView] = searchBar.findSubviewsInTree(predicateClosure: { $0 is UITextField } )
        let innerTextFiled: UITextField? = found.first as? UITextField
        innerTextFiled?.textColor = .white
        predictionsView.getRoundedCornered()

//        [self.btnCurrentCoordinate setTitle:@"" forState:UIControlStateNormal];
//        self.lblAddress.text = @"";
//        self.searchToolHeightConstraint.constant *= 2;
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
            UIAlertController.makeAlert(title: Configurations.Keys.Persistency.PermissionRequestCounter, message: "\(lastCrashCallStack)")
                .withAction(UIAlertAction(title: "fine", style: .cancel, handler: nil))
                .withAction(UIAlertAction(title: "delete", style: .default, handler: { (alertAction) in
                    UserDefaults.remove(key: Configurations.Keys.Persistency.PermissionRequestCounter).synchronize()
                }))
                .show()
        }

        LocationHelper.shared.startUpdate()

        NotificationCenter.default.addObserver(self, selector: #selector(drawerWillOpenNotification), name: Notification.Name.DrawerWillOpen, object: nil)
    }

    
    override func onLocationUpdated(updatedLocation: CLLocation) {
        //📗("verticalAccuracy: \(updatedLocation.verticalAccuracy), horizontalAccuracy: \(updatedLocation.horizontalAccuracy)")
        if shouldFollowLocation {
            moveCameraToLocation(coordinate: updatedLocation.coordinate, andZoom: 15)
        }
        
        if updatedLocation.speed > 5 { // 5 = 10kph
            UIAlertController.makeAlert(title: "Driving?", message: "Wanna navigate anyware?")
                .withAction(UIAlertAction(title: "Waze", style: UIAlertActionStyle.default, handler: { (alertAction) in
                    if let wazeUrl = "waze://navigate".toUrl() {
                        UIApplication.shared.canOpenURL(wazeUrl)
                    }
                }))
                .withAction(UIAlertAction(title: "Waze", style: UIAlertActionStyle.default, handler: { (alertAction) in
                    if let wazeUrl = "waze://navigate".toUrl() {
                        UIApplication.shared.canOpenURL(wazeUrl)
                    }
                }))
                .withAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil))
                .show()
        }
    }
    
    func moveCameraToLocation(coordinate: CLLocationCoordinate2D, andZoom zoomValue: Float? = nil) {
        if let zoomValue = zoomValue {
            mapView.animate(toZoom: zoomValue)
        }

        mapView.animate(toLocation: coordinate)
    }
    
    @objc func drawerWillOpenNotification(notification: Notification) {
        searchBar.resignFirstResponder()
    }
    
    func presentAdressesPredictions(predictions: [Prediction]) {
        self.predictions = predictions

        if predictions.count == 0 {
            dismissPredictionsList()
        } else {
            predictionsViewHeightConstraint.constant = maxPredictionsListViewHeight
            predictionsView.isPresented = true
        }
        predictionsView.refresh()
    }
    
    func dismissPredictionsList() {
        predictionsView.isPresented = false
    }
    
    @IBAction func onToggleFollowLocationClicked(_ sender: UIButton) {
        toggleFollowLocation()
    }
    
    func toggleFollowLocation(shouldTurnOn: Bool? = nil) {
        if let shouldTurnOn = shouldTurnOn {
            toggleConsistCurrentLocationButton.alpha = shouldTurnOn ? 1 : 0.5
        } else {
            toggleConsistCurrentLocationButton.alpha = toggleConsistCurrentLocationButton.alpha == 1 ? 0.5 : 1
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

    func putPlaceOnMap(place: Place) {
        let marker: GMSMarker = GMSMarker(position: place.position)//[ markerWithPosition:place.placePosition];
        marker.title = place.placeName
        marker.snippet = place.position.toString(precision: 3)
        marker.map = mapView
        marker.userData = place
    }
    
    func mapView(_ mapView: GMSMapView, didTapInfoWindowOf marker: GMSMarker) {
        if let place = marker.userData as? Place {
            presentPlaceInfo(place: place)
        }
    }
    
    func presentPlaceInfo(place: Place) {
        📗(place)
    }

    //MARK: - GMSMapViewDelegate
    func mapView(_ mapView: GMSMapView, didChange position: GMSCameraPosition) {
        currentMapViewCenter = position.target
//    [self _setLocationText:position.target];
    
    // Prevent searching address every time the text changes, wait for the user to pause his movement on the map
//    self.delayFromLastCoordinateChange = [[NSDate new] timeIntervalSince1970];
//    dispatch_time_t dispatchTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kDelayBeforeSearch * NSEC_PER_SEC));
//    typeof(self) __weak weakSelf = self;
//    dispatch_after(dispatchTime, dispatch_get_main_queue(), ^{
//    if ([[NSDate new] timeIntervalSince1970] - self.delayFromLastCoordinateChange > kDelayBeforeSearch) {
//    typeof(self) strongSelf = weakSelf;
//    [strongSelf _updateAddressByLocation];
//    }
//    });
    }

    func mapView(_ mapView: GMSMapView, didLongPressAt coordinate: CLLocationCoordinate2D) {
    // Zoom out
//    [mapView animateToZoom:mapView.camera.zoom - 1.0];
    }
  
    func mapView(_ mapView: GMSMapView, didTapPOIWithPlaceID placeID: String, name: String, location: CLLocationCoordinate2D) {
        selectedMarker = GMSMarker(position: location)
        selectedMarker?.title = name
        selectedMarker?.snippet = location.toString(precision: 3)
        selectedMarker?.map = mapView
        mapView.selectedMarker = selectedMarker
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
        fetchPredictions(searchText: searchBar.text)
        searchBar.resignFirstResponder()
    }

    var shouldFollowLocation: Bool {
        return toggleConsistCurrentLocationButton.alpha == 1
    }

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
        throttler.throttle(timeout: 0.3) {
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
            LocationHelper.fetchAutocompleteSuggestions(forPhrase: searchText) { [weak self] (resultTupple) in
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                guard let strongSelf = self, let resultTupple = resultTupple, resultTupple.keyword == self?.searchBar.text else { self?.dismissPredictionsList(); return }
                
                strongSelf.presentAdressesPredictions(predictions: resultTupple.predictions)
            }
        }
    }

    //MARK: - PredictionsViewDelegate
    func didScroll(_ predictionsView: PredictionsView) {
        searchBar.resignFirstResponder()
    }

    func didSelectPrediction(_ predictionsView: PredictionsView, dataIndex: Int) {
        dismissPredictionsList()

        toggleFollowLocation(shouldTurnOn: false)

        if let prediction = predictions?[safe: dataIndex] {
            LocationHelper.fetchPlace(byPrediction: prediction, resultCallback: { [weak self] (resultTuple) in
                guard let strongSelf = self, let resultTuple = resultTuple, let place = resultTuple.place else { return }
                📗("resultTuple: \(resultTuple)")
                strongSelf.moveCameraToLocation(coordinate: CLLocationCoordinate2D(latitude: place.latitude, longitude: place.longitude))
            })
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
