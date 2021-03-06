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
    static func parse(dataSnapshot: DataSnapshot) -> DataSnapshotConvertalbe?
}

struct FirebaseHelper {
    private(set) static var isConfigured: Bool = false

    struct Keys {
        static let Parkings = "Parkings"
        static let Users = "Users"
        static let Indexed = "Indexed"
        static let Locations = "Locations"
        static let Latitude = "latitude"
        static let Longitude = "longitude"
    }

    static let FORBIDDEN_CHARACTERS: String = ".$#[]"

    static let MAIN_PATH: DatabaseReference = Database.database().reference()
    static let MAIN_INDEXED_PATH: DatabaseReference = MAIN_PATH.child(Keys.Indexed)
    static let MAIN_USERS_PATH: DatabaseReference = MAIN_PATH.child(Keys.Users)
    static let INDEXED_USERS_PATH: DatabaseReference = MAIN_INDEXED_PATH.child(Keys.Users)
    static let INDEXED_LOCATIONS_PATH: DatabaseReference = MAIN_INDEXED_PATH.child(Keys.Locations)

    static private var currentObservedReference: DatabaseReference?
    static private(set) var currentNicknameOnFirebase: String?
    static private(set)var currentLocationOnFirebase: CLLocationCoordinate2D?

    static func configureFirebase() {
        if let firebaseOptions = UtilsObjC.firebaseEnvironmentOptions() {
            FirebaseApp.configure(options: firebaseOptions)
        }

        isConfigured = true
        
        Auth.auth().signInAnonymously() { (user, error) in
            if let user = user {
                📗("Logged in, user: \(user)")
            }
        }
        
        Configurations.shared.fetchRemoteConfig()
    }

    static func indexParking(_ timestamp: Int64, withLocationLatitude latitude: Double, withLocationLongitude longitude: Double, completionCallback: @escaping CompletionClosure<(databasReferences: [DatabaseReference], error: Error?)>) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let latitudeString: String = String(latitude)
        let longitudeString: String = String(longitude)

        let indexLatitudePath: DatabaseReference = createIndexedPath(root: INDEXED_LOCATIONS_PATH.child(Keys.Parkings).child(Keys.Latitude), lowercasedPrefix: latitudeString.replacedDotsWithTilde().lowercased())
        let indexLongitudePath: DatabaseReference = createIndexedPath(root: INDEXED_LOCATIONS_PATH.child(Keys.Parkings).child(Keys.Longitude), lowercasedPrefix: longitudeString.replacedDotsWithTilde().lowercased())

