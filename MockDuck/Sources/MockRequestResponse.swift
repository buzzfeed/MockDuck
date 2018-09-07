//
//  MockRequestResponse.swift
//  MockDuck
//
//  Created by Peter Walters on 3/22/18.
//  Copyright © 2018 BuzzFeed, Inc. All rights reserved.
//

import Foundation

/// A basic container for holding a request, a response, and any associated data.
final class MockRequestResponse: Codable {

    // MARK: - Properties

    var request: URLRequest {
        get {
            return requestWrapper.request
        }
        set {
            requestWrapper.request = newValue
        }
    }

    var response: URLResponse {
        return responseWrapper.response
    }

    var responseData: Data? {
        get {
            return responseWrapper.responseData
        }
        set {
            responseWrapper.responseData = newValue
        }
    }

    private var requestWrapper: MockRequest
    private var responseWrapper: MockResponse

    // MARK: - Initializers

    init(request: URLRequest, response: URLResponse, responseData: Data? = nil) {
        self.requestWrapper = MockRequest(request: request)
        self.responseWrapper = MockResponse(response: response, responseData: responseData)
    }

    convenience init(request: URLRequest, mockResponse: MockResponse) {
        self.init(request: request, response: mockResponse.response, responseData: mockResponse.responseData)
    }

    // MARK: - Codable

    enum CodingKeys: String, CodingKey {
        case requestWrapper = "request"
        case responseWrapper = "response"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        requestWrapper = try container.decode(MockRequest.self, forKey: .requestWrapper)
        responseWrapper = try container.decode(MockResponse.self, forKey: .responseWrapper)
    }
}
