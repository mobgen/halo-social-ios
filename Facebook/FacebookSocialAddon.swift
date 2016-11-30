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

@objc(HaloFacebookSocialAddon)
class FacebookSocialAddon : NSObject, Halo.DeeplinkingAddon, SocialProvider {
    
    var addonName: String = "FacebookSocialAddon"
    
    func setup(haloCore core: CoreManager, completionHandler handler: ((Addon, Bool) -> Void)?) {
        
    }
    
    func startup(haloCore core: CoreManager, completionHandler handler: ((Addon, Bool) -> Void)?) {
        
    }
    
    func didRegisterAddon(haloCore core: CoreManager) {
    }
    
    func willRegisterAddon(haloCore core: CoreManager) {
        
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any]) -> Bool {
        return false
    }
    
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        return false
    }
    
    func login(viewController: UIViewController? = nil, completionHandler handler: @escaping (User?, NSError?) -> Void) {
        SocialManager.loginWithFacebook(viewController: viewController,
                                        completionHandler: handler)
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

extension SocialManager {
    
    static let facebookProvider: FacebookSocialProvider = {
        return FacebookSocialProvider()
    }()
    
    enum SocialManagerError {
        case FacebookError
        case FacebookCancelled
        
        static var errorDomain: String {
            return "SocialManagerError"
        }
        
        var errorCode: Int {
            switch self {
            case .FacebookError:
                return 0
            case .FacebookCancelled:
                return 1
            }
        }
        
        var errorUserInfo: [String: AnyObject] {
            switch self {
            case .FacebookError:
                return [:]
            case .FacebookCancelled:
                return [NSLocalizedDescriptionKey: "Login with Facebook cancelled by user." as AnyObject]
            }
        }
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
                handler(nil, NSError(domain: SocialManagerError.errorDomain,
                                     code: SocialManagerError.FacebookError.errorCode,
                                     userInfo: [NSLocalizedDescriptionKey: error.localizedDescription]))
            case .cancelled:
                // 2.b. Show error.
                print("User cancelled login")
                handler(nil, NSError(domain: SocialManagerError.errorDomain,
                                     code: SocialManagerError.FacebookCancelled.errorCode,
                                     userInfo: SocialManagerError.FacebookCancelled.errorUserInfo))
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
