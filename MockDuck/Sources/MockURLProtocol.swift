//
//  MockURLProtocol.swift
//  MockDuck
//
//  Created by Peter Walters on 3/19/18.
//  Copyright © 2018 BuzzFeed, Inc. All rights reserved.
//

import Foundation

/**
 URLProtocol class that intercepts all network requests and uses a MockSession to
 stub out the responses.
 */
public class MockURLProtocol: URLProtocol, URLSessionDelegate, URLSessionDataDelegate {
    struct Constants {
        static let ProtocolHandled = "MockURLProtocolHandled"
    }
    
    var sessionTask: URLSessionTask?
    let session: Foundation.URLSession

    override init(request: URLRequest, cachedResponse: CachedURLResponse?, client: URLProtocolClient?) {
        session = MockDuck.shared.session
        
        // Always ignore the cached response to make sure it's being sourced from the mocks
        super.init(
            request: request,
            cachedResponse: nil,
            client: client)
    }
    
    override public class func canInit(with request: URLRequest) -> Bool {
        guard
            (MockDuck.shared.enabled ||
            MockDuck.shared.baseURL != nil ||
            MockDuck.shared.recordURL != nil ||
            MockDuck.shared.hasRegisteredRequestMocks())
            else { return false }
        
        // Bail out if the request has already been handled.
        return URLProtocol.property(forKey: Constants.ProtocolHandled, in: request) == nil
    }
    
    override open class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override public func startLoading() {
        guard let newRequest = ((request as NSURLRequest).mutableCopy() as? NSMutableURLRequest) else { return }

        // URLProtocols have a nasty habit of recursively calling into themselves as the URLRequest
        // is processed.  In the case of this URLProtocol, we only want to handle it the first time
        // through, and if the request isn't saved and requires going to the network to load the data
        // we don't want to get in the way.   So set a value right away in the 'startLoading' method
        // that can be checked after this point for any followup loading of this request.  If it's already
        // been handled once, bail out in the 'canInit' method.
        URLProtocol.setProperty(true, forKey: Constants.ProtocolHandled, in: newRequest)

        // Complete the reuqest using the MockSession.  On completion, call all the necessary URLClient methods to
        // communicate the results back to the caller.
        sessionTask = session.dataTask(
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

    override public func stopLoading() {
        sessionTask?.cancel()
        sessionTask = nil
    }
 }
