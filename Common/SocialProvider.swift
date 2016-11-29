//
//  SocialProvider.swift
//  HaloSocial
//
//  Created by Borja Santos-Díez on 17/11/16.
//  Copyright © 2016 Mobgen Technology. All rights reserved.
//

import Foundation
import Halo

@objc
public protocol SocialProvider {
    
    func authenticate(authProfile: AuthProfile, completionHandler handler: (User?, NSError?) -> Void) -> Void
    
}
