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

    let response: URLResponse
    var responseData: Data?

    init(response: URLResponse, responseData: Data?) {
        self.response = response
        self.responseData = responseData
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
