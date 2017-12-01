//
//  LocationHelper.swift
//  JobInterviewHW2.0
//
//  Created by Perry on 01/12/2017.
//  Copyright © 2017 perrchick. All rights reserved.
//

import Foundation
import CoreLocation

protocol LocationHelperDelegate: class {
    func onLocationUpdated(updatedLocation: CLLocation)
}

class LocationHelper: NSObject, CLLocationManagerDelegate {
    static let shared: LocationHelper = LocationHelper()

    weak var delegate: LocationHelperDelegate?
    var currentLocation: CLLocation?
    lazy var locationManager: CLLocationManager = {
        let locationManager: CLLocationManager = CLLocationManager();
        locationManager.delegate = self
        return locationManager
    }()

    override init() {
        super.init()

        locationManager.distanceFilter = kCLDistanceFilterNone
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            currentLocation = location
            delegate?.onLocationUpdated(updatedLocation: location)
        }
    }

    var isPermissionGranted: Bool {
        return CLLocationManager.authorizationStatus() == .authorizedWhenInUse
    }

    func findAddressByCoordinates(latitude lat: Double, longitude lng: Double, completion: @escaping CompletionClosure<String>) {
        // Make request
        let urlString = String(format: "https://maps.googleapis.com/maps/api/geocode/json?latlng=%f,%f&key=%@", lat, lng ,Configurations.shared.GoogleMapsUrlApiKey)
        Communicator.request(urlString: urlString, completion: { response in
            var result: String?
            guard let response = response else { return }
            switch response {
            case .succeeded(let json):
                // Request succeeded! ... parse response
                result = LocationHelper.parseGeocodeResponse(json)
            case .failed(let message):
                📕("request failed, message: \(message)")
            }

            completion(result)
        })
    }

    func requestPermissionsIfNeeded() {
        let counterKey: String = Configurations.Keys.Persistency.PermissionRequestCounter;
        let permissionRequestCounter: Int = UserDefaults.load(key: counterKey, defaultValue: 0)
        if permissionRequestCounter > 0 {
            if let settingsUrl = URL(string: UIApplicationOpenSettingsURLString) {
                if UIApplication.shared.canOpenURL(settingsUrl) {
                    if #available(iOS 10.0, *) {
                        UIApplication.shared.open(settingsUrl, completionHandler: nil)
                    } else {
                        // Fallback on earlier versions
                        UIApplication.shared.openURL(settingsUrl)
                    }
                }
            }
        } else {
            // First time for this life time
            locationManager.requestWhenInUseAuthorization()
            UserDefaults.save(value: permissionRequestCounter + 1, forKey: Configurations.Keys.Persistency.PermissionRequestCounter).synchronize()
        }
    }

    private static func parseGeocodeResponse(_ responseObject: Any) -> String? {
        var result: String?
        
        guard let responseDictionary = responseObject as? [AnyHashable:Any],
            let status = responseDictionary["status"] as? String, status == "OK" else { return result }
        
        📗("Parsing JSON dictionary:\n\(responseDictionary)")
        if let results = responseDictionary["results"] as? [AnyObject],
            let firstPlace = results[0] as? [String:AnyObject],
            let firstPlaceName = firstPlace["formatted_address"] as? String {
            result = firstPlaceName
        }
        
        return result
    }
}
