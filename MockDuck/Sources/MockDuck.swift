//
//  MockDuck.swift
//  MockDuck
//
//  Created by Peter Walters on 3/20/18.
//  Copyright © 2018 BuzzFeed, Inc. All rights reserved.
//

import Foundation

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

/// MockDuck top level class for starting, stopping, and configuring the framework.
/// This class is responsible for registering MockDuck as a URLProtocol that allows
/// it to intercept all (well, most of) the network traffic.
public class MockDuck {
    static let requestQueue = DispatchQueue(label: "com.buzzfeed.MockDuck.sessionQueue", attributes: [])

    public static let shared = MockDuck()
    public weak var delegate: MockDuckDelegate?
    public var isVerbose = false

    private let registeredMocks = [MockSequence]()

    private var requestBundle: MockBundle {
        return session.bundle
    }
    
    var session = MockSession(
        requestBundle: MockBundle(),
        requestQueue: MockDuck.requestQueue
    )

    public var enabled = true
    public var shouldFallbackToNetwork = true

    private init() {
        URLProtocol.registerClass(MockURLProtocol.self)
    }

    public var baseURL: URL? {
        didSet {
            requestBundle.baseURL = baseURL
            if let baseURL = baseURL {
                print("[MockDuck] Using bundle at: \(baseURL.path)")
            }
        }
    }

    public var recordURL: URL? {
        didSet {
            requestBundle.recordURL = recordURL
            if let recordURL = recordURL {
                print("[MockDuck] Using bundle at: \(recordURL.path)")
            }
        }
    }

    public func hasRegisteredRequestMocks() -> Bool {
        return requestBundle.hasRegisteredRequestMocks()
    }

    public func registerRequestMock(with block: @escaping MockBundle.RequestMock) {
        requestBundle.registerRequestMock(with: block)
    }

    public func unregisterAllRequestMocks() {
        requestBundle.unregisterAllRequestMocks()    
    }
}
