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
import CoreLocation

protocol DataSnapshotConvertalbe {
    static func from(dataSnapshot: DataSnapshot) -> DataSnapshotConvertalbe?
    //init?(dataSnapshot: DataSnapshot)
    //func parse(from: DataSnapshot)
}

struct FirebaseHelper {
    private(set) static var isConfigured: Bool = false

    struct Keys {
        static let Parkings = "Parkings"
        static let Users = "Users"
        static let Indexed = "Indexed"
        static let Locations = "Locations"
    }

    //Firebase database reference
    static let MAIN_PATH = Database.database().reference()
    static let MAIN_INDEXED_PATH = MAIN_PATH.child(Keys.Indexed)
    static let MAIN_USERS_PATH = MAIN_PATH.child(Keys.Users)
    static let INDEXED_USERS_PATH = MAIN_INDEXED_PATH.child(Keys.Users)
    static let INDEXED_LOCATIONS_PATH = MAIN_INDEXED_PATH.child(Keys.Locations)

    static var currentObservedReference: DatabaseReference?

    static func configureFirebase() {
        if let firebaseOptions = UtilsObjC.firebaseEnvironmentOptions() {
            FirebaseApp.configure(options: firebaseOptions)
        }

//        observeConnectionState()

//        PATH_TO_USER_ONLINE_STATE()?.onDisconnectSetValue(false)
        isConfigured = true
        
        Auth.auth().signInAnonymously() { (user, error) in
            if let user = user {
                📗("Logged in, user: \(user)")
            }
        }
        
        Configurations.shared.fetchRemoteConfig()
    }

    static func indexParking(_ timestamp: Int64, withLocationLatitude latitude: Double, withLocationLongitude longitude: Double, completionCallback: @escaping CompletionClosure<Error?>) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let latitudeString: String = String(latitude)
        let longitudeString: String = String(longitude)

        let indexLatitudePath: DatabaseReference = createIndexedPath(root: INDEXED_LOCATIONS_PATH.child(Keys.Parkings), lowercasedPrefix: latitudeString.replacedDotsWithTilde().lowercased())
        let indexLongitudePath: DatabaseReference = createIndexedPath(root: INDEXED_LOCATIONS_PATH.child(Keys.Parkings), lowercasedPrefix: longitudeString.replacedDotsWithTilde().lowercased())

        let locationString: String = "\(latitude),\(longitude)"
        let nodeValue: [String : Any] = ["location": locationString, "timestamp": timestamp]
        indexLatitudePath.child(uid).setValue(nodeValue) { (error, databaseReference) in
            if let error = error {
                completionCallback(error)
            } else {
                indexLongitudePath.child(uid).setValue(nodeValue) { (error, databaseReference) in
                    completionCallback(error)
                }
            }
        }
    }

    static func observeUsersLocations(locationPrefix: String, onUpdate: @escaping () -> ()) -> DatabaseReference? {
        return observeNode(databaseReference: INDEXED_LOCATIONS_PATH.child(Keys.Users).child(locationPrefix), onUpdate: onUpdate)
    }

    static func observeParkingLocations(locationPrefix: String, onUpdate: @escaping () -> ()) -> DatabaseReference? {
        return observeNode(databaseReference: INDEXED_LOCATIONS_PATH.child(Keys.Parkings).child(locationPrefix), onUpdate: onUpdate)
    }

    private static func observeNode(databaseReference: DatabaseReference, onUpdate: @escaping () -> ()) -> DatabaseReference? {
        currentObservedReference?.removeAllObservers()
        currentObservedReference = databaseReference
        currentObservedReference?.observe(.value, with: { (dataSnapshot) in
            📗(dataSnapshot)
        })

        return currentObservedReference
    }

    static func shareLocation(_ nickname: String, withLocationLatitude latitude: Double, withLocationLongitude longitude: Double, completionCallback: @escaping CompletionClosure<Error?>) {
        let locationString: String = "\(latitude),\(longitude)"
        MAIN_USERS_PATH.child(nickname).setValue(locationString)
        MAIN_USERS_PATH.child(nickname).onDisconnectRemoveValue()
        
        indexLocationSharing(nickname, withLocationLatitude: latitude, withLocationLongitude: longitude, completionCallback: completionCallback)
        indexNickname(nickname, withLocationLatitude: latitude, withLocationLongitude: longitude) { error in
            completionCallback(error)

            queryIndexedData(startsWith: "pe", callback: { (people: [PersonSharedLocation]) in
                📗(people)
            })
        }
    }

    private static func indexLocationSharing(_ nickname: String, withLocationLatitude latitude: Double, withLocationLongitude longitude: Double, completionCallback: @escaping CompletionClosure<Error?>) {

        let latitudeString: String = String(latitude)
        let longitudeString: String = String(longitude)

        let indexLatitudePath: DatabaseReference = createIndexedPath(root: INDEXED_LOCATIONS_PATH.child(Keys.Users), lowercasedPrefix: latitudeString.replacedDotsWithTilde().lowercased())
        let indexLongitudePath: DatabaseReference = createIndexedPath(root: INDEXED_LOCATIONS_PATH.child(Keys.Users), lowercasedPrefix: longitudeString.replacedDotsWithTilde().lowercased())
        
        let locationString: String = "\(latitude),\(longitude)"
        let nodeValue: [String : Any] = ["location": locationString, "nickname": nickname]
        indexLatitudePath.child(nickname).setValue(nodeValue) { (error, databaseReference) in
            if let error = error {
                completionCallback(error)
            } else {
                indexLongitudePath.child(nickname).setValue(nodeValue) { (error, databaseReference) in
                    completionCallback(error)
                }
                indexLongitudePath.child(nickname).onDisconnectRemoveValue()
            }
        }
        indexLatitudePath.child(nickname).onDisconnectRemoveValue()
    }

    private static func indexNickname(_ nickname: String, withLocationLatitude latitude: Double, withLocationLongitude longitude: Double, completionCallback: @escaping CompletionClosure<Error?>) {
        let indexUsersPath: DatabaseReference = createIndexedPath(root: INDEXED_USERS_PATH, lowercasedPrefix: nickname.lowercased())
        📗("Indexing '\(nickname)' to: \(indexUsersPath)")
        let locationString: String = "\(latitude),\(longitude)"
        let nodeValue: [String : Any] = ["location": locationString, "nickname": nickname]
        MAIN_USERS_PATH.child(nickname).setValue(nodeValue) { (error, databaseReference) in
            indexUsersPath.setValue(nodeValue)
            indexUsersPath.onDisconnectRemoveValue()
            completionCallback(error)
        }
        MAIN_USERS_PATH.child(nickname).onDisconnectRemoveValue()
    }
    
    private static func createIndexedPath(root: DatabaseReference, lowercasedPrefix chars: String) -> DatabaseReference {
        return concatPath(updatedReference: root, chars: chars, position: 0);
    }
    
    private static func concatPath(updatedReference: DatabaseReference, chars: String, position: Int) -> DatabaseReference {
        if chars.count == position { return updatedReference }
        return concatPath(updatedReference: updatedReference.child(String(chars[position])), chars: chars, position: position + 1);
    }

    static func queryIndexedData<T: DataSnapshotConvertalbe>(startsWith prefix: String, callback:@escaping CompletionClosure<[T]>) {
        let indexUsersPath: DatabaseReference = createIndexedPath(root: INDEXED_USERS_PATH, lowercasedPrefix: prefix.lowercased())
        
        indexUsersPath.observeSingleEvent(of: DataEventType.value) { (dataSnapshot) in
            callback(parseArray(fromDataSnapshot: dataSnapshot))
        }
    }

