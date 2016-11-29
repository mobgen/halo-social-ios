//
//  AuthProfile.swift
//  HaloSocial
//
//  Created by Borja Santos-Díez on 17/11/16.
//  Copyright © 2016 Mobgen Technology. All rights reserved.
//

import Foundation

@objc(HaloAuthProfile)
public class AuthProfile: NSObject {
    
    var email: String?
    var password: String?
    var deviceId: String?
    
    public override var debugDescription: String {
        return "[AuthProfile] Email: \(email) | Password: \(password) | DeviceId: \(deviceId)"
    }
    
    init(email: String, password: String, deviceId: String?) {
        super.init()
        self.email = email
        self.password = password
        self.deviceId = deviceId
    }
    
}
