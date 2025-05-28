Pod::Spec.new do |s|
  s.name             = 'CastarSDK'
  s.version          = '1.0.0'
  s.summary          = 'CastarSDK for iOS'
  s.description      = 'CastarSDK SDK for iOS helps you make money with iOS apps.'
  s.homepage         = 'https://github.com/srujan5570/ios-tap-to-paid'
  s.license          = { :type => 'Commercial' }
  s.author           = { 'Castar' => 'support@castar.com' }
  s.source           = { :path => '.' }
  s.ios.deployment_target = '12.0'
  s.ios.vendored_frameworks = 'CastarSDK.framework'
  s.swift_version = '5.0'
  s.platform = :ios
  s.pod_target_xcconfig = { 'VALID_ARCHS[sdk=iphonesimulator*]' => 'x86_64 arm64' }
  s.user_target_xcconfig = { 'VALID_ARCHS[sdk=iphonesimulator*]' => 'x86_64 arm64' }
end 