//
//  GoogleSocialAddonSpec.swift
//  HaloSocial
//
//  Created by Miguel López on 14/12/16.
//  Copyright © 2016 Mobgen Technology. All rights reserved.
//

import Quick
import Nimble
import OHHTTPStubs
import Halo
import HaloSocial
import GoogleSignIn
import Firebase
@testable import HaloSocialGoogle

class GoogleSocialAddonSpec : BaseSpec {
    
    let uiDelegate = MockUIDelegate()
    
    var googleSocialAddon: GoogleSocialAddon!
    
    override func spec() {
        
        super.spec()
        
        describe("Login with Google") {
            
            context("When Google Addon is not registered") {
                
                beforeEach {
                    // Start Halo.
                    Manager.core.appCredentials = Credentials(clientId: "halotestappclient", clientSecret: "halotestapppass")
                    Manager.core.startup()
                }
                
                it("returns a nil user and throws an error") {
                    
                    Manager.auth.loginWithGoogle(uiDelegate: self.uiDelegate) { (user, error) in
                        // user == nil.
                        expect(user).to(beNil())
                        // error != nil.
                        expect(error).toNot(beNil())
                    }
                    
                }
                
            }
            
        }
        
        describe("Login with Google ended") {
            
            beforeEach {
                // Register GoogleSocialAddon.
                self.googleSocialAddon = MockGoogleSocialAddon()
                Manager.core.registerAddon(addon: self.googleSocialAddon)
                
                // Start Halo.
                Manager.core.appCredentials = Credentials(clientId: "halotestappclient", clientSecret: "halotestapppass")
                Manager.core.startup()
            }
            
            context("without a device") {
                
                it("returns a nil user and an Error") {
                    
                    self.googleSocialAddon.handleLoginResult(idToken: nil, error: nil) {
                        (user, error) in
                        
                        // user == nil.
                        expect(user).to(beNil())
                        // error != nil.
                        expect(error).notTo(beNil())
                    }
                    
                }
            }
            
            context("with an error from Google") {
                
                beforeEach {
                    // Add a device for test purposes.
                    let device = Device()
                    device.alias = "randomdevicealias"
                    Manager.core.device = device
                }
                
                it("returns a nil user and an Error") {
                    
                    let error = NSError(domain: "com.mobgen.halo.test",
                                        code: -1,
                                        userInfo: [NSLocalizedDescriptionKey: "test error message"])
                    
                    self.googleSocialAddon.handleLoginResult(idToken: nil, error: error) {
                        (user, error) in
                        
                        // user == nil.
                        expect(user).to(beNil())
                        // error != nil.
                        expect(error).notTo(beNil())
                    }
                    
                }
                
            }
            
            context("With success") {
                
                beforeEach {
                    // Add a device for test purposes.
                    let device = Device()
                    device.alias = "randomdevicealias"
                    Manager.core.device = device
                    
                    stub(condition: isPath("/api/segmentation/identified/login")) { _ in
                        let stubPath = OHPathForFile("login_success.json", type(of: self))
                        return fixture(filePath: stubPath!, status: 200, headers: ["Content-Type":"application/json"])
                    }.name = "Successful login stub"
                }
                
                afterEach {
                    OHHTTPStubs.removeAllStubs()
                }
                
                it("returns a valid User object") {
                    
                    waitUntil(timeout: 2) { done in
                        
                        self.googleSocialAddon.handleLoginResult(idToken: "testrandomgoogletoken", error: nil) {
                            (user, error) in
                            
                            // error == nil.
                            expect(error).to(beNil())
                            let token = user?.token
                            // token != nil.
                            expect(token).notTo(beNil())
                            // token should be valid.
                            expect(token?.isValid()).to(beTrue())
                            // token should not be expired.
                            expect(token?.isExpired()).to(beFalse())
                            
                            done()
                        }
                        
                    }
                    
                }
                
            }
            
        }
        
        describe("When trying to logout") {
            
            context("and user is not logged in yet with Google") {
                
                it("returns false") {
                    
                    expect(self.googleSocialAddon.logout()).to(beFalse())
                    
                }
                
            }
            /*
             context("and user is logged in with Google") {
             
             it("returns true") {
             
             expect(self.googleSocialAddon.logout()).to(beTrue())
             
             }
             
             }
             */
        }
        
    }
    
}
