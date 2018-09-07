//
//  URLResponseWrapper.swift
//  MockDuck
//
//  Created by Peter Walters on 4/2/18.
//  Copyright © 2018 BuzzFeed, Inc. All rights reserved.
//

import Foundation

/// A basic class that holds onto a URLResponse and its associated data.
public final class MockResponse {

    var response: URLResponse
    var responseData: Data?

    /// Designated initializer for MockResponse.
    public init(response: URLResponse, responseData: Data?) {
        self.response = response
        self.responseData = responseData
    }

    /// Generate a MockResponse from a request without any response data.
    ///
    /// - Parameters:
    ///   - request: The request which should generate the mock response.
    ///   - statusCode: The status code of the mocked response. Defaults to 200.
    ///   - headers: The HTTP headers of the mocked response.
    /// - Returns: The mocked response
    public convenience init(
        for request: URLRequest,
        statusCode: Int = 200,
        headers: [String: String]? = nil)
        throws
    {
        guard
            let url = request.url,
            let response = HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: nil, headerFields: headers)
            else { throw MockDuckError.unableToInitializeURLResponse }

        self.init(response: response, responseData: nil)
    }

    /// Generate a MockResponse from a request with generic response data.
    ///
    /// - Parameters:
    ///   - request: The request which should generate the mock response.
    ///   - data: The data associated with the mock response.
    ///   - statusCode: The status code of the mocked response. Defaults to 200.
    ///   - headers: The HTTP headers of the mocked response.
    /// - Returns: The mocked response
    public convenience init(
        for request: URLRequest,
        data: Data?,
        statusCode: Int = 200,
        headers: [String: String]? = nil)
        throws
    {
        guard
            let url = request.url,
            let response = HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: nil, headerFields: headers)
            else { throw MockDuckError.unableToInitializeURLResponse }

        self.init(response: response, responseData: data)
    }

    /// Generate a MockResponse from this request with JSON response data.
    ///
    /// - Parameters:
    ///   - request: The request which should generate the mock response.
    ///   - json: The JSON object to be returned by the resonse. Should be a valid JSON object.
    ///   - statusCode: The status code of the mocked response. Defaults to 200.
    ///   - headers: The HTTP headers of the mocked response.
    /// - Returns: The mocked response
    public convenience init(
        for request: URLRequest,
        json: Any,
        statusCode: Int = 200,
        headers: [String: String]? = nil)
        throws
    {
        let data = try JSONSerialization.data(withJSONObject: json, options: [])
        try self.init(for: request, data: data, statusCode: statusCode, headers: headers)
    }
}

// MARK: - Codable

extension MockResponse: Codable {

    enum CodingKeys: String, CodingKey {
        case response = "url"
        case responseHeaders = "headers"
        case responseCode = "status_code"
        case responseData = "data"
        case responseMimeType = "mime_type"
        case responseExpectedContentLength = "expected_content_length"
        case responseTextEncodingName = "text_encoding_name"
    }

    public convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let url = try container.decode(URL.self, forKey: CodingKeys.response)

        let headers = try container.decodeIfPresent([String: String].self, forKey: CodingKeys.responseHeaders)
        let mimeType = try container.decodeIfPresent(String.self, forKey: CodingKeys.responseMimeType)
        let contentType = headers?["Content-Type"] ?? mimeType

        var data: Data?
        if let body = try container.decodeIfPresent(String.self, forKey: CodingKeys.responseData) {
            data = EncodingUtils.decodeBody(body, contentType: contentType)
        }

        var response: URLResponse?
        if let statusCode = try container.decodeIfPresent(Int.self, forKey: CodingKeys.responseCode) {
            response = HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: nil, headerFields: headers)
        } else {
            let expectedContentLength = try container.decode(Int.self, forKey: CodingKeys.responseExpectedContentLength)
            let textEncodingName = try container.decodeIfPresent(String.self, forKey: CodingKeys.responseTextEncodingName)
            response = URLResponse(url: url, mimeType: mimeType, expectedContentLength: expectedContentLength, textEncodingName: textEncodingName)
        }

        if let response = response {
            self.init(response: response, responseData: data)
        } else {
            throw MockDuckError.unableToInitializeURLResponse
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        if let response = response as? HTTPURLResponse {
            let headers = response.allHeaderFields as? [String: String]
            try container.encode(response.statusCode, forKey: CodingKeys.responseCode)
            try container.encode(headers, forKey: CodingKeys.responseHeaders)
        } else {
            try container.encode(response.mimeType, forKey: CodingKeys.responseMimeType)
            try container.encode(response.expectedContentLength, forKey: CodingKeys.responseExpectedContentLength)
            try container.encode(response.textEncodingName, forKey: CodingKeys.responseTextEncodingName)
        }

        if
            response.dataSuffix == nil,
            let data = responseData,
            let body = try EncodingUtils.encodeBody(data, contentType: response.contentType)
        {
            // Inline the body if not saved on the side
            try container.encode(body, forKey: CodingKeys.responseData)
        }

        if let url = response.url {
            try container.encode(url, forKey: CodingKeys.response)
        }
    }
}
