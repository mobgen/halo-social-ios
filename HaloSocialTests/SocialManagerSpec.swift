//
//  SocialManagerSpec.swift
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

class SocialManagerSpec: BaseSpec {
    
    var authProfile: AuthProfile!
    
    override func spec() {
        
        super.spec()
        
        let social = Halo.Manager.social
        
        describe("Login with Halo AuthProfile") {
            
            context("with an AuthProfile") {
                
                var user: User?
                
                beforeEach {
                    
                    guard
                        let alias = Halo.Manager.core.device?.alias
                    else {
                        return
                    }
                    
                    self.authProfile = AuthProfile(email: "account@mobgen.com", password: "password123", deviceId: alias)
                    
                    stub(condition: isPath("api/segmentation/identified/login")) { (request) -> OHHTTPStubsResponse in
                        let fixture = OHPathForFile("login_success.json", type(of: self))
                        return OHHTTPStubsResponse(fileAtPath: fixture!, statusCode: 200, headers: ["Content-Type": "application/json"])
                    }
                    
                    waitUntil { done in
                        social.loginWithHalo(authProfile: self.authProfile) { (userResponse, error) in
                            if error == nil {
                                user = userResponse
                            }
                            done()
                        }
                    }
                    
                }
                
                afterEach {
                    OHHTTPStubs.removeAllStubs()
                }
                
                it("works") {
                    let token = user?.token
                    
                    expect(token?.isValid()).to(beTrue())
                    expect(token?.isExpired()).to(beFalse())
                    
                    let userProfile = user?.userProfile
                    
                    expect(userProfile?.email).to(equal("account@mobgen.com"))
                }
            }
        }
    }
    
}
