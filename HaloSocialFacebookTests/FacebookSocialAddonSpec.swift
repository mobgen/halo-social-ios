//
//  FacebookSocialAddonSpec.swift
//  HaloSocial
//
//  Created by Miguel López on 13/12/16.
//  Copyright © 2016 Mobgen Technology. All rights reserved.
//

import Quick
import Nimble
import OHHTTPStubs
import Halo
import FacebookCore
import FacebookLogin
@testable import HaloSocialFacebook

class FacebookSocialAddonSpec : BaseSpec {
    
    lazy var testAuthProfile: AuthProfile = {
        return AuthProfile(token: "randomfacebooktoken",
                           network: Network.Facebook,
                           deviceId: "randomdevicealias")
    }()
    
    lazy var errorLoginResult: LoginResult = {
        return LoginResult.failed(NSError(domain: "com.mobgen.haloSocialFacebookTests",
                                          code: -1,
                                          userInfo: [NSLocalizedDescriptionKey: "Test error from Facebook"]))
    }()
    
    lazy var cancelledLoginResult: LoginResult = {
       return LoginResult.cancelled
    }()
    
    lazy var successWithEmailPermissionLoginResult: LoginResult = {
        var grantedPermissions: Set<Permission> = Set()
        grantedPermissions.insert(Permission(name: "email"))
        grantedPermissions.insert(Permission(name: "public_profile"))
        
        var declinedPermissions: Set<Permission> = Set()
        
        let accessToken = AccessToken(appId: "testAppId",
                                      authenticationToken: "randomfacebooktoken",
                                      userId: nil,
                                      refreshDate: Date(),
                                      expirationDate: Date(),
                                      grantedPermissions: grantedPermissions,
                                      declinedPermissions: declinedPermissions)
        
        return LoginResult.success(grantedPermissions: grantedPermissions,
                                   declinedPermissions: declinedPermissions,
                                   token: accessToken)
    }()
    
    lazy var successWithoutEmailPermissionLoginResult: LoginResult = {
        var grantedPermissions: Set<Permission> = Set()
        grantedPermissions.insert(Permission(name: "public_profile"))
        
        var declinedPermissions: Set<Permission> = Set()
        declinedPermissions.insert(Permission(name: "email"))
        
        let accessToken = AccessToken(appId: "testAppId",
                                      authenticationToken: "randomfacebooktoken",
                                      userId: nil,
                                      refreshDate: Date(),
                                      expirationDate: Date(),
                                      grantedPermissions: grantedPermissions,
                                      declinedPermissions: declinedPermissions)
        
        return LoginResult.success(grantedPermissions: grantedPermissions,
                                   declinedPermissions: declinedPermissions,
                                   token: accessToken)
    }()
    
    var facebookSocialAddon: FacebookSocialAddon!
    
