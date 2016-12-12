//
//  SocialManagerSpec.swift
//  HaloSocial
//
//  Created by Miguel López on 9/12/16.
//  Copyright © 2016 Mobgen Technology. All rights reserved.
//

import Quick
import Nimble
import Halo
import OHHTTPStubs
@testable import HaloSocial

class SocialManagerSpec: BaseSpec {
    
    lazy var testAuthProfile: AuthProfile = {
        return AuthProfile(email: "account@mobgen.com",
                           password: "password123",
                           deviceId: "randomdevicealias")
    }()
    
    lazy var testUserProfile: UserProfile = {
        return UserProfile(id: nil,
                           email: "account@mobgen.com",
                           name: "testName",
                           surname: "testSurname",
                           displayName: "testName testSurname",
                           profilePictureUrl: nil)
    }()
    
    override func spec() {
        
        super.spec()
        
        describe("Login with Halo") {
            
            context("using email and password") {
                
                beforeEach {
                    
                    stub(condition: isPath("/api/segmentation/identified/login")) { _ in
                        let stubPath = OHPathForFile("login_success.json", type(of: self))
                        return fixture(filePath: stubPath!, status: 200, headers: ["Content-Type":"application/json"])
                    }.name = "Successful login stub"
                    
                }
                
                afterEach {
                    OHHTTPStubs.removeAllStubs()
                }
                
                it("logs in successfuly") {
                    
                    waitUntil { done in
                        
                        Halo.Manager.social.loginWithHalo(authProfile: self.testAuthProfile) { (userResponse, error) in
                            
                            expect(error).to(beNil())
                            
                            let token = userResponse?.token
                            
                            expect(token).notTo(beNil())
                            expect(token?.isValid()).to(beTrue())
                            expect(token?.isExpired()).to(beFalse())
                            
                            let userProfile = userResponse?.userProfile
                            
                            expect(userProfile?.email).to(equal(self.testAuthProfile.email))
                            
                            done()
                        }
                    }
                    
                }
            }
            
        }
        
        describe("Register with Halo") {
            
            beforeEach {
                
                stub(condition: isPath("/api/segmentation/identified/register")) { _ in
                    let stubPath = OHPathForFile("register_success.json", type(of: self))
                    return fixture(filePath: stubPath!, status: 200, headers: ["Content-Type":"application/json"])
                    }.name = "Successful register stub"
                
            }
            
            afterEach {
                OHHTTPStubs.removeAllStubs()
            }
            
            it("registers successfuly") {
                
                waitUntil { done in
                    
                    Halo.Manager.social.register(authProfile: self.testAuthProfile, userProfile: self.testUserProfile) { (userProfileResponse, error) in
                        
                        expect(error).to(beNil())
                        expect(userProfileResponse).notTo(beNil())
                        expect(userProfileResponse?.identifiedId).notTo(beNil())
                        expect(userProfileResponse?.email).to(equal(self.testAuthProfile.email))
                        
                        done()
                    }
                }
                
            }
        }
    }
    
}
