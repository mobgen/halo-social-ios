//
//  SocialProvider.swift
//  HaloSocial
//
//  Created by Borja Santos-Díez on 17/11/16.
//  Copyright © 2016 Mobgen Technology. All rights reserved.
//

import Foundation
import Halo

public protocol SocialProvider {
    
    func authenticate(authProfile: AuthProfile, completionHandler handler: @escaping (User?, NSError?) -> Void) -> Void
    
}

public extension SocialProvider {
    
    func authenticate(authProfile: AuthProfile, completionHandler handler: @escaping (User?, NSError?) -> Void) {
        let request = Halo.Request<User>(router: Router.loginUser(authProfile.toDictionary()))
        try! request.responseParser(parser: userParser).responseObject { (_, result) in
            switch result {
            case .success(let user, _):
                LogMessage(message: "The user has been successfully authenticated with Halo." , level: .info).print()
                handler(user, nil)
            case .failure(let error):
                LogMessage(message: "An error happened trying to authenticate the user with Halo.", error: error)
                handler(nil, error)
            }
        }
    }
    
    // MARK : Private methods.
    
    private func userParser(_ data: Any?) -> User? {
        if let dict = data as? [String: Any] {
            return User.fromDictionary(dict)
        }
        return nil
    }
    
}
