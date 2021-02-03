//
//  Service.swift
//  ConnieDelivers
//
//  Created by M. Ochoa on 2/3/21.
//

import Firebase

let DB_REF = Database.database().reference()
let REF_USERS = DB_REF.child("users")

struct Service {
    
    static let shared = Service()
    let currentUid = Auth.auth().currentUser?.uid
    
    func fetchUserData(completion: @escaping(User) -> Void) {
        REF_USERS.child(currentUid!).observeSingleEvent(of: .value) { (snapshot) in
            guard let dictionary = snapshot.value as? [String: Any] else { return }
            let user = User(dictionary: dictionary)
            
            print("FIX ME: User email is \(user.email)")
            print("FIX ME: User fullname is \(user.fullname)")
        
            completion(user)
        }
    }
}
