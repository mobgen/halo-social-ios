//
//  BaseSpec.swift
//  HaloSocial
//
//  Created by Miguel López on 9/12/16.
//  Copyright © 2016 Mobgen Technology. All rights reserved.
//

import Quick
import Nimble
import OHHTTPStubs
import Halo
@testable import HaloSocial

class BaseSpec: QuickSpec {
    
    override func spec() {
        
        OHHTTPStubs.onStubActivation() { (request, stub, response) in
            if let url = request.url, let name = stub.name {
                print("\(url) stubbed by \"\(name).\"")
            }
        }
        
        beforeSuite {
            NSLog("-- Executing before suite")
            
            Halo.Manager.core.appCredentials = Credentials(clientId: "halotestappclient", clientSecret: "halotestapppass")
            Halo.Manager.core.startup()
        }
        
        afterSuite {
            NSLog("-- Executing after suite")
        }
        
    }
}
