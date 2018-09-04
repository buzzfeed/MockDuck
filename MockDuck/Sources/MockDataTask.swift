//
//  MockDataTask.swift
//  MockDuck
//
//  Created by Peter Walters on 3/20/18.
//  Copyright © 2018 BuzzFeed, Inc. All rights reserved.
//

import Foundation

class MockDataTask: URLSessionDataTask {

    typealias TaskCompletion = (MockSequence?, Bool, NSError?) -> Void

    unowned var session: MockSession
    let request: URLRequest
    let completion: TaskCompletion?

    init(session: MockSession,
         request: URLRequest,
         completion: (TaskCompletion)? = nil)
    {
        self.session = session
        self.request = request
        self.completion = completion
        super.init()
    }

    override func cancel() {
        // no op
    }

    // Pretty simple, on task execution, look for a saved request, or kick off the actual request
    override func resume() {
        if let sequence = session.bundle.loadRequest(request: request) {
            // The request is found. Load the MockSequence and call the completion/finish with the
            // stored data.
            completion?(sequence, true, nil)
        } else if MockDuck.shouldFallbackToNetwork {
            // The request isn't found but we should fallback to the network. Kick off a task with
            // the internal URLSession.
            let dataTask = session.internalSession.dataTask(with: request, completionHandler: { [weak self] (data, response, error) in
                guard
                    let response = response,
                    let strongSelf = self
                    else { return }
                // Create a new MockSequence with all the request/response data.
                let sequence = MockSequence(request: strongSelf.request, response: response, responseData: data)
                // Handle errors better
                strongSelf.completion?(sequence, false, nil)
            })
            dataTask.resume()
        } else {
            // The request isn't found and we shouldn't fallback to the network. Return a
            // well-crafted error in the completion.
            let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet, userInfo: nil)
            completion?(nil, false, error)
        }
    }
}
