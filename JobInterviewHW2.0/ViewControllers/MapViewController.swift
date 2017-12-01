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

class MapViewController: IHUViewController, GMSMapViewDelegate, UISearchBarDelegate, UIGestureRecognizerDelegate {
    //, PlaceInfoViewControllerDelegate {
    
    override var shouldForceLocationPermissions: Bool {
        return true
    }
    private var panGestureRecognizer: UIGestureRecognizer?
    private var currentZoom: Float?
    var middleHeight: CGFloat = 0

    @IBOutlet weak var mapView: GMSMapView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var fetchPlacesButton: UIButton!
    @IBOutlet weak var radiusMagnifierHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var radiusMagnifierImageView: UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()

        mapView.delegate = self;
        
        panGestureRecognizer = radiusMagnifierImageView.onPan { [unowned self] (panGestureRecognizer) in
            let location = panGestureRecognizer.location(in: self.view)
            let draggingLocationYAxis = self.view.frame.height - location.y
            /// Percentage from screeen height
            let maxHeight: CGFloat = self.view.frame.height
            let magnifierValue: CGFloat = PerrFuncs.percentOfValue(ofValue: draggingLocationYAxis, fromValue: maxHeight)
            self.radiusMagnifierHeightConstraint.constant = PerrFuncs.valueOfPercent(percentage: magnifierValue, fromValue: maxHeight)
        }
        panGestureRecognizer?.delegate = self

        configureUi()
    }
    
    func configureUi() {
        self.searchBar.placeholder = "Search address...".localized()
        searchBar.barStyle = .black
        let found: [UIView] = searchBar.findSubviewsInTree(predicateClosure: { $0 is UITextField } )
        (found.first as? UITextField)?.textColor = .white
//        [self _setTextColor:[UIColor whiteColor] inSubviewsOfView:self.searchBar];
//
//        self.lblPulse.hidden = YES;
//
//        [self.btnCurrentCoordinate setTitle:@"" forState:UIControlStateNormal];
//        self.lblAddress.text = @"";
//        self.searchToolHeightConstraint.constant *= 2;
        middleHeight = radiusMagnifierHeightConstraint.constant
    }

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

        testGeocode()
    }
    
    func testGeocode() {
        let afkeaLatitude: Double = 32.115216
        let afkeaLongitude: Double = 34.8174598
        
        LocationHelper.shared.findAddressByCoordinates(latitude: afkeaLatitude, longitude: afkeaLongitude) { address in
            //result = "Found address: \(firstPlaceName)"
            ToastMessage.show(messageText: address.or("Parsing failed"))
        }
    }

    //MARK: - GMSMapViewDelegate
    func mapView(_ mapView: GMSMapView, didChange position: GMSCameraPosition) {
        currentZoom = position.zoom
        LocationHelper.shared.stopUpdate()
//    [self.locationManager stopUpdatingLocation];
//    [self.searchBar resignFirstResponder];
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
  
//    -(void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
//    [searchBar resignFirstResponder];
//    }

    override func onLocationUpdated(updatedLocation: CLLocation) {
        📗("verticalAccuracy: \(updatedLocation.verticalAccuracy), horizontalAccuracy: \(updatedLocation.horizontalAccuracy)")
        moveCameraToLocation(coordinate: updatedLocation.coordinate, andZoom: 15)
        if updatedLocation.speed > 2 { // if updatedLocation.speed > 5 {
            ToastMessage.show(messageText: "is running?")
        }
    }

    func moveCameraToLocation(coordinate: CLLocationCoordinate2D, andZoom zoomValue: Float? = nil) {
        if let zoomValue = zoomValue {
            mapView.animate(toZoom: zoomValue)
        }// else if let currentZoom = currentZoom {
//            mapView.animate(toZoom: zoomValue)
//        }
        
        mapView.animate(toLocation: coordinate)
    }

    func presentAdressesPredictions(predictions: [String]) {
    }

    //MARK: - UIGestureRecognizerDelegate
    //TODO: Sharpen this
//    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
//        return radiusMagnifierImageView.pixelColor(atPoint: gestureRecognizer.location(in: radiusMagnifierImageView)) != .clear
//    }

    //MARK: - UISearchBarDelegate
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        LocationHelper.fetchAutocompleteSuggestions(forPhrase: searchText) { [weak self] (predictions) in
            guard let strongSelf = self, let predictions = predictions else { return }
            strongSelf.presentAdressesPredictions(predictions: predictions)
        }
    }
}
