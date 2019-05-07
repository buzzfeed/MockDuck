Pod::Spec.new do |spec|
  spec.name          = 'MockDuck'
  spec.version       = '1.0'
  spec.license       = { :type => 'MIT', :file => 'LICENSE' }
  spec.summary       = 'A network mocking layer for iOS and macOS'
  spec.homepage      = 'https://github.com/buzzfeed/MockDuck'
  spec.author        = 'BuzzFeed'
  spec.source        = { :git => 'https://github.com/buzzfeed/MockDuck.git', :tag => '1.0' }
  spec.source_files  = 'MockDuck/Sources/**/*.{h,m,swift}'

  spec.swift_version = '5.0'
  spec.ios.deployment_target  = '10.0'
  spec.osx.deployment_target  = '10.12'

  spec.pod_target_xcconfig = {
    'FRAMEWORK_SEARCH_PATHS' => '$(PLATFORM_DIR)/Developer/Library/Frameworks',
    'ENABLE_BITCODE' => 'NO'
  }
end
