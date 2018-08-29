//
//  MockSession.swift
//  MockDuck
//
//  Created by Peter Walters on 3/20/18.
//  Copyright © 2018 BuzzFeed, Inc. All rights reserved.
//

import Foundation

public class MockSession: URLSession {

    public typealias DataTaskCompletionBlock = (Data?, Foundation.URLResponse?, Error?) -> Void

    let internalSession: URLSession
    let queue: DispatchQueue
    let bundle: MockBundle

    public init(
        requestBundle: MockBundle,
        requestQueue: DispatchQueue,
        internalSession: URLSession = URLSession.shared)
    {
        self.internalSession = internalSession
        self.queue = requestQueue
        self.bundle = requestBundle
        super.init()
    }

    // URLSession
    public override func dataTask(
        with request: URLRequest,
        completionHandler: @escaping DataTaskCompletionBlock) -> URLSessionDataTask
    {
        let task = MockDataTask(session: self, request: request) { [weak self] (sequence, isPlayback, error) in
            guard let strongSelf = self else { return }
            strongSelf.queue.async {
                if
                    strongSelf.bundle.recording,
                    let sequence = sequence,
                    !sequence.loadedFromDisk
                {
                    strongSelf.bundle.saveRequest(sequence: sequence)
                }

                completionHandler(sequence?.responseData, sequence?.response, error)
            }
        }

        return task
    }
}
