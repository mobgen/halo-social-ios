//
//  UserProfile.swift
//  HaloSocial
//
//  Created by Borja Santos-Díez on 17/11/16.
//  Copyright © 2016 Mobgen Technology. All rights reserved.
//

import Foundation

@objc(HaloUserProfile)
public class UserProfile: NSObject {
    
    var identifiedId: String
    var email: String
    var profilePictureUrl: String?
    var displayName: String? {
        get {
            if self.displayName == nil {
                return name
            }
            return self.displayName
        }
        set {
            self.displayName = newValue
        }
    }
    var name: String
    var surname: String
    
    public override var debugDescription: String {
        return "[UserProfile] Id: \(identifiedId) | Email: \(email) | DisplayName: \(displayName)"
    }
    
    init(id: String, email: String, name: String, surname: String, displayName: String?, profilePictureUrl: String?) {
        self.identifiedId = id
        self.email = email
        self.name = name
        self.surname = surname
        super.init()
        self.displayName = displayName
        self.profilePictureUrl = profilePictureUrl
        
    }
    
}
