//
//  PersonSharedLocation.swift
//  JobInterviewHW2.0
//
//  Created by Perry on 04/12/2017.
//  Copyright © 2017 perrchick. All rights reserved.
//

import Foundation
import CoreLocation

class PersonSharedLocation: Prediction {
    var location: CLLocationCoordinate2D
    let nickname: String
    
    init(location: CLLocationCoordinate2D, nickname: String) {
        self.location = location
        self.nickname = nickname
    }
    
    var predictionDescription: String {
        return description
    }
    
    var description: String {
        return nickname
    }
}
