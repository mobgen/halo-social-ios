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

public class FacebookSocialAddon : NSObject, DeeplinkingAddon, LifecycleAddon, AuthProvider {
    
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
    
    public func login(viewController: UIViewController? = nil, completionHandler handler: @escaping (User?, NSError?) -> Void) {
        
        // Check if deviceAlias exists.
        guard
            let deviceAlias = Manager.core.device?.alias
        else {
            let message = "No device alias could be obtained"
            LogMessage(message: message, level: .error).print()
            handler(nil, NSError(domain: "com.mobgen.halo", code: -1, userInfo: [NSLocalizedDescriptionKey: message]))
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
            LogMessage(message: "Already logged in with Facebook.", level: .info).print()
            let authProfile = AuthProfile(token: AccessToken.current!.authenticationToken,
                                          network: Network.Facebook,
                                          deviceId: deviceAlias)
            self.authenticate(authProfile: authProfile, completionHandler: handler)
            return
        }
        
        // Not logged in or Email ReadPermission is not already granted.
        let loginManager = LoginManager()
        loginManager.logIn(readPermissions: [.publicProfile, .email], viewController: viewController) {
            loginResult in
            
            self.handleLoginResult(loginResult: loginResult, completionHandler: handler)
        }
    }
    
    public func handleLoginResult(loginResult: FacebookLogin.LoginResult, completionHandler handler: @escaping (User?, NSError?) -> Void) {
        
        // Check if deviceAlias exists.
        guard
            let deviceAlias = Manager.core.device?.alias
            else {
                let message = "No device alias could be obtained"
                LogMessage(message: message, level: .error).print()
                handler(nil, NSError(domain: "com.mobgen.halo", code: -1, userInfo: [NSLocalizedDescriptionKey: message]))
                return
        }
        
        switch loginResult {
            
        // Error.
        case .failed(let error):
            LogMessage(message: "An error ocurred when user was trying to authenticate with Facebook.", level: .error).print()
            handler(nil, NSError(domain: FacebookSocialAddon.FacebookSocialAddonError.errorDomain,
                                 code: FacebookSocialAddon.FacebookSocialAddonError.Error.errorCode,
                                 userInfo: [NSLocalizedDescriptionKey: error.localizedDescription]))
            
        // Cancelled.
        case .cancelled:
            LogMessage(message: "User cancelled the authentication with Facebook.", level: .error).print()
            handler(nil, NSError(domain: FacebookSocialAddon.FacebookSocialAddonError.errorDomain,
                                 code: FacebookSocialAddon.FacebookSocialAddonError.Cancelled.errorCode,
                                 userInfo: FacebookSocialAddon.FacebookSocialAddonError.Cancelled.errorUserInfo))
            
        // Success.
        case .success(let grantedPermissions, _, let accessToken):
            // Check if Email ReadPermission is granted.
            guard
                grantedPermissions.contains(Permission(name: "email"))
                else {
                    LogMessage(message: "User denied permissions access to his email.", level: .info).print()
                    handler(nil, NSError(domain: FacebookSocialAddon.FacebookSocialAddonError.errorDomain,
                                         code: FacebookSocialAddon.FacebookSocialAddonError.PermissionEmailDenied.errorCode,
                                         userInfo: FacebookSocialAddon.FacebookSocialAddonError.PermissionEmailDenied.errorUserInfo))
                    return
            }
            
            // Login with Halo.
            LogMessage(message: "Login with Facebook successful", level: .info).print()
            let authProfile = AuthProfile(token: accessToken.authenticationToken,
                                          network: Network.Facebook,
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
    @objc(loginWithFacebookWithViewController:stayLoggedIn:completionHandler:)
    func loginWithFacebook(viewController: UIViewController? = nil, stayLoggedIn: Bool = Manager.auth.stayLoggedIn, completionHandler handler: @escaping (User?, NSError?) -> Void) {
        guard
            let facebookSocialAddon = self.facebookSocialAddon
        else {
            let message = "No FacebookSocialAddon has been configured and registered."
            LogMessage(message: message, level: .error).print()
            handler(nil, NSError(domain: "com.mobgen.halo", code: -1, userInfo: [NSLocalizedDescriptionKey: message]))
            return
        }
        
        Manager.auth.stayLoggedIn = stayLoggedIn        
        facebookSocialAddon.login(viewController: viewController, completionHandler: handler)
    }
    
}
