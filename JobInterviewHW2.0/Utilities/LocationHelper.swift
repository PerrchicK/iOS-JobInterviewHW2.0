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
    typealias RawJsonFormat = [AnyHashable:Any]
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
    }
    
    func stopUpdate() {
        locationManager.stopUpdatingLocation()
    }

    func startUpdate() {
        guard isPermissionGranted else { return }
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
        let urlString = String(format: Communicator.API.Request.GeocodeFormat,
                               lat,
                               lng,
                               Configurations.shared.GoogleMapsWebApiKey)

        Communicator.request(urlString: urlString, completion: { response in
            var result: String?
            guard let response = response else {
                completion(result)
                return
            }

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

    static func fetchAutocompleteSuggestions(forPhrase keyword: String, predictionsResultCallback: @escaping CompletionClosure<(keyword: String, predictions: [Prediction])>) {
        let urlString = String(format: Communicator.API.Request.AutocompletePlacesFormat,
                               keyword,
                               Configurations.shared.GoogleMapsWebApiKey)

        Communicator.request(urlString: urlString) { (response) in
            var predictionsResult: [Prediction] = [Prediction]()
            guard let response = response else { predictionsResultCallback((keyword: keyword, predictions: predictionsResult)); return }
            
            switch response {
            case .succeeded(let json):
                if let jsonDictionary = (json as? RawJsonFormat),
                    let jsonArray = jsonDictionary[Communicator.API.Response.GoogleMapsPredictions] as? [RawJsonFormat] {
                    for predictionJsonDictionary in jsonArray {
                        guard let description = predictionJsonDictionary[Prediction.InterpretationKeys.Description] as? String,
                            let placeId = predictionJsonDictionary[Prediction.InterpretationKeys.PlaceId] as? String
                            else { continue }
                        let prediction = Prediction(placeId: placeId, predictionDescription: description)
                        predictionsResult.append(prediction)
                    }

//                if (jsonAsDictionary.count && [jsonAsDictionary[kGoogleMapsPredictionsKey] count]) {
//                    NSArray *predictionsArrayFromJson = jsonAsDictionary[kGoogleMapsPredictionsKey];
//                    for (NSDictionary *predictionAsDictionary in predictionsArrayFromJson) {
//                        // Validate before parsing
//                        if (predictionAsDictionary.count &&
//                            predictionAsDictionary[kGoogleMapsPredictionDescriptionKey] &&
//                            predictionAsDictionary[kGoogleMapsPlaceIdKey]) {
//                            Prediction *prediction = [Prediction new];
//                            prediction.predictionDescription = predictionAsDictionary[kGoogleMapsPredictionDescriptionKey];
//                            prediction.placeId = predictionAsDictionary[kGoogleMapsPlaceIdKey];
//                            [predictions addObject:prediction];
//                        }
//                    }
//                }
                    
                    // So glad we're developing in Swift ツ 👆

                }
            case .failed(let message):
                📕("request failed, message: \(message)")
            }
            predictionsResultCallback((keyword: keyword, predictions: predictionsResult))
        }
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
        }

        UserDefaults.save(value: permissionRequestCounter + 1, forKey: Configurations.Keys.Persistency.PermissionRequestCounter).synchronize()
    }

    private static func parseGeocodeResponse(_ responseObject: Any) -> String? {
        var result: String?
        
        guard let responseDictionary = responseObject as? [AnyHashable:Any],
            let status = responseDictionary["status"] as? String, status == "OK" else { return result }
        
        //📗("Parsing JSON dictionary:\n\(responseDictionary)")
        if let results = responseDictionary["results"] as? [AnyObject],
            let firstPlace = results[0] as? [String:AnyObject],
            let firstPlaceName = firstPlace["formatted_address"] as? String {
            result = firstPlaceName
        }
        
        return result
    }
}
