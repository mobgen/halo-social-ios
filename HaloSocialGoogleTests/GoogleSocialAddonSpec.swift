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
import GoogleSignIn
import Firebase
@testable import HaloSocialGoogle

class GoogleSocialAddonSpec : BaseSpec {
    
    typealias CompletionHandler = (User?, NSError?) -> Void
    
    let errorFromGoogle = NSError(domain: "com.mobgen.halo",
                                  code: -1,
                                  userInfo: [NSLocalizedDescriptionKey: "Error message for test purposes."])
    let uiDelegate = MockUIDelegate()
    var googleSocialAddon: GoogleSocialAddon!
    let testCompletionHandler: CompletionHandler = { _, _ in }
    
    override func spec() {
        
        super.spec()
        
        describe("Login with Google") {
            context("when Google Addon is not registered") {
                var user: User?
                var error: NSError?
                
                beforeEach {
                    // Start Halo.
                    Manager.core.appCredentials = Credentials(clientId: "halotestappclient", clientSecret: "halotestapppass")
                    Manager.core.startup()
                    
                    waitUntil { done in
                        Manager.auth.loginWithGoogle(uiDelegate: self.uiDelegate) { (userResponse, errorResponse) in
                            user = userResponse
                            error = errorResponse
                            done()
                        }
                    }
                }
                
                it("returns a nil User") {
                    expect(user).to(beNil())
                }
                
                it("returns an error") {
                    expect(error).toNot(beNil())
                }
            }
            
            context("when Google Addon is registered") {
                var user: User?
                var error: NSError?

                beforeEach {
                    // Register GoogleSocialAddon.
                    self.googleSocialAddon = MockGoogleSocialAddon()
                    Manager.core.registerAddon(addon: self.googleSocialAddon)
                    
                    // Start Halo.
                    Manager.core.appCredentials = Credentials(clientId: "halotestappclient", clientSecret: "halotestapppass")
                    Manager.core.startup()
                }
                
                context("without a device") {
                    beforeEach {
                        waitUntil { done in
                            self.googleSocialAddon.handleLoginResult(idToken: "testrandomidToken", error: nil) { (userResponse, errorResponse) in
                                user = userResponse
                                error = errorResponse
                                done()
                            }
                        }
                    }
                    
                    it("returns a nil User") {
                        expect(user).to(beNil())
                    }
                    
                    it("returns an error") {
                        expect(error).toNot(beNil())
                    }
                }
                
                context("with a device") {
                    beforeEach {
                        // Add a device for test purposes.
                        let device = Device()
                        device.alias = "randomdevicealias"
                        Manager.core.device = device
                    }
                    
                    context("and Google login process has ended") {
                        context("with no idToken from Google") {
                            beforeEach {
                                waitUntil { done in
                                    self.googleSocialAddon.handleLoginResult(idToken: nil, error: nil) { (userResponse, errorResponse) in
                                        user = userResponse
                                        error = errorResponse
                                        done()
                                    }
                                }
                            }
                            
                            it("returns a nil user") {
                                expect(user).to(beNil())
                            }
                            
                            it("returns an error") {
                                expect(error).toNot(beNil())
                            }
                        }
                        
                        context("with an error from Google") {
                            beforeEach {
                                waitUntil { done in
                                    self.googleSocialAddon.handleLoginResult(idToken: nil, error: self.errorFromGoogle) { (userResponse, errorResponse) in
                                        user = userResponse
                                        error = errorResponse
                                        done()
                                    }
                                }
                            }
                            
                            it("returns a nil user") {
                                expect(user).to(beNil())
                            }
                            
                            it("returns an error") {
                                expect(error).toNot(beNil())
                            }
                        }
                        
                        context("with success") {
                            beforeEach {
                                stub(condition: isPath("/api/segmentation/identified/login")) { _ in
                                    let stubPath = OHPathForFile("login_success.json", type(of: self))
                                    return fixture(filePath: stubPath!, status: 200, headers: ["Content-Type":"application/json"])
                                }.name = "Successful login stub"
                                
                                waitUntil(timeout: 2) { done in
                                    self.googleSocialAddon.handleLoginResult(idToken: "testrandomgoogletoken", error: nil) { (userResponse, errorResponse) in
                                        user = userResponse
                                        error = errorResponse
                                        done()
                                    }
                                    
                                }
                            }
                        
                            afterEach {
                                OHHTTPStubs.removeAllStubs()
                            }

                            it("returns a valid User") {
                                expect(user).toNot(beNil())
                                let token = user?.token
                                expect(token).notTo(beNil())
                                expect(token?.isValid()).to(beTrue())
                                expect(token?.isExpired()).to(beFalse())
                            }
                            
                            it("returns a nil error") {
                                expect(error).to(beNil())
                            }
                        }
                    }
                }
            }
        }      
    }
    
}
