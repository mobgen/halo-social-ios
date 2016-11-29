//
//  GoogleSocialProvider.swift
//  HaloSocial
//
//  Created by Borja Santos-Díez on 17/11/16.
//  Copyright © 2016 Mobgen Technology. All rights reserved.
//

import Foundation
import HaloSocial
import GoogleSignIn

class GoogleSocialProvider: NSObject, SocialProvider {
    
    public func authenticate(authProfile: AuthProfile, completionHandler handler: (User?, NSError?) -> Void) {
        
    }
    
}

extension SocialProvider {
    
    let googleProvider: GoogleSocialProvider = {
        return GoogleSocialProvider()
    }()
 
    public func loginWithGoogle() {
    
    }
    
}
