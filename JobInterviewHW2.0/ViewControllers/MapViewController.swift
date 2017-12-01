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

class MapViewController: IHUViewController, GMSMapViewDelegate, UISearchBarDelegate {
    //, PlaceInfoViewControllerDelegate, UIActionSheetDelegate {
    
    override var shouldForceLocationPermissions: Bool {
        return true
    }
    private var currentZoom: Float?
    @IBOutlet weak var mapView: GMSMapView!

    override func viewDidLoad() {
        super.viewDidLoad()

        mapView.delegate = self;
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if let lastCrashCallStack: [String] = UserDefaults.load(key: Configurations.Keys.Persistency.PermissionRequestCounter) as [String]? {
            UIAlertController.makeAlert(title: Configurations.Keys.Persistency.PermissionRequestCounter, message: "\(lastCrashCallStack)")
                .withAction(UIAlertAction(title: "fine", style: .cancel, handler: nil))
                .withAction(UIAlertAction(title: "delete", style: .default, handler: { (alertAction) in
                    UserDefaults.remove(key: Configurations.Keys.Persistency.PermissionRequestCounter).synchronize()
                }))
                .show()
        }

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
    
    func mapView(_ mapView: GMSMapView, didChange position: GMSCameraPosition) {
        currentZoom = position.zoom
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
    }

    func moveCameraToLocation(coordinate: CLLocationCoordinate2D, andZoom zoomValue: Float? = nil) {
        if let zoomValue = zoomValue {
            mapView.animate(toZoom: zoomValue)
        }// else if let currentZoom = currentZoom {
//            mapView.animate(toZoom: zoomValue)
//        }
        
        mapView.animate(toLocation: coordinate)
    }

}
