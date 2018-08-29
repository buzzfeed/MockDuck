//
//  URLRequest+Extensions.swift
//  MockDuck
//
//  Created by Peter Walters on 4/2/18.
//  Copyright © 2018 BuzzFeed, Inc. All rights reserved.
//

import Foundation

extension URLRequest: Codable {
    enum CodingKeys: String, CodingKey {
        case httpMethod = "method"
        case absoluteURL = "url"
        case statusCode = "status_code"
        case allHTTPHeaderFields = "headers"
        case httpBody = "body"
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let url = try values.decode(URL.self, forKey: CodingKeys.absoluteURL)

        self.init(url: url)

        self.httpMethod = try values.decode(String.self, forKey: CodingKeys.httpMethod)

        self.allHTTPHeaderFields = try? values.decode([String: String].self, forKey: CodingKeys.allHTTPHeaderFields)

        // Decode the encoded string that was representing the body
        if
            let string = try? values.decode(String.self, forKey: CodingKeys.httpBody),
            let decodedBody = EncodingUtils.decodeBody(string, headers: self.allHTTPHeaderFields)
        {
            self.httpBody = decodedBody
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if let method = httpMethod {
            try container.encode(method, forKey: CodingKeys.httpMethod)
        }

        if let url = url?.absoluteURL {
            try container.encode(url, forKey: CodingKeys.absoluteURL)
        }

        if let headers = allHTTPHeaderFields {
            try container.encode(headers, forKey: CodingKeys.allHTTPHeaderFields)
        }

        if
            dataSuffix == nil,
            let data = httpBody
        {
            let encodedBody = EncodingUtils.encodeBody(data, headers: allHTTPHeaderFields)
            try container.encode(encodedBody, forKey: CodingKeys.httpBody)
        }
    }
}

public extension URLRequest {
    public func mockResponse(statusCode: Int = 200, headers: [String: String]? = nil) -> MockResponse? {
        guard
            let url = url,
            let response = HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: nil, headerFields: headers)
            else { return nil }
        return MockResponse(response: response, responseData: nil)
    }

    public func mockResponse(data: Data?, statusCode: Int = 200, headers: [String: String]? = nil) -> MockResponse? {
        guard
            let url = url,
            let response = HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: nil, headerFields: headers)
            else { return nil }
        return MockResponse(response: response, responseData: data)
    }

    public func mockResponse(json: Any?, statusCode: Int = 200, headers: [String: String]? = nil) -> MockResponse? {
        var data: Data? = nil
        if let responseJSON = json {
            data = try? JSONSerialization.data(withJSONObject: responseJSON, options: [])
        }
        return mockResponse(data: data, statusCode: statusCode, headers: headers)
    }
}