    override func spec() {
        
        super.spec()
        
        describe("Login with Facebook") {
            context("when facebook addon is not registered") {
                var user: User?
                var error: NSError?
                
                beforeEach {
                    // Start Halo.
                    Manager.core.appCredentials = Credentials(clientId: "halotestappclient", clientSecret: "halotestapppass")
                    Manager.core.startup()
                    
                    waitUntil { done in
                        Manager.auth.loginWithFacebook { (userResponse, errorResponse) in
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
            
            context("when facebook addon is registered") {
                beforeEach {
                    // Register FacebookSocialAddon.
                    self.facebookSocialAddon = FacebookSocialAddon()
                    Manager.core.registerAddon(addon: self.facebookSocialAddon)
                    
                    // Start Halo.
                    Manager.core.appCredentials = Credentials(clientId: "halotestappclient", clientSecret: "halotestapppass")
                    Manager.core.startup()
                }
                
                context("without a device") {
                    var user: User?
                    var error: NSError?
                    
                    beforeEach {
                        waitUntil { done in
                            Manager.auth.loginWithFacebook { (userResponse, errorResponse) in
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
                
                context("and facebook login process has ended") {
                    context("without a device") {
                        var user: User?
                        var error: NSError?
                        
                        beforeEach {
                            waitUntil { done in
                                self.facebookSocialAddon.handleLoginResult(loginResult: self.successWithEmailPermissionLoginResult) { (userResponse, errorResponse) in
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
                            expect(error).notTo(beNil())
                        }
                    }
                    
                    context("with an error from Facebook") {
                        var user: User?
                        var error: NSError?
                        
                        beforeEach {
                            // Add a device for test purposes.
                            let device = Device()
                            device.alias = "randomdevicealias"
                            Manager.core.device = device
                            
                            waitUntil { done in
                                self.facebookSocialAddon.handleLoginResult(loginResult: self.errorLoginResult) { (userResponse, errorResponse) in
                                    user = userResponse
                                    error = errorResponse
                                    done()
                                }
                            }
                        }
                        
                        it("returns a nil user") {
                            expect(user).to(beNil())
                        }
                        
                        it("returns a FacebookSocialAddonError.Error") {
                            expect(error).notTo(beNil())
                            expect(error?.domain).to(equal(FacebookSocialAddon.FacebookSocialAddonError.errorDomain))
                            expect(error?.code).to(equal(FacebookSocialAddon.FacebookSocialAddonError.Error.errorCode))
                        }                        
                    }
                    
                    context("because user cancelled login") {
                        
                        beforeEach {
                            // Add a device for test purposes.
                            let device = Device()
                            device.alias = "randomdevicealias"
                            Manager.core.device = device
                        }
                        
                        it("returns a nil user and a FacebookSocialAddonError.Cancelled") {
                            
                            self.facebookSocialAddon.handleLoginResult(loginResult: self.cancelledLoginResult) {
                                (user, error) in
                                
                                // user == nil.
                                expect(user).to(beNil())
                                // error != nil.
                                expect(error).notTo(beNil())
                                // Check errorDomain.
                                expect(error?.domain).to(equal(FacebookSocialAddon.FacebookSocialAddonError.errorDomain))
                                // Check errorCode.
                                expect(error?.code).to(equal(FacebookSocialAddon.FacebookSocialAddonError.Cancelled.errorCode))
                            }
                            
                        }
                    }
                    
                    context("With success but email permission is declined") {
                        
                        beforeEach {
                            // Add a device for test purposes.
                            let device = Device()
                            device.alias = "randomdevicealias"
                            Manager.core.device = device
                        }
                        
                        it("returns a nil user and a FacebookSocialAddonError.PermissionEmailDenied") {
                            
                            self.facebookSocialAddon.handleLoginResult(loginResult: self.successWithoutEmailPermissionLoginResult) {
                                (user, error) in
                                
                                // user == nil.
                                expect(user).to(beNil())
                                // error != nil.
                                expect(error).notTo(beNil())
                                // Check errorDomain.
                                expect(error?.domain).to(equal(FacebookSocialAddon.FacebookSocialAddonError.errorDomain))
                                // Check errorCode.
                                expect(error?.code).to(equal(FacebookSocialAddon.FacebookSocialAddonError.PermissionEmailDenied.errorCode))
                            }
                            
                        }
                        
                    }
                    
                    context("With success and email permission is granted") {
                        
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
                                
                                self.facebookSocialAddon.handleLoginResult(loginResult: self.successWithEmailPermissionLoginResult) {
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
            }
        }
        
        describe("When trying to logout") {
            
            context("and user is not logged in yet with Facebook") {
                
                it("returns false") {
                    
                    expect(self.facebookSocialAddon.logout()).to(beFalse())
                    
                }
                
            }
            /*
            context("and user is logged in with Facebook") {
                
                it("returns true") {
                    
                    expect(self.facebookSocialAddon.logout()).to(beTrue())
                    
                }
                
            }
            */
        }
    }
}
