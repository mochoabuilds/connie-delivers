//
//  User.swift
//  ConnieDelivers
//
//  Created by M. Ochoa on 2/3/21.
//

// Creating Custom User Object

struct User {
    let fullname: String
    let email: String
    let accountType: Int
    
    init(dictionary: [String: Any]) {
        self.fullname = dictionary["fullname"] as? String ?? ""
        self.email = dictionary["email"] as? String ?? ""
        self.accountType = dictionary["accountType"] as? Int ?? 0
    }
}
