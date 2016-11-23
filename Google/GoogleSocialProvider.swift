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

@objc(HaloGoogleSocialProvider)
class GoogleSocialProvider: NSObject, SocialProvider {
    
}

extension SocialProvider {
    
    var googleProvider: GoogleSocialProvider {
        return GoogleSocialProvider()
    }
    
}
