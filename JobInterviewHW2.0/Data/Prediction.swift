//
//  Prediction.swift
//  JobInterviewHW2.0
//
//  Created by Perry on 02/12/2017.
//  Copyright © 2017 perrchick. All rights reserved.
//

import Foundation

class Prediction: CustomStringConvertible {
    struct InterpretationKeys {
        static let Description: String = "description"
        static let Icon: String = "icon"
        static let PlaceId: String = "place_id"
        static let Name: String = "name"
    }
    let predictionDescription: String
    let placeId: String

    init(placeId: String, predictionDescription: String) {
        self.placeId = placeId
        self.predictionDescription = predictionDescription
    }
    
    var description: String {
        return predictionDescription
    }
}
