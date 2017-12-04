//
//  AvailableParkingLocation.swift
//  JobInterviewHW2.0
//
//  Created by Perry on 04/12/2017.
//  Copyright © 2017 perrchick. All rights reserved.
//

import Foundation
import CoreLocation

class AvailableParkingLocation {
    var location: CLLocationCoordinate2D
    let timestamp: Int64
    
    init(location: CLLocationCoordinate2D, timestamp: Int64) {
        self.location = location
        self.timestamp = timestamp
    }
    
    var isExpired: Bool {
        return availabilityInMinutes > Configurations.shared.maximumParkLifeInMinutes
    }
    
    var availabilityInMinutes: Int {
        return Int((TimeInterval(timestamp) / 1000) - Date().timeIntervalSince1970) / 60
    }
}
