//
//  GoogleSocialAddon.swift
//  HaloSocial
//
//  Created by Borja Santos-Díez on 30/11/16.
//  Copyright © 2016 Mobgen Technology. All rights reserved.
//

import Foundation
import Halo
import HaloSocial
import SwiftKeychainWrapper
import GoogleSignIn
import Firebase

public class GoogleSocialAddon: DeeplinkingAddon, SocialProvider {
    
    public var addonName: String = "GoogleSocialAddon"
    
    public func setup(haloCore core: CoreManager, completionHandler handler: ((Addon, Bool) -> Void)?) {
        
    }
    
    public func startup(haloCore core: CoreManager, completionHandler handler: ((Addon, Bool) -> Void)?) {
        
        if FIRApp.defaultApp() == nil {
            FIRApp.configure()
        }
        
    }
    
    public func willRegisterAddon(haloCore core: CoreManager) {
        
    }
    
    public func didRegisterAddon(haloCore core: CoreManager) {
        
    }
    
    public func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        return false
    }
    
    public func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any]) -> Bool {
        return false
    }
    
    
    public func authenticate(authProfile: AuthProfile, completionHandler handler: (User?, NSError?) -> Void) {
        
    }
    
}

public extension SocialManager {
    
    private var googleSocialAddon: GoogleSocialAddon? {
        return Manager.core.addons.filter { $0 is GoogleSocialAddon }.first as? GoogleSocialAddon
    }
    
    func loginWithGoogle() {
        
    }
    
}
