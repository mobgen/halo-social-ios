//
//  MockGoogleSocialAddon.swift
//  HaloSocial
//
//  Created by Miguel López on 14/12/16.
//  Copyright © 2016 Mobgen Technology. All rights reserved.
//

import Halo
import HaloSocialGoogle

class MockGoogleSocialAddon : GoogleSocialAddon {
    
    override func startup(haloCore core: CoreManager, completionHandler handler: ((Addon, Bool) -> Void)?) {
        
        handler?(self, true)
        
    }
    
}
