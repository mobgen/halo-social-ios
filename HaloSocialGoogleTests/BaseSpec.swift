//
//  BaseSpec.swift
//  HaloSocial
//
//  Created by Miguel López on 14/12/16.
//  Copyright © 2016 Mobgen Technology. All rights reserved.
//

import Quick
import Nimble
import OHHTTPStubs
import Halo
@testable import HaloSocialGoogle

class BaseSpec : QuickSpec {
    
    override func spec() {
        
        OHHTTPStubs.onStubActivation() { (request, stub, response) in
            if let url = request.url, let name = stub.name {
                print("\(url) stubbed by \"\(name).\"")
            }
        }
        
        beforeSuite {
            NSLog("-- Executing before suite")
        }
        
        afterSuite {
            NSLog("-- Executing after suite")
        }
        
    }
    
}
