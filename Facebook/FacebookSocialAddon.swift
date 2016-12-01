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

public class FacebookSocialAddon : NSObject, Halo.DeeplinkingAddon, SocialProvider {
    
    enum FacebookSocialAddonError {
        case Error
        case Cancelled
        
        static var errorDomain: String {
            return "SocialManagerError"
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
    
    public func setup(haloCore core: CoreManager, completionHandler handler: ((Addon, Bool) -> Void)?) { }
    
    public func startup(haloCore core: CoreManager, completionHandler handler: ((Addon, Bool) -> Void)?) { }
    
    public func willRegisterAddon(haloCore core: CoreManager) { }
    
    public func didRegisterAddon(haloCore core: CoreManager) { }
    
    // MARK : DeeplinkingAddon methods.
    
    public func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any]) -> Bool {
        return false
    }
    
    public func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        return false
    }    
    
    private func userParser(_ data: Any?) -> User? {
        if let dict = data as? [String: Any] {
            return User.fromDictionary(dict: dict)
        }
        return nil
    }
    
    public func authenticate(authProfile: AuthProfile, completionHandler handler: (User?, NSError?) -> Void) {
        let request = Halo.Request<User>(router: Router.loginUser(authProfile.toDictionary()))
        try! request.responseParser(parser: userParser).responseObject(completionHandler: handler)
    }
}

public extension SocialManager {
    
    private var facebookSocialAddon: FacebookSocialAddon? {
        return Manager.core.addons.filter { $0 is FacebookSocialAddon }.first as? FacebookSocialAddon
    }
    
    func loginWithFacebook(viewController: UIViewController? = nil, completionHandler handler: @escaping (User?, NSError?) -> Void) {
        
        // 1. Start login with facebook
        let loginManager = LoginManager()
        loginManager.logIn(readPermissions: [.publicProfile, .email], viewController: viewController) {
            loginResult in
            
            switch loginResult {
            case .failed(let error):
                // 2.a. Show error.
                print(error)
                handler(nil, NSError(domain: FacebookSocialAddon.FacebookSocialAddonError.errorDomain,
                                     code: FacebookSocialAddon.FacebookSocialAddonError.Error.errorCode,
                                     userInfo: [NSLocalizedDescriptionKey: error.localizedDescription]))
            case .cancelled:
                // 2.b. Show error.
                print("User cancelled login")
                handler(nil, NSError(domain: FacebookSocialAddon.FacebookSocialAddonError.errorDomain,
                                     code: FacebookSocialAddon.FacebookSocialAddonError.Cancelled.errorCode,
                                     userInfo: FacebookSocialAddon.FacebookSocialAddonError.Cancelled.errorUserInfo))
            case .success(let grantedPermissions, let declinedPermissions, let accessToken):
                // 2.c. Ask for rest of data.
                print("Logged in!")
                let authProfile = AuthProfile(token: accessToken.authenticationToken,
                                              network: Network.Facebook,
                                              deviceId: Manager.core.device?.id ?? "")
                SocialManager.facebookProvider.authenticate(authProfile: authProfile, completionHandler: handler)
            }
        }
        
    }
    
}
