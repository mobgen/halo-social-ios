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
    var completionHandler: (User?, NSError?) -> Void = { _, _ in }
    
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
        
        guard
            error == nil
        else {
            LogMessage(message: error.localizedDescription, level: .error).print()
            self.completionHandler(nil, NSError(domain: "com.mobgen.halo", code: -1, userInfo: [NSLocalizedDescriptionKey: error.localizedDescription]))
            return
        }
        
        guard let idToken = user.authentication?.idToken else {
            let message = "No token could be obtained from Google"
            LogMessage(message: message, level: .error).print()
            self.completionHandler(nil, NSError(domain: "com.mobgen.halo", code: -1, userInfo: [NSLocalizedDescriptionKey: message]))
            return
        }
        
        guard let deviceAlias = Manager.core.device?.alias else {
            let message = "No device alias could be obtained"
            LogMessage(message: message, level: .error).print()
            self.completionHandler(nil, NSError(domain: "com.mobgen.halo", code: -1, userInfo: [NSLocalizedDescriptionKey: message]))
            return
        }
        
        LogMessage(message: "Google token: \(idToken)", level: .info).print()
        
        let profile = AuthProfile(token: idToken, network: .Google, deviceId: deviceAlias)
        authenticate(authProfile: profile) { (user, error) in
            if error != nil {
                signIn.signOut()
            }
            self.completionHandler(user, error)
        }
    }
    
    public func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
        // Remove from keychain if stored?
    }
    
}

public extension SocialManager {
    
    @objc(loginWithGoogleWithUIDelegate:completionHandler:)
    func loginWithGoogle(uiDelegate: GIDSignInUIDelegate, completionHandler handler: @escaping (User?, Error?) -> Void) {
        
        let google = Manager.core.addons.filter { $0 is GoogleSocialAddon }.first as? GoogleSocialAddon
        
        guard google != nil else {
            let message = "No GoogleSocialAddon has been configured and registered"
            LogMessage(message: message, level: .error).print()
            handler(nil, NSError(domain: "com.mobgen.halo", code: -1, userInfo: [NSLocalizedDescriptionKey: message]))
            return
        }
        
        google?.completionHandler = handler
        
        GIDSignIn.sharedInstance().uiDelegate = uiDelegate
        GIDSignIn.sharedInstance().signIn()
    }
    
}
