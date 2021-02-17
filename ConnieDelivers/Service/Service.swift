//
//  Service.swift
//  ConnieDelivers
//
//  Created by M. Ochoa on 2/3/21.
//

import Firebase
import CoreLocation
import GeoFire

// MARK: - DatabaseRefs

let DB_REF = Database.database().reference()
let REF_USERS = DB_REF.child("users")
let REF_DRIVER_LOCATIONS = DB_REF.child("driver-locations")
let REF_TRIPS = DB_REF.child("trips")

// MARK: - StoreService

struct DriverService {
    static let shared = DriverService()
    
    // "listen" for when child get added to db to notify store and change UI
    func observeTrips(completion: @escaping(Trip) -> Void) {
        REF_TRIPS.observe(.childAdded) { (snapshot) in
            guard let dictionary = snapshot.value as? [String: Any] else { return }
            let uid = snapshot.key
            let trip = Trip(passengerUid: uid, dictionary: dictionary)
            completion(trip)
        }
    }
    
    func observeTripCancelled(trip: Trip, completion: @escaping() -> Void) {
        REF_TRIPS.child(trip.passengerUid).observeSingleEvent(of: .childRemoved) { _ in
            completion()
        }
    }
    func acceptTrip(trip: Trip, completion: @escaping(Error?, DatabaseReference) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        // using enum helps us easily recall integer value and change state of trip
        let values = ["driverUid": uid,
                      "state": TripState.accepted.rawValue] as [String : Any]
        REF_TRIPS.child(trip.passengerUid).updateChildValues(values, withCompletionBlock: completion)
    }
    func updateTripState(trip: Trip, state: TripState,
                         completion: @escaping(Error?, DatabaseReference) -> Void) {
        REF_TRIPS.child(trip.passengerUid).child("state").setValue(state.rawValue, withCompletionBlock: completion)
        
        if state == .completed {
            REF_TRIPS.child(trip.passengerUid).removeAllObservers()
        }
    }
    func updateDriverLocation(location: CLLocation) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let geofire = GeoFire(firebaseRef: REF_DRIVER_LOCATIONS)
        geofire.setLocation(location, forKey: uid)
    }
}

// MARK: - GuestService

struct PassengerService {
    static let shared = PassengerService()
    
    // allocate uid and location coordinates, copy into db
    func fetchDriver(location: CLLocation, completion: @escaping(User) -> Void) {
        let geofire = GeoFire(firebaseRef: REF_DRIVER_LOCATIONS)
        
        //  add listener to observe changes in db structure
        REF_DRIVER_LOCATIONS.observe(.value) { (snapshot) in
            geofire.query(at: location, withRadius: 50).observe(.keyEntered, with: { (uid, location) in
                Service.shared.fetchUserData(uid: uid, completion: { (user) in
                    
                    // mutable copy
                    var driver = user
                    driver.location = location
                    completion(driver)
                })
            })
        }
    }
    
    func uploadTrip (_ pickupCoordinates: CLLocationCoordinate2D,
        _ destinationCoordinates: CLLocationCoordinate2D,
        completion: @escaping(Error?, DatabaseReference) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        // create array around "korner store requested" coordinates
        let pickupArray = [pickupCoordinates.latitude, pickupCoordinates.longitude]
        let destinationArray = [destinationCoordinates.latitude, destinationCoordinates.longitude]
        
        let values = ["pickupCoordinates": pickupArray,
                      "destinationCoordinates": destinationArray,
                      "state": TripState.requested.rawValue] as [String : Any]
        
        REF_TRIPS.child(uid).updateChildValues(values, withCompletionBlock: completion)
    }
    func observeCurrentTrip(completion: @escaping(Trip) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        REF_TRIPS.child(uid).observe(.value) { (snapshot) in
            guard let dictionary = snapshot.value as? [String: Any] else { return }
            let uid = snapshot.key
            let trip = Trip(passengerUid: uid, dictionary: dictionary)
            completion(trip)
        }
    }
    func deleteTrip(completion: @escaping(Error?, DatabaseReference) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        // deleting data from db upon cancel
        REF_TRIPS.child(uid).removeValue(completionBlock: completion)
    }
}

// MARK: - SharedService

struct Service {
    
    static let shared = Service()
 
    // allocate email and name, copy into db
    func fetchUserData(uid: String, completion: @escaping(User) -> Void) {
        REF_USERS.child(uid).observeSingleEvent(of: .value) { (snapshot) in
            guard let dictionary = snapshot.value as? [String: Any] else { return }
            let uid = snapshot.key
            let user = User(uid: uid, dictionary: dictionary)
            completion(user)
        }
    }
}

