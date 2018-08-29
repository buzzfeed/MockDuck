Pod::Spec.new do |spec|
  spec.name          = 'MockDuck'
  spec.version       = '1.0'
  spec.license       = 'MIT'
  spec.summary       = 'A network mocking layer for iOS and macOS'
  spec.homepage      = 'https://github.com/buzzfeed/MockDuck'
  spec.author        = 'BuzzFeed'
  spec.source        = { :git => 'git@github.com:buzzfeed/MockDuck.git' }
  spec.source_files  = 'MockDuck/Sources/**/*.{h,m,swift}'
  spec.swift_version = '4.0'
end
