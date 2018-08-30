# MockDuck

A network mocking layer for iOS and macOS

## Installation

### CocoaPods

[CocoaPods](https://cocoapods.org/) is a dependency manager for Swift and Objective-C Cocoa projects. To integrate MockDuck into your project, specify it in your `Podfile`:

```ruby
pod 'MockDuck'
```

### Carthage

[Carthage](https://github.com/Carthage/Carthage) is a simple, decentralized dependency manager for Cocoa. To integrate MockDuck into your project, add the following to your `Cartfile`:

```ruby
github "BuzzFeed/MockDuck" "master"
```

### Manually

MockDuck can also be integrated into your project manually by using git submodules. Once you have added your submodule, simply drag `MockDuck.xcodeproj` into your Xcode project or workspace and then have your target link against `MockDuck.framework`.
