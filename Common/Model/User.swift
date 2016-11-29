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
    
    var userProfile: UserProfile
    var token: Token
    
    public override var debugDescription: String {
        return "[User] Email: \(userProfile.email)"
    }
    
    init(profile: UserProfile, token: Token) {
        self.userProfile = profile
        self.token = token
        super.init()
    }
    
}
