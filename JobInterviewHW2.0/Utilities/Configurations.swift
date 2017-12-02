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

    struct Constants {
        // From: http://gis.stackexchange.com/questions/7430/what-ratio-scales-do-google-maps-zoom-levels-correspond-to
        static let ClosestZoomRatioScale: Double = 591657550.50
        static let GitHubLink: String = "https://github.com/PerrchicK/iOS-JobInterviewHW2.0"
    }

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

public struct LeftMenuOptions {
    public typealias MenuOption = (text: String, symbol: String)

    public enum LeftMenuOption {
        case option(text: String, symbol: String)
    }

    public struct Application {
        public static let title: String = ("iHereU")
        
        static let Announcements: MenuOption = (text: "Announcements", symbol: "📣")
        public static let WhereIsHere: MenuOption = (text: "Where am I?", symbol: "🤔")
        public static let WhereIsMapCenter: MenuOption = (text: "Map's current address", symbol: "✛")
        public static let RenameNickname: MenuOption = (text: "Change nickname", symbol: "👽")
    }
    public struct About {
        public static let title: String = "About"
        
        public static let AboutApp: MenuOption = (text: "About the app", symbol: "📱")
        public static let AboutDeveloper: MenuOption = (text: "About the developer", symbol: "💻")
    }
}
