//
//  User.swift
//  HaloSocial
//
//  Created by Borja Santos-Díez on 17/11/16.
//  Copyright © 2016 Mobgen Technology. All rights reserved.
//

import Foundation
import Halo

@objc(HaloUser)
public class User: NSObject {
    
    struct Keys {
        static let Token = "token"
        static let UserProfile = "user"
    }
    
    var userProfile: UserProfile
    internal (set) public var token: Token
    
    public override var debugDescription: String {
        return "[User] Email: \(userProfile.email)"
    }
    
    init(profile: UserProfile, token: Token) {
        self.userProfile = profile
        self.token = token
        super.init()
    }
    
    public class func fromDictionary(_ dict: [String: Any]) -> User? {
        var t: Token
        if let tokenDict = dict[Keys.Token] as? [String: Any] {
            t = Token.fromDictionary(tokenDict)
        } else {
            return nil
        }
        
        var up: UserProfile
        if let userProfileDict = dict[Keys.UserProfile] as? [String: Any] {
            up = UserProfile.fromDictionary(userProfileDict)
        } else {
            return nil
        }
        
        return User(profile: up, token: t)
    }
    
}
