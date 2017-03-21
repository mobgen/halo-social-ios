Pod::Spec.new do |spec|
  spec.name             = 'HaloSocialSDK'
  spec.module_name      = 'HaloSocial'
  spec.version          = '2.2.2'
  spec.summary          = 'HALO Social iOS SDK'
  spec.homepage         = 'https://mobgen.github.io/halo-documentation/ios_home.html'
  spec.license          = 'Apache License, Version 2.0'
  spec.author           = { 'Borja Santos-Diez' => 'borja.santos@mobgen.com' }
  spec.source           = { :git => 'https://github.com/mobgen/halo-social-ios.git', :tag => '2.2.2' }

  spec.platforms        = { :ios => '8.0' }
  spec.requires_arc     = true

  spec.subspec 'Facebook' do |fb|
    fb.source_files         = 'Facebook'
    fb.public_header_files  = 'Facebook/*.h'
  
    fb.dependency 'FBSDKCoreKit'
    fb.dependency 'FBSDKLoginKit'
    fb.dependency 'FBSDKShareKit'
  end

  spec.subspec 'Google' do |google|
    google.source_files         = 'Google'
    google.public_header_files  = 'Google/*.h'

    google.dependency 'Google'
  end
 
  spec.dependency 'HaloSDK'

end