//
//  FacebookSocialAddon.swift
//  HaloSocial
//
//  Created by Miguel López on 30/11/16.
//  Copyright © 2016 Mobgen Technology. All rights reserved.
//

import Foundation
import Halo
import HaloSocial
import FacebookCore
import FacebookLogin
import FBSDKLoginKit

public class FacebookSocialAddon : NSObject, Halo.DeeplinkingAddon, Halo.LifecycleAddon, SocialProvider {
    
    public enum FacebookSocialAddonError {
        case Error
        case Cancelled
        
        static var errorDomain: String {
            return "com.mobgen.halo"
        }
        
        var errorCode: Int {
            switch self {
            case .Error:
                return 0
            case .Cancelled:
                return 1
            }
        }
        
        var errorUserInfo: [String: AnyObject] {
            switch self {
            case .Error:
                return [:]
            case .Cancelled:
                return [NSLocalizedDescriptionKey: "Login with Facebook cancelled by user." as AnyObject]
            }
        }
    }
    
    public var addonName: String = "FacebookSocialAddon"
    
    // MARK : Addon methods.
    
    public func setup(haloCore core: CoreManager, completionHandler handler: ((Addon, Bool) -> Void)?) {
        LogMessage(message: "facebook setup", level: .info).print()
        handler?(self, true)
    }
    
    public func startup(haloCore core: CoreManager, completionHandler handler: ((Addon, Bool) -> Void)?) {
        LogMessage(message: "facebook startup", level: .info).print()
        handler?(self, true)
    }
    
    public func willRegisterAddon(haloCore core: CoreManager) {
        LogMessage(message: "facebook willRegisterAddon", level: .info).print()
    }
    
    public func didRegisterAddon(haloCore core: CoreManager) {
        LogMessage(message: "facebook didRegisterAddon", level: .info).print()
    }
    
    // MARK : DeeplinkingAddon methods.
    
    public func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any]) -> Bool {
        return FBSDKApplicationDelegate.sharedInstance().application(app, open: url, options: options)
    }
    
    public func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        return FBSDKApplicationDelegate.sharedInstance().application(application, open: url, sourceApplication: sourceApplication, annotation: annotation)
    }
    
    // MARK : LifecycleAddon methods.
    
    public func applicationWillFinishLaunching(_ app: UIApplication, core: Halo.CoreManager) -> Bool {
        return true
    }
    
    public func applicationDidFinishLaunching(_ app: UIApplication,
                                       core: Halo.CoreManager,
                                       didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]?) -> Bool {        
        return FBSDKApplicationDelegate.sharedInstance().application(app, didFinishLaunchingWithOptions: launchOptions)
    }
    
    public func applicationDidEnterBackground(_ app: UIApplication, core: Halo.CoreManager) -> Void { }
    
    public func applicationDidBecomeActive(_ app: UIApplication, core: Halo.CoreManager) -> Void { }
    
    public func login(viewController: UIViewController? = nil, completionHandler handler: @escaping (User?, NSError?) -> Void) {
        
        guard
            let deviceAlias = Manager.core.device?.alias
        else {
            let message = "No device alias could be obtained"
            LogMessage(message: message, level: .error).print()
            handler(nil, NSError(domain: "com.mobgen.halo", code: -1, userInfo: [NSLocalizedDescriptionKey: message]))
            return
        }
        
        let loginManager = LoginManager()
        
        guard
            AccessToken.current == nil
        else {
            // Already logged-in
            LogMessage(message: "Already logged in with Facebook.", level: .info).print()
            let authProfile = AuthProfile(token: AccessToken.current!.authenticationToken,
                                          network: Network.Facebook,
                                          deviceId: deviceAlias)
            self.authenticate(authProfile: authProfile, completionHandler: handler)
            return
        }
        
        loginManager.logIn(readPermissions: [.publicProfile, .email], viewController: viewController) {
            loginResult in
            
            switch loginResult {
            case .failed(let error):
                LogMessage(message: "An error ocurred when user was trying to authenticate with Facebook.", level: .error).print()
                handler(nil, NSError(domain: FacebookSocialAddon.FacebookSocialAddonError.errorDomain,
                                     code: FacebookSocialAddon.FacebookSocialAddonError.Error.errorCode,
                                     userInfo: [NSLocalizedDescriptionKey: error.localizedDescription]))
            case .cancelled:
                LogMessage(message: "User cancelled the authentication with Facebook.", level: .error).print()
                handler(nil, NSError(domain: FacebookSocialAddon.FacebookSocialAddonError.errorDomain,
                                     code: FacebookSocialAddon.FacebookSocialAddonError.Cancelled.errorCode,
                                     userInfo: FacebookSocialAddon.FacebookSocialAddonError.Cancelled.errorUserInfo))
            case .success(_, _, let accessToken):
                LogMessage(message: "Login with Facebook successful", level: .info).print()
                let authProfile = AuthProfile(token: accessToken.authenticationToken,
                                              network: Network.Facebook,
                                              deviceId: deviceAlias)
                self.authenticate(authProfile: authProfile, completionHandler: handler)
            }
        }
    }
    
}

public extension SocialManager {
    
    private var facebookSocialAddon: FacebookSocialAddon? {
        return Manager.core.addons.filter { $0 is FacebookSocialAddon }.first as? FacebookSocialAddon
    }
    
    func loginWithFacebook(viewController: UIViewController? = nil, completionHandler handler: @escaping (User?, NSError?) -> Void) {
        guard
            let facebookSocialAddon = self.facebookSocialAddon
        else {
            let message = "No FacebookSocialAddon has been configured and registered."
            LogMessage(message: message, level: .error).print()
            handler(nil, NSError(domain: "com.mobgen.halo", code: -1, userInfo: [NSLocalizedDescriptionKey: message]))
            return
        }
        
        facebookSocialAddon.login(viewController: viewController, completionHandler: handler)
    }
    
}
