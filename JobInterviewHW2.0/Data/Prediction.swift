//
//  Prediction.swift
//  JobInterviewHW2.0
//
//  Created by Perry on 02/12/2017.
//  Copyright © 2017 perrchick. All rights reserved.
//

import Foundation

protocol Prediction: CustomStringConvertible {
    var predictionDescription: String { get }
    
}
class AddressPrediction: Prediction {
    struct InterpretationKeys {
        static let Description: String = "description"
        static let Icon: String = "icon"
        static let PlaceId: String = "place_id"
        static let Name: String = "name"
    }
    let addressDescription: String
    let placeId: String

    init(placeId: String, addressDescription: String) {
        self.placeId = placeId
        self.addressDescription = addressDescription
    }
    
    var predictionDescription: String {
        return addressDescription
    }
    
    var description: String {
        return predictionDescription
    }
}
