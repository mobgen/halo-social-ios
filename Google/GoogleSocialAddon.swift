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


open class GoogleSocialAddon: NSObject, HaloDeeplinkingAddon, AuthProvider, GIDSignInDelegate {

    public var googleFileName: String = "GoogleService-Info"
    public var addonName: String = "GoogleSocialAddon"
    var completionHandler: (HTTPURLResponse?, Result<Halo.User?>) -> Void = { _, _ in }
    
    public func setup(haloCore core: CoreManager, completionHandler handler: ((HaloAddon, Bool) -> Void)?) {
        handler?(self, true)
    }
    
    open func startup(haloCore core: CoreManager, completionHandler handler: ((HaloAddon, Bool) -> Void)?) {

        if let path = Bundle.main.path(forResource: googleFileName, ofType: "plist") {
            let dictRoot = NSDictionary(contentsOfFile: path)
            if let dict = dictRoot {
                GIDSignIn.sharedInstance().clientID = dict["CLIENT_ID"] as! String
                Halo.Manager.core.logMessage("Configured GoogleSignIn with clientId: \(GIDSignIn.sharedInstance().clientID)", level: .info)
            }
        }
        else {
            let e: HaloError = .loginError("No GoogleService-Info file from bundle")
            Manager.core.logMessage(e.description, level: .error)
        }

        GIDSignIn.sharedInstance().delegate = self

        handler?(self, true)
    }

    public func startup(app: UIApplication, haloCore core: CoreManager, completionHandler handler: ((HaloAddon, Bool) -> Void)?) {


        if let path = Bundle.main.path(forResource: googleFileName, ofType: "plist") {
            let dictRoot = NSDictionary(contentsOfFile: path)
            if let dict = dictRoot {
                GIDSignIn.sharedInstance().clientID = dict["CLIENT_ID"] as! String
                Halo.Manager.core.logMessage("Configured GoogleSignIn with clientId: \(GIDSignIn.sharedInstance().clientID)", level: .info)
            }
        }
        else {
            let e: HaloError = .loginError("No GoogleService-Info file from bundle")
            Manager.core.logMessage(e.description, level: .error)
        }

        GIDSignIn.sharedInstance().delegate = self

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
    
    public func handleLoginResult(idToken: String?, error: Error!, completionHandler handler: @escaping ((HTTPURLResponse?, Result<Halo.User?>) -> Void)) {
        
        guard
            error == nil
        else {
            let haloError = HaloError.registrationError(error.localizedDescription)
            Manager.core.logMessage(haloError.description, level: .error)
            handler(nil, .failure(haloError))
            return
        }
        
        guard
            let idToken = idToken
        else {
            let e: HaloError = .loginError("No token could be obtained from Google")
            Manager.core.logMessage(e.description, level: .error)
            handler(nil, .failure(e))
            return
        }
        
        guard
            let deviceAlias = Manager.core.device?.alias
        else {
            let e: HaloError = .loginError("No device alias could be obtained")
            Manager.core.logMessage(e.description, level: .error)
            handler(nil, .failure(e))
            return
        }
        
        Halo.Manager.core.logMessage("Google token: \(idToken)", level: .info)
     
        let profile = AuthProfile(token: idToken, network: .google, deviceId: deviceAlias)
        authenticate(authProfile: profile) { (user, error) in

                GIDSignIn.sharedInstance().signOut()

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
    func loginWithGoogle(uiDelegate: GIDSignInUIDelegate, stayLoggedIn: Bool = Manager.auth.stayLoggedIn, completionHandler handler: @escaping (HTTPURLResponse?, Result<Halo.User?>) -> Void) {
        guard
            let googleSocialAddon = self.googleSocialAddon
        else {

            let e: HaloError = .loginError("No GoogleSocialAddon has been configured and registered.")
            Manager.core.logMessage(e.description, level: .error)
            handler(nil, .failure(e))

            return
        }
        
        Manager.auth.stayLoggedIn = stayLoggedIn        
        googleSocialAddon.completionHandler = handler
        
        GIDSignIn.sharedInstance().uiDelegate = uiDelegate
        GIDSignIn.sharedInstance().signIn()
    }
    
}
