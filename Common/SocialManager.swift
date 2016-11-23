//
//  SocialManager.swift
//  HaloSocial
//
//  Created by Borja Santos-Díez on 18/11/16.
//  Copyright © 2016 Mobgen Technology. All rights reserved.
//

import Foundation
import Halo

@objc
public enum SocialNetwork: Int {
    case halo, facebook, google
}

@objc(HaloSocialManager)
public class SocialManager: NSObject, HaloManager {
    
    @objc(startup:)
    public func startup(completionHandler handler: ((Bool) -> Void)?) -> Void {
        
    }
    
    public func login(network: SocialNetwork, authProfile: AuthProfile?, completionHandler handler: (SocialProfile) -> Void) -> Void {
        
    }
    
    public func register(authProfile: AuthProfile, userProfile: UserProfile, completionHandler handler: (SocialProfile) -> Void) -> Void {
        
    }
    
}

extension Manager {
    
    open static let social: SocialManager = {
        return SocialManager()
    }()
    
}
