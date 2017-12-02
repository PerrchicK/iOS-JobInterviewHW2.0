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
    private var currentZoom: Float?
    lazy var throttler = Throttler()

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
    @IBOutlet weak var radiusMagnifierHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var radiusMagnifierImageView: UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()

        mapView.delegate = self
        predictionsView.delegate = self
        searchBar.delegate = self

        panGestureRecognizer = radiusMagnifierImageView.onPan { [unowned self] (panGestureRecognizer) in
            let location = panGestureRecognizer.location(in: self.view)
//            let draggingLocationYAxis = self.view.frame.height - location.y
            /// Percentage from screeen height
            if let previousLocation = (panGestureRecognizer as? OnPanListener)?.previousLocation {
                📗(previousLocation)
                let delta = location.y - previousLocation.y
                var newHeight = self.radiusMagnifierHeightConstraint.constant + delta
//                newHeight = min(newHeight, self.minMagnifierHeight)
//                newHeight = max(newHeight, self.maxMagnifierHeight)
                self.radiusMagnifierHeightConstraint.constant = newHeight
            }
        }
        panGestureRecognizer?.delegate = self

        configureUi()
    }
    
    func configureUi() {
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
        testGeocode()
    }

    
    override func onLocationUpdated(updatedLocation: CLLocation) {
        //📗("verticalAccuracy: \(updatedLocation.verticalAccuracy), horizontalAccuracy: \(updatedLocation.horizontalAccuracy)")
        if shouldFollowLocation {
            moveCameraToLocation(coordinate: updatedLocation.coordinate, andZoom: 15)
        }
        
        if updatedLocation.speed > 2 { // if updatedLocation.speed > 5 {
            ToastMessage.show(messageText: "is running?")
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
        let maxHeight = view.frame.height - searchBar.frame.origin.y + searchBar.frame.height
        predictionsViewHeightConstraint.constant = maxHeight//min(maxHeight, CGFloat(predictions.count) * PredictionsView.PredictionCellHeight)
        if predictions.count == 0 {
            dismissPredictionsList()
        } else {
            predictionsView.isPresented = true
        }
        predictionsView.refresh()
    }
    
    func dismissPredictionsList() {
        predictionsView.isPresented = false
    }
    
    @IBAction func onToggleFollowLocationClicked(_ sender: UIButton) {
        sender.alpha = sender.alpha == 1 ? 0.5 : 1
    }

    @IBAction func onSearchInRadiusClicked(_ sender: UIButton) {
        guard sender == fetchPlacesButton else { return }
        sender.animateScaleAndFadeOut(scaleSize: 20) { [weak self] _ in
            self?.fetchPlacesButton.alpha = 1
            self?.fetchPlacesButton.transform = CGAffineTransform(scaleX: 1, y: 1)
        }
    }

    func testGeocode() {
//        let afkeaLatitude: Double = 32.115216
//        let afkeaLongitude: Double = 34.8174598
//
//        LocationHelper.findAddressByCoordinates(latitude: afkeaLatitude, longitude: afkeaLongitude) { address in
//            //result = "Found address: \(firstPlaceName)"
//            ToastMessage.show(messageText: address.or("Parsing failed"))
//        }
    }

    //MARK: - GMSMapViewDelegate
    func mapView(_ mapView: GMSMapView, didChange position: GMSCameraPosition) {
        currentZoom = position.zoom
        searchBar.resignFirstResponder()
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
    }
    
    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
//    [self _presentPlaceInfoOfPlaceId:marker.userData];
        return true
    }

    //MARK: - UIGestureRecognizerDelegate
    //TODO: Sharpen user interaction
//    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
//        return radiusMagnifierImageView.pixelColor(atPoint: gestureRecognizer.location(in: radiusMagnifierImageView)) != .clear
//    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }

    var shouldFollowLocation: Bool {
        return toggleConsistCurrentLocationButton.alpha == 1
    }
    //MARK: - UISearchBarDelegate
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.count == 0 { dismissPredictionsList(); return }
        throttler.throttle(timeout: 0.3) {
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
            LocationHelper.fetchAutocompleteSuggestions(forPhrase: searchText) { [weak self] (resultTupple) in
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                guard let strongSelf = self, let resultTupple = resultTupple, resultTupple.keyword == searchBar.text else { self?.dismissPredictionsList(); return }

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
