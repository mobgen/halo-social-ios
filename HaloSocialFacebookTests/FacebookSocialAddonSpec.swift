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
            context("when Facebook Addon is not registered") {
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
            
            context("when Facebook Addon is registered") {
                var user: User?
                var error: NSError?

                beforeEach {
                    // Register FacebookSocialAddon.
                    self.facebookSocialAddon = FacebookSocialAddon()
                    Manager.core.registerAddon(addon: self.facebookSocialAddon)
                    
                    // Start Halo.
                    Manager.core.appCredentials = Credentials(clientId: "halotestappclient", clientSecret: "halotestapppass")
                    Manager.core.startup()
                }
                
                context("stayLoggedIn is ! Manager.auth.stayLoggedI") {
                    let stayLoggedIn = !Manager.auth.stayLoggedIn
                    
                    beforeEach {
                        waitUntil { done in
                            Manager.auth.loginWithFacebook(stayLoggedIn: stayLoggedIn) { (_, _) in
                                done()
                            }
                        }
                    }
                    
                    afterEach {
                        waitUntil { done in
                            Manager.auth.logout { success in
                                done()
                            }
                        }
                    }
                    
                    it("stayLoggedIn AuthManager property is correctly set") {
                        expect(Manager.auth.stayLoggedIn).to(equal(stayLoggedIn))
                    }
                }
                
                context("without a device") {
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
                
                context("and Facebook login process has ended") {
                    context("without a device") {
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
                    
                    context("with a device") {
                        beforeEach {
                            // Add a device for test purposes.
                            let device = Device()
                            device.alias = "randomdevicealias"
                            Manager.core.device = device
                        }
                        
                        context("with an error from Facebook") {
                            beforeEach {
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
                                waitUntil { done in
                                    self.facebookSocialAddon.handleLoginResult(loginResult: self.cancelledLoginResult) { (userResponse, errorResponse) in
                                        user = userResponse
                                        error = errorResponse
                                        done()
                                    }
                                }
                            }
                            
                            it("returns a nil User") {
                                expect(user).to(beNil())
                            }
                            
                            it("returns a FacebookSocialAddonError.Cancelled") {
                                expect(error).notTo(beNil())
                                expect(error?.domain).to(equal(FacebookSocialAddon.FacebookSocialAddonError.errorDomain))
                                expect(error?.code).to(equal(FacebookSocialAddon.FacebookSocialAddonError.Cancelled.errorCode))
                            }
                        }
                        
                        context("With success but email permission is declined") {
                            beforeEach {
                                waitUntil { done in
                                    self.facebookSocialAddon.handleLoginResult(loginResult: self.successWithoutEmailPermissionLoginResult) { (userResponse, errorResponse) in
                                        user = userResponse
                                        error = errorResponse
                                        done()
                                    }
                                }
                            }
                            
                            it("returns a nil User") {
                                expect(user).to(beNil())
                            }
                            
                            it("returns a FacebookSocialAddonError.PermissionEmailDenied") {
                                expect(error).notTo(beNil())
                                expect(error?.domain).to(equal(FacebookSocialAddon.FacebookSocialAddonError.errorDomain))
                                expect(error?.code).to(equal(FacebookSocialAddon.FacebookSocialAddonError.PermissionEmailDenied.errorCode))
                            }
                        }
                        
                        context("With success and email permission is granted") {
                            beforeEach {
                                stub(condition: isPath("/api/segmentation/identified/login")) { _ in
                                    let stubPath = OHPathForFile("login_success.json", type(of: self))
                                    return fixture(filePath: stubPath!, status: 200, headers: ["Content-Type":"application/json"])
                                }.name = "Successful login stub"
                                
                                waitUntil { done in
                                    self.facebookSocialAddon.handleLoginResult(loginResult: self.successWithEmailPermissionLoginResult) { (userResponse, errorResponse) in
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
