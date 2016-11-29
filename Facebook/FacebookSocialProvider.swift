//
//  FacebookSocialProvider.swift
//  HaloSocial
//
//  Created by Borja Santos-Díez on 17/11/16.
//  Copyright © 2016 Mobgen Technology. All rights reserved.
//

import Foundation
import HaloSocial

class FacebookSocialProvider: SocialProvider {
 
    public func authenticate(authProfile: AuthProfile, completionHandler handler: (User?, NSError?) -> Void) {
        
    }
    
}

extension SocialManager {
    
    static let facebookProvider: FacebookSocialProvider = {
        return FacebookSocialProvider()
    }()
    
    public func loginWithFacebook() {
        
    }
    
}
