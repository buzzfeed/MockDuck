<p align="center"><img src ="mockduck.png?raw=true" alt="MockDuck Mascot" title="MockDuck" /></p>

# MockDuck

MockDuck is a network mocking layer written in [Swift](https://swift.org) for iOS, tvOS, and macOS. It has the following major features:

1. MockDuck can record all network traffic to disk. This recorded data can then be used while you run your app, as well as provide a more stable infrastructure for your UI and unit tests.
2. With a few lines of code, MockDuck can hijack any `URLRequest` and provide a mocked `URLResponse` with its associated data.

## Request Mocking

MockDuck ships with basic support for mocking network requests in code. This is a great way to add reliability and stability to your unit tests. For example:

```swift
MockDuck.registerRequestHandler { request in
    if request.url?.absoluteString == "https://api.buzzfeed.com/create_user" {
        return try? MockResponse(for: request, statusCode: 201)
    } else {
        return nil
    }
}
```

MockDuck also supports specifying the HTTP response headers, as well as JSON or any other data in the response payload. Don't forget to call `MockDuck.unregisterAllRequestHandlers()` in the `tearDown` method of your test case classes!

## Recording & Replaying

To begin capturing network activity in a MockDuck session, simply tell MockDuck where it should record requests and their responses:

```swift
MockDuck.recordURL = URL(fileURLWithPath: "/tmp/MockDuckRecording")
```

And then when you want to stop recording:

```swift
MockDuck.recordURL = nil
```

You can now (or in a future launch of your app) tell MockDuck to use this recording to replay any matching requests:

```swift
MockDuck.baseURL = URL(fileURLWithPath: "/tmp/MockDuckRecording")
```

In this scenario, any request that is not found in your recording will cause MockDuck to fallback to the network. If you would rather that these requests simply fail, you can set `MockDuck.shouldFallbackToNetwork` to `false`. In this scenario, anyone who makes a network request that can not be handled by the recording will receive a `URLError` error with a `.NotConnectedToInternet` code.

One of the goals of MockDuck is to make the recordings as easy as possible for humans to read and modify. When it makes sense, the entire request and response are written as a single JSON file in the recording directory. If the response also includes an image, a text file, or a JSON file, that data will be stored in a separate file right next to the request/response JSON. If a different format of data is returned, that data will be Base64 encoded and written as a value in the JSON file. Any of these files can be modified however you like to alter the mocked response.

We recommend crafting a few different recordings for different ways to use your app. For example, you may want to create one recording for your app's happy path, another that captures various failure scenarios, and another for anonymous users who have not logged in.

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

### Swift Package Manager

[Swift Package Manager](https://swift.org/getting-started/#using-the-package-manager) is a tool for managing distribution of source code written in Swift. To integrate MockDuck with your Swift library or application, add it as a dependency to your `Package.swift`:

```swift
    dependencies: [
        .package(url: "https://github.com/BuzzFeed/MockDuck", .branch("master"))
    ],
    targets: [
        .target(name: "your-target-name", dependencies: ["MockDuck"])
    ]
```

Please note that on macOS MockDuck requires 10.12 or newer, so you will have to specify `-Xswiftc "x86_64-apple-macosx10.12"` as an argument to your `swift build`, `swift run`, and `swift test` commands.

### Manually

MockDuck can also be integrated into your project manually by using git submodules. Once you have added your submodule, simply drag `MockDuck.xcodeproj` into your Xcode project or workspace and then have your target link against `MockDuck.framework`.

## Versioning

We use [Semantic Versioning](http://semver.org/) for MockDuck releases. For the versions available, take a look at the [tags on this repository](https://github.com/buzzfeed/MockDuck/tags).

## Acknowledgements

* Our wonderful [mascot](mockduck.png) was lovingly created by [Celine Chang](http://celinechang.com/).
* [VCR](https://github.com/vcr/vcr) is a tool that heavily inspired MockDuck. It excels at recording and replaying network requests. While VCR is written in Ruby, there are a few iOS and macOS tools inspired by VCR including [VCRURLConnection](https://github.com/dstnbrkr/VCRURLConnection) and [DVR](https://github.com/venmo/DVR).
* [OHHTTPStubs](https://github.com/AliSoftware/OHHTTPStubs) is a great tool that provides a simple API to stub out network requests in unit tests. This provided inspiration for MockDuck's request mocking feature described above.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
