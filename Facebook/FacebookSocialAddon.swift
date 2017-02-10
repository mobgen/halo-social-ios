//
//  FacebookSocialAddon.swift
//  HaloSocial
//
//  Created by Miguel López on 30/11/16.
//  Copyright © 2016 Mobgen Technology. All rights reserved.
//

import Foundation
import Halo
import FacebookCore
import FacebookLogin

open class FacebookSocialAddon : NSObject, DeeplinkingAddon, LifecycleAddon, AuthProvider {
    
    public enum FacebookSocialAddonError {
        case Error
        case Cancelled
        case PermissionEmailDenied
        
        static var errorDomain: String {
            return "com.mobgen.halo"
        }
        
        var errorCode: Int {
            switch self {
            case .Error:
                return 0
            case .Cancelled:
                return 1
            case .PermissionEmailDenied:
                return 2
            }
        }
        
        var errorUserInfo: [String: AnyObject] {
            switch self {
            case .Error:
                return [:]
            case .Cancelled:
                return [NSLocalizedDescriptionKey: "Login with Facebook cancelled by user." as AnyObject]
            case .PermissionEmailDenied:
                return [NSLocalizedDescriptionKey: "User denied permission access to email." as AnyObject]
            }
        }
    }
    
    public var addonName: String = "FacebookSocialAddon"
    
    // MARK : Addon methods.
    
    public func setup(haloCore core: CoreManager, completionHandler handler: ((Addon, Bool) -> Void)?) {
        handler?(self, true)
    }
    
    public func startup(haloCore core: CoreManager, completionHandler handler: ((Addon, Bool) -> Void)?) {
        handler?(self, true)
    }
    
    public func willRegisterAddon(haloCore core: CoreManager) { }
    
    public func didRegisterAddon(haloCore core: CoreManager) { }
    
    // MARK : DeeplinkingAddon methods.
    
    public func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any]) -> Bool {
        if #available(iOS 9.0, *) {
            return SDKApplicationDelegate.shared.application(app, open: url, options: options)
        } else {
            return SDKApplicationDelegate.shared.application(app, open: url, sourceApplication: Bundle.main.bundleIdentifier, annotation: [:])
        }
    }
    
    public func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        return SDKApplicationDelegate.shared.application(application, open: url, sourceApplication: sourceApplication, annotation: annotation)
    }
    
    // MARK : LifecycleAddon methods.
    
    public func applicationWillFinishLaunching(_ app: UIApplication, core: Halo.CoreManager) -> Bool {
        return true
    }
    
    public func applicationDidFinishLaunching(_ app: UIApplication,
                                       core: Halo.CoreManager,
                                       didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]?) -> Bool {
        return SDKApplicationDelegate.shared.application(app, didFinishLaunchingWithOptions: launchOptions)
    }
    
    public func applicationDidEnterBackground(_ app: UIApplication, core: Halo.CoreManager) -> Void { }
    
    public func applicationDidBecomeActive(_ app: UIApplication, core: Halo.CoreManager) -> Void { }
    
    // MARK : AuthProvider methods.
    
    public func logout() {
        let loginManager = LoginManager()
        loginManager.logOut()
    }
    
    // MARK : Other methods.
    
    public func login(viewController: UIViewController? = nil, completionHandler handler: @escaping (User?, HaloError?) -> Void) {
        
        // Check if deviceAlias exists.
        guard
            let deviceAlias = Manager.core.device?.alias
        else {
            let message = "No device alias could be obtained"
            Halo.Manager.core.logMessage(message: message, level: .error)
            handler(nil, .loginError(message))
            return
        }
        
        // Check if user already logged in with Facebook
        // and check if Email ReadPermission is already granted.
        guard
            AccessToken.current == nil ||
            AccessToken.current!.grantedPermissions == nil ||
            !AccessToken.current!.grantedPermissions!.contains(Permission(name: "email"))
        else {
            // Already logged-in, login with Halo.
            Halo.Manager.core.logMessage(message: "Already logged in with Facebook.", level: .info)
            let authProfile = AuthProfile(token: AccessToken.current!.authenticationToken,
                                          network: .facebook,
                                          deviceId: deviceAlias)
            self.authenticate(authProfile: authProfile, completionHandler: handler)
            return
        }
        
        // Not logged in or Email ReadPermission is not already granted.
        let loginManager = LoginManager()
        loginManager.logIn([.publicProfile, .email], viewController: viewController) {
            loginResult in
            
            self.handleLoginResult(loginResult: loginResult, completionHandler: handler)
        }
    }
    
    public func handleLoginResult(loginResult: FacebookLogin.LoginResult, completionHandler handler: @escaping (User?, HaloError?) -> Void) {
        
        // Check if deviceAlias exists.
        guard
            let deviceAlias = Manager.core.device?.alias
            else {
                let message = "No device alias could be obtained"
                Halo.Manager.core.logMessage(message: message, level: .error)
                handler(nil, .loginError(message))
                return
        }
        
        switch loginResult {
            
        // Error.
        case .failed(let error):
            Halo.Manager.core.logMessage(message: "An error ocurred when user was trying to authenticate with Facebook.", level: .error)
            handler(nil, .loginError(error.localizedDescription))
            
        // Cancelled.
        case .cancelled:
            let message = "User cancelled the authentication with Facebook."
            Halo.Manager.core.logMessage(message: message, level: .error)
            handler(nil, .loginError(message))
            
        // Success.
        case .success(let grantedPermissions, _, let accessToken):
            // Check if Email ReadPermission is granted.
            guard
                grantedPermissions.contains(Permission(name: "email"))
                else {
                    let message = "User denied permissions access to his email."
                    Halo.Manager.core.logMessage(message: message, level: .info)
                    handler(nil, .loginError(message))
                    return
            }
            
            // Login with Halo.
            Halo.Manager.core.logMessage(message: "Login with Facebook successful", level: .info)
            let authProfile = AuthProfile(token: accessToken.authenticationToken,
                                          network: .facebook,
                                          deviceId: deviceAlias)
            self.authenticate(authProfile: authProfile, completionHandler: handler)
        }
    }
}

public extension AuthManager {
    
    private var facebookSocialAddon: FacebookSocialAddon? {
        return Manager.core.addons.filter { $0 is FacebookSocialAddon }.first as? FacebookSocialAddon
    }
    
    /**
     Call this method to start the login with Facebook.
     
     - parameter viewController:    The viewController to present from the login window. 
                                    If nil, the topmost view controller will be 
                                    automatically determined as best as possible.
     - parameter completionHandler: Closure to be called after completion
     */
    //@objc(loginWithFacebookWithViewController:stayLoggedIn:completionHandler:)
    func loginWithFacebook(viewController: UIViewController? = nil, stayLoggedIn: Bool = Manager.auth.stayLoggedIn, completionHandler handler: @escaping (User?, HaloError?) -> Void) {
        guard
            let facebookSocialAddon = self.facebookSocialAddon
        else {
            let message = "No FacebookSocialAddon has been configured and registered."
            Halo.Manager.core.logMessage(message: message, level: .error)
            handler(nil, .loginError(message))
            return
        }
        
        Manager.auth.stayLoggedIn = stayLoggedIn        
        facebookSocialAddon.login(viewController: viewController, completionHandler: handler)
    }
    
}