        let locationString: String = "\(latitude),\(longitude)"
        let nodeValue: [String : Any] = ["location": locationString, "timestamp": timestamp]
        indexLatitudePath.child(uid).setValue(nodeValue) { (error, databaseReference) in
            if let error = error {
                completionCallback((databasReferences: [indexLatitudePath, indexLongitudePath], error: error))
            } else {
                indexLongitudePath.child(uid).setValue(nodeValue) { (error, databaseReference) in
                    completionCallback((databasReferences: [indexLatitudePath, indexLongitudePath], error: error))
                }
            }
        }
    }

    // Using generic subscripts, inspiration: https://medium.com/developermind/generics-in-swift-4-4f802cd6f53c
    static func observeParkingLocations<T: DataSnapshotConvertalbe>(overlappingCoordinates: CLLocationCoordinate2D, onUpdate: @escaping CompletionClosure<[T]>) -> [DatabaseReference] {
        
        let latitudeString: String = String(overlappingCoordinates.latitude)
        let longitudeString: String = String(overlappingCoordinates.longitude)
        
        let indexLatitudePath: DatabaseReference = createIndexedPath(root: INDEXED_LOCATIONS_PATH.child(Keys.Parkings).child(Keys.Latitude), lowercasedPrefix: latitudeString.replacedDotsWithTilde().lowercased())
        let indexLongitudePath: DatabaseReference = createIndexedPath(root: INDEXED_LOCATIONS_PATH.child(Keys.Parkings).child(Keys.Longitude), lowercasedPrefix: longitudeString.replacedDotsWithTilde().lowercased())

        if let latitudeReference = observeNode(databaseReference: indexLatitudePath, onUpdate: onUpdate),
            let longitudeReference = observeNode(databaseReference: indexLongitudePath, onUpdate: onUpdate) {
            return [latitudeReference, longitudeReference]
        } else {
            📕("Failed to observe parking location nodes")
            return []
        }
    }
    
    static func observePeopleLocations<T: DataSnapshotConvertalbe>(overlappingCoordinates: CLLocationCoordinate2D, onUpdate: @escaping CompletionClosure<[T]>) -> [DatabaseReference] {

        let latitudeString: String = String(Int(overlappingCoordinates.latitude))
        let longitudeString: String = String(Int(overlappingCoordinates.longitude))

        let indexLatitudePath: DatabaseReference = createIndexedPath(root: INDEXED_LOCATIONS_PATH.child(Keys.Users).child(Keys.Latitude), lowercasedPrefix: latitudeString.replacedDotsWithTilde().lowercased())
        let indexLongitudePath: DatabaseReference = createIndexedPath(root: INDEXED_LOCATIONS_PATH.child(Keys.Users).child(Keys.Longitude), lowercasedPrefix: longitudeString.replacedDotsWithTilde().lowercased())

        if let latitudeReference = observeNode(databaseReference: indexLatitudePath, onUpdate: onUpdate),
            let longitudeReference = observeNode(databaseReference: indexLongitudePath, onUpdate: onUpdate) {
            return [latitudeReference, longitudeReference]
        } else {
            📕("Failed to observe parking location nodes")
            return []
        }
    }

    private static func observeNode<T: DataSnapshotConvertalbe>(databaseReference: DatabaseReference, onUpdate: @escaping CompletionClosure<[T]>) -> DatabaseReference? {
        currentObservedReference?.removeAllObservers()
        currentObservedReference = databaseReference
        currentObservedReference?.observe(.value, with: { (dataSnapshot) in
            onUpdate(parseDataArray(fromDataSnapshot: dataSnapshot))
            if let parsed: T = T.parse(dataSnapshot: dataSnapshot) as? T {
                onUpdate([parsed])
            } else {
                onUpdate([])
            }
        })

        return currentObservedReference
    }

    static func removeNode(databaseReference: DatabaseReference) {
        databaseReference.removeValue()
    }
    static func removeCurrentLocationSharing() {
        if let currentNickname = currentNicknameOnFirebase {
            removeNode(databaseReference: MAIN_USERS_PATH.child(currentNickname))
            removeNode(databaseReference: createIndexedPath(root: INDEXED_USERS_PATH, lowercasedPrefix: currentNickname.lowercased()))
        }

        if let currentLocation = currentLocationOnFirebase {
            removeNode(databaseReference: createIndexedPath(root: INDEXED_LOCATIONS_PATH.child(Keys.Users).child(Keys.Latitude), lowercasedPrefix: String(currentLocation.latitude).replacedDotsWithTilde().lowercased()))
            removeNode(databaseReference: createIndexedPath(root: INDEXED_LOCATIONS_PATH.child(Keys.Users).child(Keys.Longitude), lowercasedPrefix: String(currentLocation.longitude).replacedDotsWithTilde().lowercased()))
        }
    }

    static func shareLocation(nickname rawNickname: String, withLocation locationCoordinate: CLLocationCoordinate2D, completionCallback: @escaping CompletionClosure<Error?>) {
        removeCurrentLocationSharing()

        var nickname: String = rawNickname
        for s in FORBIDDEN_CHARACTERS {
            nickname = rawNickname.replacingOccurrences(of: String(s), with: "")
        }
        currentNicknameOnFirebase = nickname
        currentLocationOnFirebase = locationCoordinate

        MAIN_USERS_PATH.child(nickname).setValue(locationCoordinate.toString())
        MAIN_USERS_PATH.child(nickname).onDisconnectRemoveValue()
        
        indexLocationSharing(nickname, withLocationLatitude: locationCoordinate.latitude, withLocationLongitude: locationCoordinate.longitude, completionCallback: { error in
            if let error = error {
                📕(error)
                completionCallback(error)
            } else {
                indexNickname(nickname, withLocation: locationCoordinate) { error in
                    completionCallback(error)
                }
            }
        })
    }

    private static func indexLocationSharing(_ nickname: String, withLocationLatitude latitude: Double, withLocationLongitude longitude: Double, completionCallback: @escaping CompletionClosure<Error?>) {

        let latitudeString: String = String(latitude)
        let longitudeString: String = String(longitude)

        let indexLatitudePath: DatabaseReference = createIndexedPath(root: INDEXED_LOCATIONS_PATH.child(Keys.Users).child(Keys.Latitude), lowercasedPrefix: latitudeString.replacedDotsWithTilde().lowercased())
        let indexLongitudePath: DatabaseReference = createIndexedPath(root: INDEXED_LOCATIONS_PATH.child(Keys.Users).child(Keys.Longitude), lowercasedPrefix: longitudeString.replacedDotsWithTilde().lowercased())
        
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

    private static func indexNickname(_ nickname: String, withLocation locationCoordinate: CLLocationCoordinate2D, completionCallback: @escaping CompletionClosure<Error?>) {
        let indexUsersPath: DatabaseReference = createIndexedPath(root: INDEXED_USERS_PATH, lowercasedPrefix: nickname.lowercased())
        📗("Indexing '\(nickname)' to: \(indexUsersPath)")

        let nodeValue: [String : Any] = ["location": locationCoordinate.toString(), "nickname": nickname]
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

    static func queryIndexedData<T: DataSnapshotConvertalbe>(startsWith prefix: String, callback:@escaping CompletionClosure<(originalQuery: String, results: [T])>) {
        guard prefix.count > 0 else { callback((originalQuery: prefix, results: [])); return }

        let indexUsersPath: DatabaseReference = createIndexedPath(root: INDEXED_USERS_PATH, lowercasedPrefix: prefix.lowercased())
        
        indexUsersPath.observeSingleEvent(of: DataEventType.value) { (dataSnapshot) in
            callback((originalQuery: prefix, results: parseDataArray(fromDataSnapshot: dataSnapshot)))
        }
    }

    static func parseDataArray<T: DataSnapshotConvertalbe>(fromDataSnapshot dataSnapshot: DataSnapshot) -> [T] {
        guard dataSnapshot.childrenCount > 0 else { return [] }
        return parseAndConcatDataArray(fromDataSnapshot: dataSnapshot)
    }
    
    private static func parseAndConcatDataArray<T: DataSnapshotConvertalbe>(fromDataSnapshot child: DataSnapshot) -> [T] {
        var parsed: [T] = []

        let iterator = child.children
        while let node = iterator.nextObject() as? DataSnapshot {
            if let converted: T = T.parse(dataSnapshot: node) as? T {
                📗("parsed this to a DataSnapshotConvertalbe instance: \(converted)") // PersonSharedLocation
                parsed.append(converted)
            } else {
                parsed.append(contentsOf: parseAndConcatDataArray(fromDataSnapshot: node))
            }
        }

        return parsed
    }
}

extension String {
    /// A helper method to prevent using forbidden characters (., $, #, [, ], /, or ASCII...) when updating firebase: https://firebase.google.com/docs/database/android/structure-data#how_data_is_structured_its_a_json_tree
    func replacedDotsWithTilde() -> String {
        return self.replacingOccurrences(of: ".", with: "~")
    }

    /// A helper method to prevent using forbidden characters (., $, #, [, ], /, or ASCII...) when updating firebase: https://firebase.google.com/docs/database/android/structure-data#how_data_is_structured_its_a_json_tree
    func replacedTildeWithDots() -> String {
        return self.replacingOccurrences(of: "~", with: ".")
    }
}

extension AvailableParkingLocation: DataSnapshotConvertalbe {
    static func parse(dataSnapshot: DataSnapshot) -> DataSnapshotConvertalbe? {
        guard let jsonDictionary = dataSnapshot.value as? RawJsonFormat,
            let location = jsonDictionary["location"] as? String,
            let coordinate = CLLocationCoordinate2D(string: location),
            let timestamp: Int64 = jsonDictionary["timestamp"] as? Int64 else { return nil }

        // Logic check:
        let numOfSecondsInMinutes: Int64 = 60
        let seconds = (Date().timestampMillis - timestamp) / 1000
        let age = (seconds / numOfSecondsInMinutes)
        let isExpired: Bool = age > Configurations.shared.maximumParkLifeInMinutes
        
        let allowedParkingSpotForPOC = CLLocationCoordinate2D(latitude: 32.109203, longitude: 34.839056)
        if (isExpired && coordinate != allowedParkingSpotForPOC) {
            FirebaseHelper.removeNode(databaseReference: dataSnapshot.ref)
            return nil
        }
        
        return AvailableParkingLocation(location: coordinate, timestamp: timestamp)
    }
}

extension PersonSharedLocation: DataSnapshotConvertalbe {
    static func parse(dataSnapshot: DataSnapshot) -> DataSnapshotConvertalbe? {
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
        guard let latitude = Double(lat),
            let longitude = Double(lng) else { return nil }
        // Yes, I used 'guard' in a middle of a function, it's a matter of tase, I could use the 'if let' statement
        
        self.init(latitude: latitude, longitude: longitude)
    }
}
