//
//  MockDuck.swift
//  MockDuck
//
//  Created by Peter Walters on 3/20/18.
//  Copyright © 2018 BuzzFeed, Inc. All rights reserved.
//

import Foundation
import os

/// A delegate protocol that can be used to modify how MockDuck functions.
public protocol MockDuckDelegate: class {

    /// A hook that allows one to normalize a request before it is turned into a hash that uniquely
    /// identifies it on the filesystem. By default, the entire request URL and the request body
    /// are used to create a unique request hash. It may be useful to remove some query parameters
    /// here or clear out the body so that multiple similar requests all hash to the same location
    /// on disk.
    ///
    /// - Parameter request: The request to normalize
    /// - Returns: The normalized request
    func normalizedRequest(for request: URLRequest) -> URLRequest
}

/// Public-facing errors that MockDuck can throw.
public enum MockDuckError: Error {

    /// HTTPURLResponse has a failable initializer. If MockDuck unexpectedly encounter that, this
    /// error will be thrown.
    case unableToInitializeURLResponse
}

// MARK: -

/// MockDuck top level class for configuring the framework. This class is responsible for
/// registering MockDuck as a URLProtocol that allows it to intercept network traffic.
public final class MockDuck {

    // MARK: - Public Properties

    /// A delegate that allows a class to hook into and modify how MockDuck behaves.
    public static weak var delegate: MockDuckDelegate?

    /// By default, MockDuck is enabled, even though it does nothing until configured by setting
    /// `baseURL`, `recordURL`, or by registering a request mock. This is here, however, to allow
    /// developers to quickly disable MockDuck by setting this to `false`.
    public static var enabled = true

    /// By default, MockDuck will fallback to making a network request if the request can not be
    /// loaded from `baseURL` or if the request can not be handled by a registered request mock.
    /// Set this to `false` to force an error that resembles what `URLSession` provides when the
    /// network is unreachable.
    public static var shouldFallbackToNetwork = true

    /// When MockDuck falls back to making a normal network request, it will use a URLSession
    /// configured with this object. You can hook in here to modify how these fallback requests
    /// are made.
    public static var fallbackSessionConfiguration = URLSessionConfiguration.default {
        didSet {
            fallbackSession = URLSession(configuration: fallbackSessionConfiguration)
        }
    }

    /// The location where MockDuck will attempt to look for network requests that have been saved
    /// to disk.
    public static var baseURL: URL? {
        willSet {
            checkConfigureMockDuck()
        }
        didSet {
            mockBundle.baseURL = baseURL

            if let baseURL = baseURL {
                os_log("Loading network requests from: %@", log: log, type: .info, baseURL.path)
            } else {
                os_log("No longer loading network requests from disk", log: log, type: .info)
            }
        }
    }

    /// The location where MockDuck should attempt to save network requests that occur. This is a
    /// useful way to record a session of network activity to disk which is then used in the future
    /// by pointing to this same data using `baseURL`.
    public static var recordURL: URL? {
        willSet {
            checkConfigureMockDuck()
        }
        didSet {
            mockBundle.recordURL = recordURL

            if let recordURL = recordURL {
                os_log("Recording network requests to: %@", log: log, type: .info, recordURL.path)
            } else {
                os_log("No longer recording network requests", log: log, type: .info)
            }
        }
    }

    // MARK: - Providing Request Handlers

    public typealias RequestHandler = (URLRequest) -> MockResponse?

    /// This function allows one to hook into MockDuck by allowing the caller to override any
    /// request with a mock response. This is most often used in unit tests to mock out expected
    /// requests so that the network isn't actually hit, introducing instability to the test.
    ///
    /// - Parameter handler: The handler to register. It receives a single parameter being the
    /// URLRequest that is about to be made. This block should return `nil` to do nothing with that
    /// request. Otherwise, it should return a `MockResponse` object that describes the full
    /// response that should be used for that request. You can use the extensions provided to
    /// `URLRequest.` to easily create a `MockResponse` for any request. See the various
    /// `mockResponse` functions in `URLRequest+Extensions.swift`.
    public static func registerRequestHandler(_ handler: @escaping RequestHandler) {
        checkConfigureMockDuck()
        mockBundle.registerRequestHandler(handler)
    }

    /// Quickly unregister all request handlers that were registered by calling
    /// `registerRequestHandler`. You generally want to call this in the `tearDown` method of your
    /// unit tests.
    public static func unregisterAllRequestHandlers() {
        mockBundle.unregisterAllRequestHandlers()
    }

    // MARK: - Internal Use Only

    /// This is the session MockDuck will fallback to using if the mocked request is not found and
    /// if `MockDuck.shouldFallbackToNetwork` is `true`.
    internal static var fallbackSession = URLSession.shared

    /// MockDuck uses this to log all of its messages.
    internal static let log = OSLog(subsystem: "com.buzzfeed.MockDuck", category: "default")

    // This is the URLSession subclass that we use to handle all mocked network requests.
    internal static var mockSession = MockSession()

    /// This is the object responsible for loading cached requests from disks as well as recording
    /// new requests to disk.
    internal static var mockBundle = MockBundle()

    // MARK: - Private Configuration

    private static var isConfigured = false

    private static func checkConfigureMockDuck() {
        guard !isConfigured else { return }
        URLProtocol.registerClass(MockURLProtocol.self)
        isConfigured = true
    }
}