//    static func queryNicknames(startsWith prefix: String, callback:@escaping CompletionClosure<[String]>) {
//        let indexUsersPath: DatabaseReference = createIndexedPath(root: INDEXED_USERS_PATH, lowercasedPrefix: prefix.lowercased())
//
//        indexUsersPath.observeSingleEvent(of: DataEventType.value) { (dataSnapshot) in
//            callback(indexedNicknames(fromDataSnapshot: dataSnapshot))
//        }
//    }

    private static func parseArray<T: DataSnapshotConvertalbe>(fromDataSnapshot dataSnapshot: DataSnapshot) -> [T] {
        guard dataSnapshot.childrenCount > 0 else { return [] }
        return concatArray(child: dataSnapshot)
    }
    
    private static func concatArray<T: DataSnapshotConvertalbe>(child: DataSnapshot) -> [T] {
        var parsed: [T] = []

        let iterator = child.children
        while let node = iterator.nextObject() as? DataSnapshot {
            if let converted: T = T.from(dataSnapshot: node) as? T {
                📗("parsed this to a DataSnapshotConvertalbe instance: \(converted)") // PersonSharedLocation
                parsed.append(converted)
            } else {
                parsed.append(contentsOf: concatArray(child: node))
            }
        }

        return parsed
    }
}

extension String {
    func replacedDotsWithTilde() -> String {
        return self.replacingOccurrences(of: ".", with: "~")
    }

    func replacedTildeWithDots() -> String {
        return self.replacingOccurrences(of: "~", with: ".")
    }
}

//class IHUDatabaseReference: DatabaseReference {
//    deinit {
//        self.removeAllObservers()
//    }
//
//    override func child(_ pathString: String) -> DatabaseReference {
//        <#code#>
//    }
//}
//
//extension DatabaseReference {
//    func ihuChild(_ pathString: String) -> IHUDatabaseReference {
//        return IHUDatabaseReference()
//    }
//}

extension AvailableParkingLocation: DataSnapshotConvertalbe {
    static func from(dataSnapshot: DataSnapshot) -> DataSnapshotConvertalbe? {
        guard let jsonDictionary = dataSnapshot.value as? RawJsonFormat,
            let location = jsonDictionary["location"] as? String,
            let coordinate = CLLocationCoordinate2D(string: location),
            let timestamp = jsonDictionary["timestamp"] as? Int64 else { return nil }
        return AvailableParkingLocation(location: coordinate, timestamp: timestamp)
    }
}

extension PersonSharedLocation: DataSnapshotConvertalbe {
    static func from(dataSnapshot: DataSnapshot) -> DataSnapshotConvertalbe? {
        guard let jsonDictionary = dataSnapshot.value as? RawJsonFormat,
            let location = jsonDictionary["location"] as? String,
            let coordinate = CLLocationCoordinate2D(string: location),
            let nickname = jsonDictionary["nickname"] as? String else { return nil }
        return PersonSharedLocation(location: coordinate, nickname: nickname)
    }
}

extension CLLocationCoordinate2D {
    init?(string: String) {
        let stringComponents = string.components(separatedBy: ",")
        guard stringComponents.count == 2 else { return nil }
        let lat = stringComponents[0]
        let lng = stringComponents[1]
        guard let latitude = Double(lat) else { return nil }
        guard let longitude = Double(lng) else { return nil }
        
        self.init(latitude: latitude, longitude: longitude)
    }
}
