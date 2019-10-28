//
//  MockDataTask.swift
//  MockDuck
//
//  Created by Peter Walters on 3/20/18.
//  Copyright © 2018 BuzzFeed, Inc. All rights reserved.
//

import Foundation

/// A URLSessionDataTask subclass that attempts to return a cached response from disk, when
/// possible. When it is unable to load a response from disk, it can optionally use a fallback
/// URLSession to handle the request normally.
final class MockDataTask: URLSessionDataTask {

    typealias TaskCompletion = (MockRequestResponse?, Error?) -> Void

    enum ErrorType: Error {
        case unknown
    }

    private let request: URLRequest
    private let completion: TaskCompletion
    private var fallbackTask: URLSessionDataTask?

    init(request: URLRequest, completion: @escaping TaskCompletion) {
        self.request = request
        self.completion = completion
        super.init()
    }

    // On task execution, look for a saved request or kick off the fallback request.
    override func resume() {
        let mockRequestResponse = MockRequestResponse(request: request)

        if MockDuck.mockBundle.loadResponse(for: mockRequestResponse) {
            let message = String(format: "Did load response for URL: %@", request.url?.absoluteString ?? "")
            MockDuck.log(message, type: .error)

            // The request is found. Load the MockRequestResponse and call the completion/finish
            // with the updated data.
            completion(mockRequestResponse, nil)
        } else if MockDuck.shouldFallbackToNetwork {
            // The request isn't found but we should fallback to the network. Kick off a task with
            // the fallback URLSession.
            fallbackTask = MockDuck.fallbackSession.dataTask(with: request, completionHandler: { responseData, response, error in
                if let error = error {
                    self.completion(nil, error)
                } else if let response = response {
                    mockRequestResponse.responseWrapper = MockResponse(response: response, responseData: responseData)
                    MockDuck.mockBundle.record(requestResponse: mockRequestResponse)
                    self.completion(mockRequestResponse, nil)
                } else {
                    self.completion(nil, ErrorType.unknown)
                }

                self.fallbackTask = nil
            })
            fallbackTask?.resume()
        } else {
            let message = String(format: "Did fail to load response for URL: %@", request.url?.absoluteString ?? "")
            MockDuck.log(message, type: .error)

            // The request isn't found and we shouldn't fallback to the network. Return a
            // well-crafted error in the completion.
            let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet, userInfo: nil)
            completion(nil, error)
        }
    }

    override func cancel() {
        fallbackTask?.cancel()
        fallbackTask = nil
    }
}
