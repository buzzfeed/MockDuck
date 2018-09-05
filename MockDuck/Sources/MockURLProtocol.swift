//
//  MockURLProtocol.swift
//  MockDuck
//
//  Created by Peter Walters on 3/19/18.
//  Copyright © 2018 BuzzFeed, Inc. All rights reserved.
//

import Foundation

/// This is the URLProtocol subclass that intercepts all network requests and uses `MockSession` to
/// stub out the responses. One of these is instantiated per request.
class MockURLProtocol: URLProtocol, URLSessionDelegate, URLSessionDataDelegate {
    private struct Constants {
        static let ProtocolHandled = "MockURLProtocolHandled"
    }

    var sessionTask: URLSessionTask?

    override init(request: URLRequest, cachedResponse: CachedURLResponse?, client: URLProtocolClient?) {
        // We set cached response to nil here to make sure that it's being sourced from the mocks.
        super.init(request: request, cachedResponse: nil, client: client)
    }

    override class func canInit(with request: URLRequest) -> Bool {
        // Bail out and do nothing if MockDuck has not been configured with the ability to mock out
        // any requests.
        guard
            (MockDuck.enabled ||
            MockDuck.baseURL != nil ||
            MockDuck.recordURL != nil ||
            MockDuck.mockBundle.hasRegisteredRequestHandlers())
            else { return false }

        // Check to be sure that we haven't yet handled this particular request. See the comment
        // around where we set this below.
        return URLProtocol.property(forKey: Constants.ProtocolHandled, in: request) == nil
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        guard let newRequest = ((request as NSURLRequest).mutableCopy() as? NSMutableURLRequest) else { return }

        // URLProtocols have a nasty habit of recursively calling into themselves as the URLRequest
        // is processed.  In the case of this URLProtocol, we only want to handle it the first time
        // through, and if the request isn't saved and requires going to the network to load the
        // data we don't want to get in the way. So set a value right away in the 'startLoading'
        // method that can be checked after this point for any followup loading of this request. If
        // it's already been handled once, bail out in the 'canInit' method.
        URLProtocol.setProperty(true, forKey: Constants.ProtocolHandled, in: newRequest)

        // Complete the request using our `MockSession`. On completion, call all the necessary
        // URLClient methods to communicate the results back to the caller.
        sessionTask = MockDuck.mockSession.dataTask(
            with: newRequest as URLRequest,
            completionHandler: { [weak self] data, response, error in
                guard let strongSelf = self else { return }

                if let error = error {
                    strongSelf.client?.urlProtocol(strongSelf, didFailWithError: error)
                } else {
                    if let response = response {
                        strongSelf.client?.urlProtocol(strongSelf, didReceive: response, cacheStoragePolicy: .allowed)
                    }
                    if let data = data {
                        strongSelf.client?.urlProtocol(strongSelf, didLoad: data)
                    }
                    strongSelf.client?.urlProtocolDidFinishLoading(strongSelf)
                }
            }
        )
        sessionTask?.resume()
    }

    override func stopLoading() {
        sessionTask?.cancel()
        sessionTask = nil
    }
 }
