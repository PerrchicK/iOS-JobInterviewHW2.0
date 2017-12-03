//
//  FirebaseHelper.swift
//  JobInterviewHW2.0
//
//  Created by Perry on 01/12/2017.
//  Copyright © 2017 perrchick. All rights reserved.
//

import Foundation
import Firebase
import FirebaseAuth

class FirebaseHelper {
    private(set) static var isConfigured: Bool = false

    static func configureFirebase() {
        if let firebaseOptions = UtilsObjC.firebaseEnvironmentOptions() {
            FirebaseApp.configure(options: firebaseOptions)
        }

//        observeConnectionState()

//        PATH_TO_USER_ONLINE_STATE()?.onDisconnectSetValue(false)
        isConfigured = true
        
        Auth.auth().signInAnonymously() { (user, error) in
            📗("Logged in, user: \(user)")
        }
    }
}
