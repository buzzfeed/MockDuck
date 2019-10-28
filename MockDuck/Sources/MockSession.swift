//
//  MockSession.swift
//  MockDuck
//
//  Created by Peter Walters on 3/20/18.
//  Copyright © 2018 BuzzFeed, Inc. All rights reserved.
//

import Foundation

/// MockSession is a basic subclass of URLSession, created so that we can hook into the creation of
/// NSURLSession tasks and provide our own tasks that can load cached requests from disk.
final class MockSession: URLSession {
    private let queue = DispatchQueue(label: "com.buzzfeed.MockDuck.MockSessionQueue", attributes: [])

    override func dataTask(
        with request: URLRequest,
        completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void)
        -> URLSessionDataTask
    {
        let task = MockDataTask(request: request) { (sequence, error) in
            self.queue.async {
                var isDataEmpty = true
                if let data = sequence?.responseData {
                    isDataEmpty = data.isEmpty
                }
                let isDataEmptyString = isDataEmpty ? "Data is empty" : "Data is not empty"
                let message = String(format: "Data task completion - Request URL: %@, Data: %@, URLResponse: %@, Error: %@",
                                     request.url?.absoluteString ?? "No request URL",
                                     isDataEmptyString,
                                     sequence?.response ?? "No response",
                                     error?.localizedDescription ?? "No error")
                MockDuck.log(message, type: .error)
                completionHandler(sequence?.responseData, sequence?.response, error)
            }
        }

        return task
    }
}
