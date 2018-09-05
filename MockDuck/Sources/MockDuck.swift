//
//  MockDuck.swift
//  MockDuck
//
//  Created by Peter Walters on 3/20/18.
//  Copyright © 2018 BuzzFeed, Inc. All rights reserved.
//

import Foundation
import os

/// A delegate protocol that can be used to modify how MockDuck functions
public protocol MockDuckDelegate: class {

    /// A hook that allows one to normalize and/or modify a request before it is processed by
    /// MockDuck. For example, this can be useful to remove query parameters that change from
    /// one run of the app to another.
    ///
    /// - Parameter request: The request to normalize
    /// - Returns: The normalized request
    func normalize(url: URL) -> URL
    func useBodyInRequestHash(url: URL) -> Bool
}

// MARK: -

/// MockDuck top level class for configuring the framework. This class is responsible for
/// registering MockDuck as a URLProtocol that allows it to intercept network traffic.
public class MockDuck {
    static let requestQueue = DispatchQueue(label: "com.buzzfeed.MockDuck.sessionQueue", attributes: [])

    public static weak var delegate: MockDuckDelegate?

    private static let registeredMocks = [MockSequence]()

    private static var requestBundle: MockBundle {
        return session.bundle
    }
    
    static var session = MockSession(
        requestBundle: MockBundle(),
        requestQueue: MockDuck.requestQueue
    )

    /// By default, MockDuck is enabled, even though it does nothing until configured by setting
    /// `baseURL`, `recordURL`, or by registering a request mock. This is here, however, to allow
    /// developers to quickly disable MockDuck by setting this to `false`.
    public static var enabled = true

    /// By default, MockDuck will fallback to making a network request if the request can not be
    /// loaded from `baseURL` or if the request can not be handled by a registered request mock.
    /// Set this to `false` to force an error that resembles what `URLSession` provides when the
    /// network is unreachable.
    public static var shouldFallbackToNetwork = true

    /// The location where MockDuck will attempt to look for network requests that have been saved
    /// to disk.
    public static var baseURL: URL? {
        willSet {
            checkConfigureMockDuck()
        }
        didSet {
            requestBundle.baseURL = baseURL

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
            requestBundle.recordURL = recordURL

            if let recordURL = recordURL {
                os_log("Recording network requests to: %@", log: log, type: .info, recordURL.path)
            } else {
                os_log("No longer recording network requests", log: log, type: .info)
            }
        }
    }

    /// This function allows one to hook into MockDuck by allowing the caller to override any
    /// request with a specified response. This is most often used in unit tests to mock out
    /// expected requests so that the network isn't actually hit, introducing instability to the
    /// test.
    ///
    /// - Parameter block: The block to register. It receives a single parameter being the
    /// URLRequest that is about to be made. This block should return `nil` to do nothing with that
    /// request. Otherwise, it should return a `MockResponse` object that describes the full
    /// response that should be used for that request. You can use the extensions provided to
    /// `URLRequest.` to easily create a `MockResponse` for any request. See the various
    /// `mockResponse` functions in `URLRequest+Extensions.swift`.
    public static func registerRequestMock(with block: @escaping MockBundle.RequestMock) {
        checkConfigureMockDuck()
        requestBundle.registerRequestMock(with: block)
    }

    /// Quickly unregister all mocks that were registered by calling `registerRequestMock`. You
    /// generally want to call this in the `tearDown` method of your unit tests.
    public static func unregisterAllRequestMocks() {
        requestBundle.unregisterAllRequestMocks()    
    }

    // MARK: - Internal Use Only

    /// MockDuck uses this to log all of its messages.
    internal static let log = OSLog(subsystem: "com.buzzfeed.MockDuck", category: "default")

    // MARK: - Private Configuration

    private static var isConfigured = false

    private static func checkConfigureMockDuck() {
        guard !isConfigured else { return }
        URLProtocol.registerClass(MockURLProtocol.self)
        isConfigured = true
    }
}
