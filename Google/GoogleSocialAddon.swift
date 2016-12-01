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

public class GoogleSocialAddon: NSObject, DeeplinkingAddon, SocialProvider, GIDSignInDelegate {
    
    public var addonName: String = "GoogleSocialAddon"
    
    public func setup(haloCore core: CoreManager, completionHandler handler: ((Addon, Bool) -> Void)?) {
        handler?(self, true)
    }
    
    public func startup(haloCore core: CoreManager, completionHandler handler: ((Addon, Bool) -> Void)?) {
        
        if FIRApp.defaultApp() == nil {
            FIRApp.configure()
        }
        
        GIDSignIn.sharedInstance().clientID = FIRApp.defaultApp()?.options.clientID
        GIDSignIn.sharedInstance().delegate = self
        
        LogMessage(message: "Configured GoogleSignIn with clientId: \(GIDSignIn.sharedInstance().clientID)", level: .info).print()
        
        handler?(self, true)
    }
    
    public func willRegisterAddon(haloCore core: CoreManager) {
        
    }
    
    public func didRegisterAddon(haloCore core: CoreManager) {
        
    }
    
    public func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        return GIDSignIn.sharedInstance().handle(url, sourceApplication: sourceApplication, annotation: annotation)
    }
    
    public func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any]) -> Bool {
        if #available(iOS 9.0, *) {
            return GIDSignIn.sharedInstance().handle(url, sourceApplication:options[UIApplicationOpenURLOptionsKey.sourceApplication] as? String, annotation: [:])
        } else {
            return GIDSignIn.sharedInstance().handle(url, sourceApplication:Bundle.main.bundleIdentifier, annotation: [:])
        }
    }
    
    // MARK: GIDSignInDelegate
    
    public func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        
        if let idToken = user.authentication?.accessToken {
            // Submit the token to the server
            print("Google token: \(idToken)")
        }
    }
    
    public func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
        // Remove from keychain if stored?
    }

    // MARK: SocialProvider
    
    public func authenticate(authProfile: AuthProfile, completionHandler handler: (User?, NSError?) -> Void) {
        
    }
    
}

public extension SocialManager {
    
    private var googleSocialAddon: GoogleSocialAddon? {
        return Manager.core.addons.filter { $0 is GoogleSocialAddon }.first as? GoogleSocialAddon
    }
    
    func loginWithGoogle(uiDelegate: GIDSignInUIDelegate? = nil) {
        
        if let delegate = uiDelegate {
            GIDSignIn.sharedInstance().uiDelegate = delegate
        }
        
        GIDSignIn.sharedInstance().signIn()
    }
    
}
