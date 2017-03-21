//
//  GoogleSocialAddon.swift
//  HaloSocial
//
//  Created by Borja Santos-Díez on 30/11/16.
//  Copyright © 2016 Mobgen Technology. All rights reserved.
//

import Foundation
import Halo
import GoogleSignIn
import Firebase

open class GoogleSocialAddon: NSObject, DeeplinkingAddon, AuthProvider, GIDSignInDelegate {
    
    public var addonName: String = "GoogleSocialAddon"
    var completionHandler: (User?, HaloError?) -> Void = { _, _ in }
    
    public func setup(haloCore core: CoreManager, completionHandler handler: ((Addon, Bool) -> Void)?) {
        handler?(self, true)
    }
    
    open func startup(haloCore core: CoreManager, completionHandler handler: ((Addon, Bool) -> Void)?) {
        
        if FIRApp.defaultApp() == nil {
            FIRApp.configure()
        }
        
        GIDSignIn.sharedInstance().clientID = FIRApp.defaultApp()?.options.clientID
        GIDSignIn.sharedInstance().delegate = self
        
        Halo.Manager.core.logMessage("Configured GoogleSignIn with clientId: \(GIDSignIn.sharedInstance().clientID)", level: .info)
        
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
        if error != nil {
            handleLoginResult(idToken: nil, error: error, completionHandler: self.completionHandler)
        } else {
            handleLoginResult(idToken: user.authentication.idToken, error: error, completionHandler: self.completionHandler)
        }
    }
    
    public func handleLoginResult(idToken: String?, error: Error!, completionHandler handler: @escaping ((User?, HaloError?) -> Void)) {
        
        guard
            error == nil
        else {
            Halo.Manager.core.logMessage(error.localizedDescription, level: .error)
            handler(nil, .loginError(error.localizedDescription))
            return
        }
        
        guard
            let idToken = idToken
        else {
            let message = "No token could be obtained from Google"
            Halo.Manager.core.logMessage(message, level: .error)
            handler(nil, .loginError(message))
            return
        }
        
        guard
            let deviceAlias = Manager.core.device?.alias
        else {
            let message = "No device alias could be obtained"
            Halo.Manager.core.logMessage(message, level: .error)
            handler(nil, .loginError(message))
            return
        }
        
        Halo.Manager.core.logMessage("Google token: \(idToken)", level: .info)
     
        let profile = AuthProfile(token: idToken, network: .google, deviceId: deviceAlias)
        authenticate(authProfile: profile) { (user, error) in
            if error != nil {
                GIDSignIn.sharedInstance().signOut()
            }
            handler(user, error)
        }
    }
    
    public func logout() {
        GIDSignIn.sharedInstance().signOut()
    }
    
}

public extension AuthManager {
    
    private var googleSocialAddon: GoogleSocialAddon? {
        return Manager.core.addons.filter { $0 is GoogleSocialAddon }.first as? GoogleSocialAddon
    }
    
    /**
     Call this method to start the login with Google.
     
     - parameter uiDelegate:    GIDSignInUIDelegate is used to dispatch when the
                                sign-in flow will display a the login viewController
                                , dismiss it or will dispatch it.
     - parameter completionHandler: Closure to be called after completion
     */
    //@objc(loginWithGoogleWithUIDelegate:stayLoggedIn:completionHandler:)
    func loginWithGoogle(uiDelegate: GIDSignInUIDelegate, stayLoggedIn: Bool = Manager.auth.stayLoggedIn, completionHandler handler: @escaping (User?, HaloError?) -> Void) {
        guard
            let googleSocialAddon = self.googleSocialAddon
        else {
            let message = "No GoogleSocialAddon has been configured and registered."
            Halo.Manager.core.logMessage(message, level: .error)
            handler(nil, .loginError(message))
            return
        }
        
        Manager.auth.stayLoggedIn = stayLoggedIn        
        googleSocialAddon.completionHandler = handler
        
        GIDSignIn.sharedInstance().uiDelegate = uiDelegate
        GIDSignIn.sharedInstance().signIn()
    }
    
}
