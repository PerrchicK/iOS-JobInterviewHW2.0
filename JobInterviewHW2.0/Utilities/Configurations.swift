//
//  Configurations.swift
//  SomeApp
//
//  Created by Perry on 2/13/16.
//  Copyright © 2016 PerrchicK. All rights reserved.
//

import Foundation
import FirebaseRemoteConfig

class Configurations {
    static let shared = Configurations()

    struct Constants {
        // From: http://gis.stackexchange.com/questions/7430/what-ratio-scales-do-google-maps-zoom-levels-correspond-to
        static let ClosestZoomRatioScale: Double = 591657550.50
        static let GitHubLink: String = "https://github.com/PerrchicK/iOS-JobInterviewHW2.0"
    }

    struct Keys {
        struct RemoteConfig {
            static let MaximumParkLifeInMinutes: String                = "MaximumParkLifeInMinutes"
        }
        
        static let NoNoAnimation: String                = "noAnimation" // not using inferred on purpose, to help Swift compiler
        struct Persistency {
            static let PermissionRequestCounter: String = "PermissionRequestCounter"
            static let LastCrash: String                = "last crash"
        }
    }

    let GoogleMapsWebApiKey: String
    let GoogleMapsMobileSdkApiKey: String
    private(set) var maximumParkLifeInMinutes: Int
    
    private var remoteConfig: RemoteConfig

    init() {
        remoteConfig = RemoteConfig.remoteConfig()

        maximumParkLifeInMinutes = 30

        if let remoteConfigSettings = RemoteConfigSettings(developerModeEnabled: true) {
            remoteConfig.configSettings = remoteConfigSettings
        }

        guard let secretConstantsPlistFilePath: String = Bundle.main.path(forResource: "SecretConstants", ofType: "plist"),
        let config: [String: String] = NSDictionary(contentsOfFile: secretConstantsPlistFilePath) as? [String : String],
        let googleMapsWebApiKey = config["GoogleMapsWebApiKey"],
        let googleMapsMobileSdkApiKey = config["GoogleMapsMobileSdkApiKey"]
        else { fatalError("No way! The app must have this plist file with the mandatory keys") }

        GoogleMapsWebApiKey = googleMapsWebApiKey
        GoogleMapsMobileSdkApiKey = googleMapsMobileSdkApiKey
    }
    func fetchRemoteConfig() {
        remoteConfig.fetch(withExpirationDuration: 2, completionHandler: { [weak self] (fetchStatus, error) -> () in
            if fetchStatus == .success {
                if let maximumParkLifeInMinutes = self?.remoteConfig[Keys.RemoteConfig.MaximumParkLifeInMinutes].numberValue?.intValue, maximumParkLifeInMinutes > 0 {
                    self?.maximumParkLifeInMinutes = maximumParkLifeInMinutes
                }
            } else if let error = error {
                📕("Failed to fetch remote config! Error: \(error)")
            } else {
                📕("Failed to fetch remote config! Missing error object...")
            }
        })
    }
}

public struct LeftMenuOptions {
    public typealias MenuOption = (text: String, symbol: String)

    public enum LeftMenuOption {
        case option(text: String, symbol: String)
    }

    public struct Driving {
        public static let title: String = "Driving".localized()

        public static let LeaveParking: MenuOption = (text: "iLeave", symbol: "👋")
        public static let SeekParking: MenuOption = (text: "iPark", symbol: "🚙")
    }
    public struct Location {
        public static let title: String = "Location".localized()
        
        public static let WhereIsHere: MenuOption = (text: "Where am I?".localized(), symbol: "🤔")
        public static let ShareLocation: MenuOption = (text: "Expose your location?".localized(), symbol: "📍")
        public static let WhereIsMapCenter: MenuOption = (text: "Map's current address".localized(), symbol: "✛")
    }
    public struct About {
        public static let title: String = "About".localized()
        
        static let Announcements: MenuOption = (text: "Announcements".localized(), symbol: "📣")
        public static let AboutApp: MenuOption = (text: "About the app".localized(), symbol: "📱")
        public static let AboutDeveloper: MenuOption = (text: "About the developer".localized(), symbol: "💻")
    }
}
