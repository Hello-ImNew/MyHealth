//
//  Account.swift
//  MyHealth
//
//  Created by Bao Bui on 6/14/24.
//

import Foundation

class Account: NSObject, NSSecureCoding {
    static var supportsSecureCoding: Bool = true
    
    let username: String
    let password: String
    
    init(username: String, password: String) {
        self.username = username
        self.password = password
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(username, forKey: "username")
        coder.encode(password, forKey: "password")
    }
    
    required init?(coder: NSCoder) {
        guard let username = coder.decodeObject(of: NSString.self, forKey: "username") as? String,
              let password = coder.decodeObject(of: NSString.self, forKey: "password") as? String else {
            return nil
        }
        
        self.username = username
        self.password = password
    }
    

}
