//
//  Configurations.swift
//  SomeApp
//
//  Created by Perry on 2/13/16.
//  Copyright © 2016 PerrchicK. All rights reserved.
//

import Foundation

class Configurations {
    static let shared = Configurations()
    let projectLocationInsideGitHub = "https://github.com/PerrchicK"

    struct Keys {
        static let NoNoAnimation: String                = "noAnimation" // not using inferred on purpose, to help Swift compiler
        struct Persistency {
            static let PermissionRequestCounter: String = "PermissionRequestCounter"
            static let LastCrash: String                = "last crash"
        }
    }

    let GoogleMapsWebApiKey: String
    let GoogleMapsMobileSdkApiKey: String
    
    init() {
        guard let secretConstantsPlistFilePath: String = Bundle.main.path(forResource: "SecretConstants", ofType: "plist"),
        let config: [String: String] = NSDictionary(contentsOfFile: secretConstantsPlistFilePath) as? [String : String],
        let googleMapsWebApiKey = config["GoogleMapsWebApiKey"],
        let googleMapsMobileSdkApiKey = config["GoogleMapsMobileSdkApiKey"]
        else { fatalError("No way! The app must have this plist file with the mandatory keys") }

        GoogleMapsWebApiKey = googleMapsWebApiKey
        GoogleMapsMobileSdkApiKey = googleMapsMobileSdkApiKey
    }
}

//typealias MenuOption = (String,String)

public struct LeftMenuOptions {
    public struct Application {
        public static let title = "iHereU"
        
        public static let Announcements = "Announcements"
        public static let WhereIsHere = "Where am I?"
        public static let WhereIsMapCenter = "What address is the map showing?"
        public static let RenameNickname = "Change nickname"
    }
    public struct About {
        public static let title: (title: String, symbol: String) = ("About", "")
        
        public static let AboutApp = "About the app"
        public static let AboutDeveloper = "About the developer"
    }
}
