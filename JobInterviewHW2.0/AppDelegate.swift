/*
 Cool features:
 - iLeave - a behaviour that let's you open a navigation app on the hosting device (Waze / Google Maps) + let "everyone" know that a parking lot became available.
 - Use Firebase to sync nicknames + location
 - Implemented an in-house auto complete for nickname suggestions.
 - Throttler to throttle user input and prevent Google API "attacks"
 - Import an ObjC code to Swift, for recognizing debug / release.
 - Used the cool Response enum that Ron showed me during the interview
 - A function pointer for quick behaviour change

 Using of course the mandatory features to pass this challenge:
 - Reverse geocoding (from coordinate to address)
 - Auto complete for addresses search
 - Usin Google Places web API.
 - User's current location and address
 */


//
//  AppDelegate.swift
//  JobInterviewHW2.0
//
//  Created by Perry on 30/11/2017.
//  Copyright © 2017 perrchick. All rights reserved.
//

import UIKit
import GoogleMaps

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

        GMSServices.provideAPIKey(Configurations.shared.GoogleMapsMobileSdkApiKey)

        try? Reachability.shared?.startNotifier()
        FirebaseHelper.configureFirebase()

        NSSetUncaughtExceptionHandler { (exception) in
            let stack = exception.callStackSymbols
            UserDefaults.save(value: stack, forKey: Configurations.Keys.Persistency.LastCrash).synchronize()
        }

        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

