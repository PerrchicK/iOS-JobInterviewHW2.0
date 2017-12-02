//
//  Place.swift
//  JobInterviewHW2.0
//
//  Created by Perry on 02/12/2017.
//  Copyright © 2017 perrchick. All rights reserved.
//

import Foundation

class Place: CustomStringConvertible {
    let longitude: Double
    let latitude: Double
    let iconUrl: String
    let placeName: String
    let placeId: String
    
    init(longitude: Double, latitude: Double, iconUrl: String, placeName: String, placeId: String) {
        self.placeId = placeId
        self.longitude = longitude
        self.latitude = latitude
        self.iconUrl = iconUrl
        self.placeName = placeName
    }

    var description: String {
        return placeName
    }
}
